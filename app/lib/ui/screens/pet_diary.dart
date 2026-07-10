// Memory Pager — Pet diary (full-screen push target). Cold Press.
//
// 삐삐의 그림 일기장. `appState.loadDiaries(reset: true)` pulls the pet's diary
// page (newest first) from the repo (REST/mock = source of truth); each entry is
// a placeholder illustration (a deterministic gradient + activity glyph standing
// in for `image_url`, which is a server media path we can't load) over a caption,
// an `entry_date`, and a `style.kind` badge (기본/학습).
//
// The one narrative beat: the day `style.kind` flips `default → learned` — "우리
// 그림체를 배운 날". In the newest-first list that transition is the adjacent pair
// where the newer entry is `learned` and the older one is still `default`; a quiet
// eucalyptus boundary is drawn there and dated to the learned entry. When the
// boundary isn't present in the loaded page (all-default, all-learned, or the
// default era hasn't paged in yet) nothing is invented — the divider simply
// doesn't appear.
//
// Cold Press throughout: cpMist ground, slate ink, one eucalyptus accent, 0.5px
// keyline mats, tracked-caps eyebrows, sharp radius, generous whitespace.

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';

// ===========================================================================
// Screen (public name + const ctor preserved — app.dart depends on both)
// ===========================================================================

class PetDiaryScreen extends StatefulWidget {
  const PetDiaryScreen({super.key});

  @override
  State<PetDiaryScreen> createState() => _PetDiaryScreenState();
}

/// The initial-load lifecycle of the diary page.
enum _Phase { loading, ready, error }

class _PetDiaryScreenState extends State<PetDiaryScreen> {
  _Phase _phase = _Phase.loading;
  Object? _error;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    // Load after first frame so the scaffold paints immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      await appState.loadDiaries(reset: true);
      if (!mounted) return;
      setState(() => _phase = _Phase.ready);
    } catch (e) {
      // listDiaries has no 404/410 surface in normal flow; any failure here is
      // a loud, honest error with a retry — never a faked empty page.
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = e;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !appState.diariesHasMore) return;
    setState(() => _loadingMore = true);
    try {
      await appState.loadDiaries();
    } catch (_) {
      // Keep the page we already have; the footer stays available to retry.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      title: '펫 일기',
      leading: CpIconButton(
        icon: Icons.arrow_back,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          switch (_phase) {
            case _Phase.loading:
              return const _PdLoading();
            case _Phase.error:
              return _PdError(message: _errorMessage(_error), onRetry: _load);
            case _Phase.ready:
              final diaries = appState.diaries;
              if (diaries.isEmpty) {
                return _PdEmpty(petName: appState.pet?.name);
              }
              return _PdList(
                diaries: diaries,
                petName: appState.pet?.name,
                hasMore: appState.diariesHasMore,
                loadingMore: _loadingMore,
                onLoadMore: _loadMore,
              );
          }
        },
      ),
    );
  }
}

// ===========================================================================
// The list
// ===========================================================================

class _PdList extends StatelessWidget {
  const _PdList({
    required this.diaries,
    required this.petName,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });

  final List<Diary> diaries;
  final String? petName;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final learnedCount =
        diaries.where((d) => d.style.kind == StyleKind.learned).length;

    final children = <Widget>[
      _PdIntro(
        petName: petName,
        total: diaries.length,
        learnedCount: learnedCount,
      ),
      const SizedBox(height: 22),
    ];

    // Newest-first: render each card, and drop a "learned" boundary right below
    // the earliest learned entry (the learned card sitting directly above a
    // still-default one).
    for (var i = 0; i < diaries.length; i++) {
      final d = diaries[i];
      children.add(_PdDiaryCard(diary: d));

      final older = i + 1 < diaries.length ? diaries[i + 1] : null;
      final isBoundary = d.style.kind == StyleKind.learned &&
          older != null &&
          older.style.kind == StyleKind.default_;
      if (isBoundary) {
        children.add(_PdLearnedBoundary(date: d.entryDate));
      } else {
        children.add(const SizedBox(height: 16));
      }
    }

    children.add(_PdFooter(
      hasMore: hasMore,
      loadingMore: loadingMore,
      onLoadMore: onLoadMore,
    ));

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 36),
      children: children,
    );
  }
}

class _PdIntro extends StatelessWidget {
  const _PdIntro({
    required this.petName,
    required this.total,
    required this.learnedCount,
  });

  final String? petName;
  final int total;
  final int learnedCount;

  @override
  Widget build(BuildContext context) {
    final name = (petName == null || petName!.isEmpty) ? '펫' : petName!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CpEyebrow('PET DIARY'),
        const SizedBox(height: 6),
        Text('$name의 그림 일기', style: cpSans(size: 22, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          '$name가 하루를 그림으로 남겼어요. 우리 그림체를 배운 날부터 그림의 결이 달라져요.',
          style: cpSans(size: 13, color: cpInkA(0.55), height: 1.55),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _PdCountPill(label: '일기', value: '$total'),
            const SizedBox(width: 10),
            if (learnedCount > 0)
              _PdCountPill(
                label: '학습 이후',
                value: '$learnedCount',
                accent: true,
              ),
          ],
        ),
      ],
    );
  }
}

/// A tiny value+label stat pill for the intro row.
class _PdCountPill extends StatelessWidget {
  const _PdCountPill({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accent ? cpEucA(0.10) : cpDim,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: accent ? cpEucA(0.5) : cpInkA(0.10),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: cpSans(
              size: 13,
              weight: FontWeight.w600,
              color: accent ? cpEuc : cpInk,
              spacing: 0.4,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: cpSans(
              size: 11,
              color: accent ? cpEuc : cpInkA(0.55),
              spacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// One diary card
// ===========================================================================

class _PdDiaryCard extends StatelessWidget {
  const _PdDiaryCard({required this.diary});

  final Diary diary;

  @override
  Widget build(BuildContext context) {
    final learned = diary.style.kind == StyleKind.learned;
    return CpMatted(
      mat: 14,
      keyline: learned ? 0.14 : 0.24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PdPlaceholderImage(diary: diary, learned: learned),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: CpEyebrow(_pdFmtDate(diary.entryDate)),
                ),
              ),
              const SizedBox(width: 10),
              _PdStyleBadge(style: diary.style),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            diary.caption,
            style: cpSans(size: 14, height: 1.55),
          ),
          if (diary.activities.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in diary.activities) _PdActivityTag(kind: a),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Honest stand-in for `image_url` (a server media path we cannot fetch, and
/// must not on web): a deterministic two-tone gradient seeded from the diary id
/// plus the day's activity glyph. It signals *the kind of* entry; it never
/// pretends to be the real illustration.
class _PdPlaceholderImage extends StatelessWidget {
  const _PdPlaceholderImage({required this.diary, required this.learned});

  final Diary diary;
  final bool learned;

  @override
  Widget build(BuildContext context) {
    final swatch = _pdSwatch(diary.id);
    final glyph = diary.activities.isNotEmpty
        ? _pdActivityGlyph(diary.activities.first)
        : '📖';
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1),
          border: Border.all(
            color: learned ? cpEucA(0.45) : cpInkA(0.10),
            width: 0.5,
          ),
          gradient: LinearGradient(
            colors: [
              Color.alphaBlend(cpPrint.withOpacity(0.42), swatch.$1),
              Color.alphaBlend(cpPrint.withOpacity(0.42), swatch.$2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(child: Text(glyph, style: const TextStyle(fontSize: 44))),
            Positioned(
              left: 12,
              bottom: 10,
              child: CpEyebrow(
                learned ? '학습 그림체' : '기본 그림체',
                color: cpInk,
                size: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The `style.kind` badge (기본/학습 그림체) shown on every card.
class _PdStyleBadge extends StatelessWidget {
  const _PdStyleBadge({required this.style});

  final DiaryStyle style;

  @override
  Widget build(BuildContext context) {
    final learned = style.kind == StyleKind.learned;
    final fg = learned ? cpEuc : cpInkA(0.55);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: learned ? cpEucA(0.12) : cpDim,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: learned ? cpEucA(0.5) : cpInkA(0.10),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (learned) ...[
            const Text('🎨', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 6),
          ],
          Text(
            learned ? '우리 그림체' : '기본 그림체',
            style: cpSans(
              size: 11,
              color: fg,
              weight: FontWeight.w600,
              spacing: 0.4,
            ),
          ),
          if (style.version > 0) ...[
            const SizedBox(width: 6),
            Text(
              'v${style.version}',
              style: cpSans(size: 10, color: fg.withOpacity(0.7), spacing: 0.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small activity tag (glyph + Korean label) from the diary's activities.
class _PdActivityTag extends StatelessWidget {
  const _PdActivityTag({required this.kind});

  final PetActivityKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        border: Border.all(color: cpInkA(0.12), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_pdActivityGlyph(kind), style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 6),
          Text(
            _pdActivityLabel(kind),
            style: cpSans(size: 11, color: cpInkA(0.6), spacing: 0.4),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// "우리 그림체를 배운 날" boundary
// ===========================================================================

/// The quiet eucalyptus divider marking the day `style.kind` flipped to
/// `learned`. Sits between the learned era (above) and the default era (below).
class _PdLearnedBoundary extends StatelessWidget {
  const _PdLearnedBoundary({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Container(height: 1, color: cpEucA(0.35))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: cpEucA(0.10),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: cpEucA(0.5), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎨', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(
                        '우리 그림체를 배운 날',
                        style: cpEyebrowStyle(color: cpEuc, size: 10),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: cpEucA(0.35))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _pdFmtDate(date),
            style: cpSans(size: 11, color: cpEucA(0.9), spacing: 1.2),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Footer / states
// ===========================================================================

class _PdFooter extends StatelessWidget {
  const _PdFooter({
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          child: Text(
            '· 여기까지가 처음이에요 ·',
            style: cpSans(size: 11, color: cpInkA(0.35), spacing: 1.0),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: loadingMore
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: cpEuc),
              )
            : CpPrimaryButton(
                label: '이전 일기 더 보기',
                filled: false,
                onTap: onLoadMore,
              ),
      ),
    );
  }
}

class _PdLoading extends StatelessWidget {
  const _PdLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: cpEuc),
      ),
    );
  }
}

class _PdEmpty extends StatelessWidget {
  const _PdEmpty({required this.petName});

  final String? petName;

  @override
  Widget build(BuildContext context) {
    final name = (petName == null || petName!.isEmpty) ? '펫' : petName!;
    return Center(
      child: CpEmptyState(
        icon: Icons.menu_book_outlined,
        text: '$name의 그림 일기가 아직 없어요\n하루가 쌓이면 여기에 그려져요',
      ),
    );
  }
}

class _PdError extends StatelessWidget {
  const _PdError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CpEmptyState(
            icon: Icons.cloud_off_outlined,
            text: message,
          ),
          const SizedBox(height: 18),
          CpPrimaryButton(label: '다시 시도', filled: false, onTap: onRetry),
        ],
      ),
    );
  }
}

/// The server's own words when it's an [ApiException]; a plain line otherwise.
String _errorMessage(Object? e) {
  if (e is ApiException) return e.error.message;
  return '일기를 불러오지 못했어요';
}

// ===========================================================================
// Pure helpers (private, unique prefix)
// ===========================================================================

const List<String> _pdWeekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// `2026.07.09 (목)` — date-only, no clock read.
String _pdFmtDate(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  // DateTime.weekday: Mon=1 .. Sun=7.
  final wd = _pdWeekdays[(d.weekday - 1).clamp(0, 6)];
  return '${d.year}.$mm.$dd ($wd)';
}

/// Emoji standing in for an activity in the placeholder / tag. Exhaustive over
/// the closed enum (unknown wire values already fold to [PetActivityKind.waiting]).
String _pdActivityGlyph(PetActivityKind k) => switch (k) {
      PetActivityKind.eating => '🍚',
      PetActivityKind.sleeping => '😴',
      PetActivityKind.walking => '🚶',
      PetActivityKind.playing => '🎾',
      PetActivityKind.drawing => '🎨',
      PetActivityKind.waiting => '🪟',
    };

/// Korean label for an activity tag.
String _pdActivityLabel(PetActivityKind k) => switch (k) {
      PetActivityKind.eating => '밥',
      PetActivityKind.sleeping => '낮잠',
      PetActivityKind.walking => '산책',
      PetActivityKind.playing => '놀이',
      PetActivityKind.drawing => '그림',
      PetActivityKind.waiting => '기다림',
    };

/// Two muted colors seeded from [id] — a deterministic placeholder swatch (same
/// spirit as [CpDoodleThumb]'s fallback: honest, never a faked illustration).
(Color, Color) _pdSwatch(String id) {
  final hue = (id.hashCode % 360).abs().toDouble();
  final a = HSLColor.fromAHSL(1, hue, 0.28, 0.62).toColor();
  final b = HSLColor.fromAHSL(1, (hue + 42) % 360, 0.26, 0.55).toColor();
  return (a, b);
}
