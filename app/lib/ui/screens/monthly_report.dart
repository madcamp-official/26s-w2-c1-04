// Memory Pager — Monthly report (P1, full-screen push target).
//
// The month's snapshot: pet growth, doodle-type distribution, poke count and
// "이번 달 최고의 낙서" with the rule that picked it.
//
// Two contract details shape this screen:
//  · `best_doodle_rule` may grow new values when the team adds vision selection.
//    [BestDoodleRule] folds unknown wire values into `unknown`, and we render a
//    neutral label rather than crashing (API.md §6).
//  · Reports are snapshots that only exist once generated. MR-3 runs monthly, so
//    nothing fires during a 7-day build — hence the explicit demo trigger
//    (`POST .../reports/{YYYY-MM}/generate`). Until then we show an honest empty
//    state, never a zero-filled fake report.

import 'package:flutter/material.dart';

import '../../core/api/mock_repository.dart';
import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../theme.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  late String _month = _monthKey(_nowUtc());
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await appState.loadReports();
      // Land on a month that actually has a report: prefer this month, else the
      // most recent generated one. We never fabricate data — we just open on a
      // real report instead of an empty current month.
      final available = appState.reports.map((s) => s.month).toList()
        ..sort((a, b) => b.compareTo(a));
      if (!available.contains(_month) && available.isNotEmpty) {
        _month = available.first;
      }
      await appState.loadReport(_month);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '레포트를 불러오지 못했어요');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await appState.generateReport(_month);
      await appState.loadReports();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '생성하지 못했어요');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(String month) async {
    setState(() => _month = month);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      title: '월간 레포트',
      leading: CpIconButton(
        icon: Icons.arrow_back,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final r = appState.report;
          final months = <String>{
            for (final s in appState.reports) s.month,
            _monthKey(_nowUtc()),
          }.toList()
            ..sort((a, b) => b.compareTo(a));

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _monthRow(months),
                const SizedBox(height: 24),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: cpEuc),
                      ),
                    ),
                  )
                else if (r == null || r.reportMonth != _month)
                  _empty()
                else
                  _report(r),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Text(_error!, style: cpSans(size: 12, color: cpEuc)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _monthRow(List<String> months) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final m in months) ...[
            CpFilterChip(
              label: _monthLabel(m),
              selected: m == _month,
              onTap: () => _pick(m),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _empty() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const CpEmptyState(
          icon: Icons.insert_chart_outlined,
          text: '아직 이 달의 레포트가 없어요',
        ),
        const SizedBox(height: 12),
        Text(
          '레포트는 월말에 한 번 생성돼요.\n시연을 위해 지금 만들어 볼 수 있어요.',
          textAlign: TextAlign.center,
          style: cpSans(size: 12, color: cpInkA(0.45), height: 1.6),
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: 180,
            child: CpPrimaryButton(
                label: _busy ? '생성 중' : '레포트 생성', onTap: _generate),
          ),
        ),
      ],
    );
  }

  Widget _report(MonthlyReport r) {
    final total = r.photoCount + r.drawingCount + r.textCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CpSectionHeader(eyebrow: '성장', title: '이만큼 자랐어요'),
        const SizedBox(height: 16),
        _GrowthRow(from: r.petLevelStart, to: r.petLevelEnd),
        const SizedBox(height: 30),
        const CpHair(),
        const SizedBox(height: 22),
        CpSectionHeader(
          eyebrow: '낙서 유형',
          title: '$total개의 낙서',
          // `dominant_type` is null for a month with no doodles (v0.2:
          // `str | None`). Show the "주로 X" note only when there's a real
          // dominant kind — never coerce null into a fake type.
          trailing: r.dominantType == null
              ? null
              : Text(
                  '주로 ${_typeLabel(r.dominantType!)}',
                  style:
                      cpSans(size: 11, color: cpEuc, weight: FontWeight.w600),
                ),
        ),
        const SizedBox(height: 18),
        _Bar(label: '그림 위주', value: r.drawingCount, total: total),
        const SizedBox(height: 12),
        _Bar(label: '사진 위주', value: r.photoCount, total: total),
        const SizedBox(height: 12),
        _Bar(label: '텍스트 위주', value: r.textCount, total: total),
        const SizedBox(height: 22),
        Row(
          children: [
            CpEyebrow('찌르기', size: 9),
            const Spacer(),
            Text('${r.pokeCount}회',
                style: cpSans(size: 13, weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 30),
        const CpHair(),
        const SizedBox(height: 22),
        const CpSectionHeader(eyebrow: '이번 달', title: '최고의 낙서'),
        const SizedBox(height: 16),
        _BestDoodle(best: r.bestDoodle),
        const SizedBox(height: 30),
        Center(
          child: SizedBox(
            width: 180,
            child: CpPrimaryButton(
              label: _busy ? '다시 만드는 중' : '레포트 다시 생성',
              filled: false,
              onTap: _generate,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Pieces
// ===========================================================================

class _GrowthRow extends StatelessWidget {
  const _GrowthRow({required this.from, required this.to});

  final int from;
  final int to;

  @override
  Widget build(BuildContext context) {
    final gained = to - from;
    return Row(
      children: [
        _LevelPill('LV $from'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(height: 1, color: cpInkA(0.14)),
          ),
        ),
        _LevelPill('LV $to', accent: true),
        const SizedBox(width: 12),
        Text(
          gained > 0 ? '+$gained' : '변화 없음',
          style: cpSans(
            size: 12,
            color: gained > 0 ? cpEuc : cpInkA(0.4),
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill(this.text, {this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? cpEucA(0.12) : cpPrint,
        borderRadius: BorderRadius.circular(cpRadiusPill),
        border: Border.all(
          color: accent ? cpEucA(0.5) : cpInkA(0.12),
        ),
      ),
      child: Text(text,
          style: cpSans(
            size: 11,
            color: accent ? cpEuc : cpInkA(0.65),
            weight: FontWeight.w600,
            spacing: 0.6,
          )),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.total});

  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final frac = total <= 0 ? 0.0 : value / total;
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: cpSans(size: 12, color: cpInkA(0.7))),
            const Spacer(),
            Text('$value',
                style: cpSans(size: 12, weight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(cpRadiusPill),
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Container(width: c.maxWidth, height: 8, color: cpInkA(0.10)),
                Container(
                  width: c.maxWidth * frac,
                  height: 8,
                  decoration: BoxDecoration(
                    color: cpEuc,
                    borderRadius: BorderRadius.circular(cpRadiusPill),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BestDoodle extends StatelessWidget {
  const _BestDoodle({required this.best});

  final BestDoodle? best;

  @override
  Widget build(BuildContext context) {
    final b = best;
    if (b == null) {
      return const CpEmptyState(
        icon: Icons.image_not_supported_outlined,
        text: '뽑을 낙서가 없었어요',
      );
    }
    final repo = appState.repo;
    final strokes = repo is MockRepository ? repo.strokeDataFor(b.id) : null;

    return Column(
      children: [
        CpMatted(
          mat: 16,
          inset: 8,
          child: SizedBox(
            height: 190,
            child: _bestPreview(b, strokes),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cpEucA(0.10),
            borderRadius: BorderRadius.circular(cpRadiusPill),
            border: Border.all(color: cpEucA(0.4)),
          ),
          child: Text(_ruleLabel(b.rule),
              style: cpSans(size: 11, color: cpEuc, weight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Text(_stamp(b.createdAt),
            style: cpSans(size: 11, color: cpInkA(0.45))),
      ],
    );
  }

  /// Render the winning doodle by its own [ContentType] (v0.2: the winner can be
  /// a photo, drawing, or text). Cached strokes paint the real drawing; a text
  /// winner shows its real `text_body`; anything else (a photo, or a drawing
  /// behind a network URL we can't load offline) falls back to an honest
  /// content-type line icon — never a faked drawing.
  Widget _bestPreview(BestDoodle b, StrokeData? strokes) {
    if (strokes != null && strokes.strokes.isNotEmpty) {
      return CustomPaint(
        painter: CpDoodlePainter(strokes, background: cpPrint),
        size: Size.infinite,
      );
    }
    if (b.contentType == ContentType.text &&
        (b.textBody?.trim().isNotEmpty ?? false)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            b.textBody!,
            textAlign: TextAlign.center,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: cpSans(size: 15, color: cpInkA(0.78), height: 1.5),
          ),
        ),
      );
    }
    return Center(
      child: Icon(_bestIcon(b), size: 40, color: cpInkA(0.3)),
    );
  }
}

// ===========================================================================
// Helpers
// ===========================================================================

/// 'now' without a wall clock: the deterministic mock clock, else the newest
/// memory, else the seeded demo date. Never `DateTime.now()`.
DateTime _nowUtc() {
  final r = appState.repo;
  if (r is MockRepository) return r.clock.now();
  final a = appState.album;
  if (a.isNotEmpty) return a.first.createdAt;
  return DateTime.utc(2026, 7, 10);
}

String _two(int n) => n < 10 ? '0$n' : '$n';

String _monthKey(DateTime d) => '${d.year}-${_two(d.month)}';

String _monthLabel(String key) {
  final parts = key.split('-');
  if (parts.length != 2) return key;
  return '${parts[0]}년 ${int.tryParse(parts[1]) ?? parts[1]}월';
}

String _stamp(DateTime utc) {
  final t = utc.toLocal();
  return '${t.year}. ${t.month}. ${t.day}';
}

String _typeLabel(ContentType c) => switch (c) {
      ContentType.drawing => '그림',
      ContentType.photo => '사진',
      ContentType.text => '텍스트',
    };

/// The content-type line icon for a best doodle that can't be stroke-painted.
/// Branches on the winner's own [ContentType] (v0.2) — a photo shows the image
/// glyph, a drawing the brush glyph, text the notes glyph. A vector Material
/// outlined icon, never an emoji.
IconData _bestIcon(BestDoodle b) => switch (b.contentType) {
      ContentType.photo => Icons.image_outlined,
      ContentType.drawing => Icons.brush_outlined,
      ContentType.text => Icons.notes_outlined,
    };

/// Tolerates a rule the app has never heard of (future vision selection).
String _ruleLabel(BestDoodleRule r) => switch (r) {
      BestDoodleRule.mostReplies => '답장이 가장 많았어요',
      BestDoodleRule.mostStrokes => '획이 가장 많았어요',
      BestDoodleRule.latest => '이 달의 마지막 낙서',
      BestDoodleRule.unknown => '특별히 골랐어요',
    };
