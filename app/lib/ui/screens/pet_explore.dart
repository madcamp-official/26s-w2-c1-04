// Memory Pager — Explore other groups' pets (P2 / EX-1~3, full-screen).
//
//   EX-3 옆으로 넘기기   GET /pets/explore
//   EX-2 코드로 찾아가기  GET /pets/by-code/{invite_code}
//   EX-1 좋아요          POST|DELETE /pets/{pet_id}/like  (idempotent)
//
// This is the one place the closed app looks outward, so it stays deliberately
// quiet: a single pet per page, no counts racing, no feed.

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
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
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: cpSans(size: 12, color: const Color(0xFFB5654A))),
                ],
                if (_found != null) ...[
                  const SizedBox(height: 18),
                  CpEyebrow('코드로 찾은 펫', size: 9),
                  const SizedBox(height: 10),
                  _PetCard(
                    pet: _found!,
                    onLike: () => _toggleLike(_found!),
                    compact: true,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => setState(() => _found = null),
                      child: Text('닫기',
                          style: cpSans(size: 11, color: cpInkA(0.45))),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const CpHair(),
                const SizedBox(height: 18),
                Expanded(
                  child: _busy && pets.isEmpty
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: cpEuc),
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
                const SizedBox(height: 10),
                Text(
                  '좌우로 넘겨 다른 펫을 구경하세요 · 공개 설정한 그룹만 보여요',
                  textAlign: TextAlign.center,
                  style: cpSans(size: 11, color: cpInkA(0.4)),
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
}

// ===========================================================================
// Card
// ===========================================================================

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.onLike, this.compact = false});

  final ExplorePet pet;
  final VoidCallback onLike;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CpMatted(
      mat: compact ? 14 : 20,
      inset: compact ? 10 : 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pet.moodEmoji, style: TextStyle(fontSize: compact ? 40 : 76)),
          SizedBox(height: compact ? 10 : 20),
          Text(pet.name,
              style: cpSans(
                  size: compact ? 16 : 20, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('LV ${pet.level} · ${pet.inviteCode}',
              style: cpSans(size: 11, color: cpInkA(0.45), spacing: 0.6)),
          SizedBox(height: compact ? 12 : 22),
          GestureDetector(
            onTap: onLike,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: pet.likedByMe ? cpEucA(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: pet.likedByMe ? cpEucA(0.55) : cpInkA(0.14),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pet.likedByMe ? '♥' : '♡',
                      style: TextStyle(
                          fontSize: 14,
                          color: pet.likedByMe ? cpEuc : cpInkA(0.4))),
                  const SizedBox(width: 8),
                  Text('${pet.likeCount}',
                      style: cpSans(
                        size: 12,
                        color: pet.likedByMe ? cpEuc : cpInkA(0.55),
                        weight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
