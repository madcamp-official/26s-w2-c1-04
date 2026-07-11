// Memory Pager — Explore other groups' pets (P2 / EX-1~3, full-screen).
//
//   EX-3 옆으로 넘기기   GET /pets/explore
//   EX-2 코드로 찾아가기  GET /pets/by-code/{invite_code}
//   EX-1 좋아요          POST|DELETE /pets/{pet_id}/like  (idempotent)
//
// This is the one place the closed app looks outward, so it stays deliberately
// quiet: a single pet per page, no counts racing, no feed.
//
// Sumone skin: warm cream ground, soft rounded cards, one gentle heart-pink
// accent, generous whitespace. ZERO emoji — the like control is a Material line
// heart, and each explore pet is drawn HAND-DRAWN via [PetView] (never the
// server's `mood_emoji` string). `ExplorePet` has no species column, so the
// look is derived deterministically from the pet id — an honest, stable
// placeholder avatar (the same id-seeded pattern the album thumbs use), not a
// claim about the pet's real chosen character.

import 'package:flutter/material.dart';

import '../../charlab/roster.dart';
import '../../charlab/toolkit.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../pet_view.dart';
import '../theme.dart';

class PetExploreScreen extends StatefulWidget {
  const PetExploreScreen({super.key});

  @override
  State<PetExploreScreen> createState() => _PetExploreScreenState();
}

class _PetExploreScreenState extends State<PetExploreScreen> {
  final PageController _pages = PageController();
  final TextEditingController _code = TextEditingController();

  bool _busy = true;
  String? _error;

  /// A pet fetched by invite code — shown above the feed until dismissed.
  ExplorePet? _found;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pages.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      await appState.explore(reset: true);
    } catch (_) {
      if (mounted) setState(() => _error = '펫을 불러오지 못했어요');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _search() async {
    final c = _code.text.trim();
    if (c.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _found = null;
    });
    try {
      final p = await appState.repo.petByCode(c);
      if (mounted) setState(() => _found = p);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.status == 404 ? '그 코드의 펫이 없어요' : e.error.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = '찾지 못했어요');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleLike(ExplorePet p) async {
    try {
      await appState.like(p.petId, liked: !p.likedByMe);
      if (_found?.petId == p.petId && mounted) {
        // The feed row is the source of truth once it's there; otherwise flip
        // the found card locally so the button reflects the write we just made.
        final row = appState.explorePets
            .where((x) => x.petId == p.petId)
            .cast<ExplorePet?>()
            .firstWhere((_) => true, orElse: () => null);
        setState(() => _found = row ?? _flip(p));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '반영하지 못했어요');
    }
  }

  ExplorePet _flip(ExplorePet p) => ExplorePet(
        petId: p.petId,
        name: p.name,
        level: p.level,
        moodEmoji: p.moodEmoji,
        likeCount: p.likedByMe
            ? (p.likeCount > 0 ? p.likeCount - 1 : 0)
            : p.likeCount + 1,
        likedByMe: !p.likedByMe,
        inviteCode: p.inviteCode,
      );

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      title: '다른 그룹 펫',
      leading: CpIconButton(
        icon: Icons.arrow_back,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final pets = appState.explorePets;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _searchRow(),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _errorSlip(_error!),
                ],
                if (_found != null) ...[
                  const SizedBox(height: 20),
                  const CpEyebrow('코드로 찾은 펫'),
                  const SizedBox(height: 12),
                  _PetCard(
                    pet: _found!,
                    onLike: () => _toggleLike(_found!),
                    compact: true,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => setState(() => _found = null),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Text('닫기',
                            style: cpSans(
                                size: 12,
                                color: cpInkA(0.45),
                                weight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const CpHair(),
                const SizedBox(height: 20),
                Expanded(
                  child: _busy && pets.isEmpty
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cpEuc),
                          ),
                        )
                      : pets.isEmpty
                          ? const CpEmptyState(
                              icon: Icons.pets_outlined,
                              text: '구경할 수 있는 펫이 없어요',
                            )
                          : PageView.builder(
                              controller: _pages,
                              itemCount: pets.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: _PetCard(
                                  pet: pets[i],
                                  onLike: () => _toggleLike(pets[i]),
                                ),
                              ),
                            ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe_outlined,
                        size: 15, color: cpInkA(0.4)),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        '좌우로 넘겨 다른 펫을 구경하세요 · 공개 설정한 그룹만 보여요',
                        textAlign: TextAlign.center,
                        style: cpSans(size: 11, color: cpInkA(0.4)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _searchRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CpTextField(
            controller: _code,
            label: '코드로 찾아가기',
            hint: '초대 코드',
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 84,
          child: CpPrimaryButton(label: '찾기', onTap: _search),
        ),
      ],
    );
  }

  /// A quiet inline error slip — a soft pink-tinted pill with a line icon. Honest
  /// and calm, never shouty.
  Widget _errorSlip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cpEucA(0.10),
        borderRadius: BorderRadius.circular(cpRadiusSmall),
        border: Border.all(color: cpEucA(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: cpEuc),
          const SizedBox(width: 10),
          Flexible(
            child: Text(text,
                style: cpSans(
                    size: 12, color: cpEuc, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Card
// ===========================================================================

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.onLike, this.compact = false});

  final ExplorePet pet;
  final VoidCallback onLike;
  final bool compact;

  /// A stable roster species for this pet, seeded from its id. `ExplorePet` has
  /// no species column, so the look is a deterministic placeholder (id-seeded,
  /// like the album thumbs) — never a claim about the pet's real character.
  String get _speciesId {
    final list = petRoster;
    if (list.isEmpty) return kDefaultSpecies;
    return list[pet.petId.hashCode.abs() % list.length].id;
  }

  @override
  Widget build(BuildContext context) {
    return CpMatted(
      mat: compact ? 16 : 22,
      inset: compact ? 10 : 18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PetView(
            speciesId: _speciesId,
            size: compact ? 84 : 168,
            expression: PetExpression.happy,
          ),
          SizedBox(height: compact ? 10 : 18),
          Text(
            pet.name,
            style: cpSerif(
              size: compact ? 18 : 26,
              weight: FontWeight.w600,
              style: FontStyle.normal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'LV ${pet.level} · ${pet.inviteCode}',
            style: cpSans(size: 11, color: cpInkA(0.45), spacing: 0.5),
          ),
          SizedBox(height: compact ? 14 : 24),
          _LikeButton(
            liked: pet.likedByMe,
            count: pet.likeCount,
            onTap: onLike,
          ),
        ],
      ),
    );
  }
}

/// A soft pill like-control: a Material line heart (filled + pink when liked)
/// beside the like count. No emoji, no boxy border.
class _LikeButton extends StatelessWidget {
  const _LikeButton({
    required this.liked,
    required this.count,
    required this.onTap,
  });

  final bool liked;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: liked ? cpEucA(0.12) : cpPrint,
          borderRadius: BorderRadius.circular(cpRadiusPill),
          border: Border.all(
            color: liked ? cpEucA(0.5) : cpInkA(0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: liked ? cpEuc : cpInkA(0.4),
            ),
            const SizedBox(width: 9),
            Text(
              '$count',
              style: cpSans(
                size: 13,
                color: liked ? cpEuc : cpInkA(0.55),
                weight: FontWeight.w600,
                spacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
