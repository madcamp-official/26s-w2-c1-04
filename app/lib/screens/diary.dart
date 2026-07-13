// 4f 모리의 그림 일기장 — 디자인 HTML 실측 그대로.
// paperDiary 바탕, 흰 r22 카드(골드 그림자) + goldDash 점선 프레임 안에
// 펫이 그린 손그림 장면(CustomPainter) + Gaegu 캡션.

import 'package:flutter/material.dart';

import '../mock.dart';
import '../theme.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paperDiary,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: mock,
          builder: (context, _) {
            return Column(
              children: [
                // ---- 헤더: ← / 타이틀 컬럼 / 균형용 스페이서
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text('←',
                              style: sans(16, w: FontWeight.w700, c: muted)),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('${mock.petName}의 그림 일기장',
                                style: sans(17, w: FontWeight.w800)),
                            Text('${mock.petName}가 배운 그림체로 그렸어요',
                                style: hand(13, c: goldText)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                // ---- 일기 카드들
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: mock.diary.isEmpty
                        ? _emptyDiary(mock.petName)
                        : Column(
                            children: [
                              for (int i = 0; i < mock.diary.length; i++) ...[
                                if (i > 0) const SizedBox(height: 14),
                                _DiaryCard(entry: mock.diary[i]),
                              ],
                            ],
                          ),
                  ),
                ),
                // ---- 하단 페이지 도트
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 18,
                        height: 6,
                        decoration: BoxDecoration(
                          color: coral,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _dot(),
                      const SizedBox(width: 6),
                      _dot(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyDiary(String petName) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Text('아직 그린 일기가 없어요',
                style: sans(15, w: FontWeight.w700, c: muted)),
            const SizedBox(height: 8),
            Text('$petName가 너희 낙서를 보고 그림을 그리면\n여기에 하나씩 쌓여요',
                textAlign: TextAlign.center, style: hand(15, c: goldText)),
          ],
        ),
      );

  Widget _dot() => Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: goldDash,
          shape: BoxShape.circle,
        ),
      );
}

// ---------------------------------------------------------------- card
class _DiaryCard extends StatelessWidget {
  const _DiaryCard({required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final scene0 = entry.scene == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: goldText.withValues(alpha: entry.isNew ? 0.10 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(entry.dateLabel, style: hand(17, c: goldText)),
              const Spacer(),
              if (entry.isNew)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: coral,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('NEW',
                      style:
                          sans(11.5, w: FontWeight.w700, c: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // 점선 프레임 + (실서버 이미지 or 손그림 장면)
          SizedBox(
            width: double.infinity,
            height: entry.isRemote ? 150 : (scene0 ? 130 : 110),
            child: CustomPaint(
              painter: _DashedFramePainter(),
              child: entry.isRemote
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          entry.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (ctx, err, st) => Center(
                              child: Text('그림을 불러오지 못했어요',
                                  style: hand(14, c: goldText))),
                          loadingBuilder: (ctx, child, p) =>
                              p == null ? child : const SizedBox.shrink(),
                        ),
                      ),
                    )
                  : Center(
                      child: scene0
                          ? const CustomPaint(
                              size: Size(114 * 200 / 110, 114),
                              painter: _HoldingHandsScene(),
                            )
                          : const CustomPaint(
                              size: Size(94 * 200 / 90, 94),
                              painter: _TteokbokkiScene(),
                            ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(entry.caption, style: hand(16, c: brown, h: 1.5)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- dashed frame
/// paperDiary 배경 + goldDash 1.5px 점선 r14 프레임.
class _DashedFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, Paint()..color = paperDiary);

    final stroke = Paint()
      ..color = goldDash
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 4.5;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(
            metric.extractPath(d, (d + dash).clamp(0, metric.length)), stroke);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedFramePainter oldDelegate) => false;
}

// ---------------------------------------------------------------- scenes
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// 장면 0 — 손 잡은 두 사람(코랄·블루 졸라맨) + 하트 + 풀숲. viewBox 200x110.
class _HoldingHandsScene extends CustomPainter {
  const _HoldingHandsScene();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 200, sy = size.height / 110;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final me = _stroke(coral, 3 * sx);
    final you = _stroke(partnerBlue, 3 * sx);
    final grass = _stroke(goldText, 2.5 * sx);

    // 나 (코랄): 머리 + 몸 + 팔(중앙으로) + 다리
    canvas.drawCircle(p(75, 36), 13 * sx, me);
    canvas.drawLine(p(75, 49), p(75, 78), me);
    canvas.drawLine(p(75, 58), p(97, 64), me);
    canvas.drawLine(p(75, 78), p(65, 98), me);
    canvas.drawLine(p(75, 78), p(85, 98), me);

    // 상대 (블루)
    canvas.drawCircle(p(120, 38), 13 * sx, you);
    canvas.drawLine(p(120, 51), p(120, 80), you);
    canvas.drawLine(p(120, 60), p(97, 64), you);
    canvas.drawLine(p(120, 80), p(110, 100), you);
    canvas.drawLine(p(120, 80), p(130, 100), you);

    // 하트 (두 사람 위)
    final heart = Path()
      ..moveTo(98 * sx, 16 * sy)
      ..cubicTo(95 * sx, 11 * sy, 88 * sx, 11 * sy, 88 * sx, 17 * sy)
      ..cubicTo(88 * sx, 21 * sy, 98 * sx, 27 * sy, 98 * sx, 27 * sy)
      ..cubicTo(98 * sx, 27 * sy, 108 * sx, 21 * sy, 108 * sx, 17 * sy)
      ..cubicTo(108 * sx, 11 * sy, 101 * sx, 11 * sy, 98 * sx, 16 * sy)
      ..close();
    canvas.drawPath(heart, Paint()..color = coral);

    // 구석 풀 스트로크
    canvas.drawLine(p(28, 104), p(38, 88), grass);
    canvas.drawLine(p(40, 104), p(48, 92), grass);
    canvas.drawLine(p(158, 104), p(166, 88), grass);
    canvas.drawLine(p(170, 104), p(176, 94), grass);
  }

  @override
  bool shouldRepaint(covariant _HoldingHandsScene oldDelegate) => false;
}

/// 장면 1 — 떡볶이 두 접시(코랄·블루) + 김 + 젓가락. viewBox 200x90.
class _TteokbokkiScene extends CustomPainter {
  const _TteokbokkiScene();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 200, sy = size.height / 90;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final me = _stroke(coral, 3 * sx);
    final you = _stroke(partnerBlue, 3 * sx);
    final steam = _stroke(muted, 2.5 * sx);
    final sticks = _stroke(goldText, 2.5 * sx);

    // 내 접시 (코랄): 사다리꼴 + 타원 테
    final myPlate = Path()
      ..moveTo(40 * sx, 48 * sy)
      ..lineTo(96 * sx, 48 * sy)
      ..lineTo(90 * sx, 72 * sy)
      ..lineTo(46 * sx, 72 * sy)
      ..close();
    canvas.drawPath(myPlate, me);
    canvas.drawOval(
      Rect.fromCenter(center: p(68, 48), width: 56 * sx, height: 12 * sy),
      me,
    );

    // 김
    canvas.drawPath(
      Path()
        ..moveTo(56 * sx, 36 * sy)
        ..quadraticBezierTo(59 * sx, 28 * sy, 56 * sx, 20 * sy),
      steam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(70 * sx, 36 * sy)
        ..quadraticBezierTo(73 * sx, 28 * sy, 70 * sx, 20 * sy),
      steam,
    );

    // 상대 접시 (블루)
    final yourPlate = Path()
      ..moveTo(112 * sx, 52 * sy)
      ..lineTo(160 * sx, 52 * sy)
      ..lineTo(155 * sx, 72 * sy)
      ..lineTo(117 * sx, 72 * sy)
      ..close();
    canvas.drawPath(yourPlate, you);
    canvas.drawOval(
      Rect.fromCenter(center: p(136, 52), width: 48 * sx, height: 10 * sy),
      you,
    );

    // 젓가락
    canvas.drawLine(p(150, 44), p(172, 24), sticks);
    canvas.drawLine(p(156, 48), p(178, 30), sticks);
  }

  @override
  bool shouldRepaint(covariant _TteokbokkiScene oldDelegate) => false;
}
