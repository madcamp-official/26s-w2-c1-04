// 4e 펫 상호작용 — 쓰다듬다 뜨는 풀스크린 깜짝 낙서 (양쪽 동시 팝업).
// 디자인: Memory Pager 디자인.dc.html #4e (390x844) 실측값 그대로.

import 'package:flutter/material.dart';

import '../mock.dart';
import '../pet.dart';
import '../theme.dart';

const double _deg = 0.017453292519943295; // pi/180

class SurpriseScreen extends StatelessWidget {
  const SurpriseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mock,
      builder: (context, _) {
        // 실서버에서 모리가 실제로 그린 그림(일기 이미지)이 있는지.
        // 없으면 커플 그림을 지어내지 않고, 배우는 중임을 정직하게 안내한다(#18).
        final realArt = mock.real
            ? mock.diary
                .where((d) => d.imageUrl != null && d.imageUrl!.isNotEmpty)
                .toList()
            : const <DiaryEntry>[];
        final DiaryEntry? latest = realArt.isNotEmpty ? realArt.first : null;
        final learning = mock.real && latest == null; // 실서버인데 아직 그림 없음
        return Scaffold(
          backgroundColor: mock.roomColor,
          body: SafeArea(
            bottom: false,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // ---- 헤더 문구 (design top:96, 상태바 52 제외)
                Positioned(
                  top: 44,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(learning ? '삐삐- 조금만 기다려줘' : '삐삐- 깜짝 선물!',
                          style: hand(17, c: coral, ls: 2)),
                      const SizedBox(height: 4),
                      Text(
                          learning
                              ? '${mock.petName}가 그림을 배우는 중이에요'
                              : '${mock.petName}가 그림을 그렸어요',
                          style: sans(22, w: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                          learning
                              ? '낙서를 주고받을수록 그림 실력이 늘어요'
                              : '두 사람의 그림체를 배워서 그렸대요',
                          style: sans(12.5, c: brownWarm)),
                    ],
                  ),
                ),

                // ---- 메인 카드 (design top:210, rotate -1.5deg)
                Positioned(
                  top: 158,
                  left: 32,
                  right: 32,
                  child: Transform.rotate(
                    angle: -1.5 * _deg,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: brownWarm.withValues(alpha: .25),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 10),
                            decoration: BoxDecoration(
                              color: paperDiary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: learning
                                  ? _LearningCard(petName: mock.petName)
                                  : latest != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            latest.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const CustomPaint(
                                                    painter: _ScenePainter()),
                                          ),
                                        )
                                      : const CustomPaint(
                                          painter: _ScenePainter()),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      learning
                                          ? '둘의 낙서를 모으는 중'
                                          : (latest?.caption.isNotEmpty ?? false)
                                              ? latest!.caption
                                              : '억새밭에서 손잡은 우리',
                                      style: hand(18, c: brown)),
                                ),
                                if (!learning)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: goldBg,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      '일기장에 자동 저장',
                                      style: sans(11.5,
                                          w: FontWeight.w800, c: goldText),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---- 상대 화면 동시 팝업 안내 필 (design bottom:150)
                // 실제 모리 그림이 떴을 때만 안내한다(배우는 중엔 동시 이벤트가 없다).
                if (!learning)
                Positioned(
                  bottom: 150,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 9, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: partnerBlueBg,
                              shape: BoxShape.circle,
                            ),
                            child: Text('나',
                                style: sans(10,
                                    w: FontWeight.w800, c: partnerBlue)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${mock.partnerNick} 화면에도 지금 같이 떴어요',
                            style:
                                sans(12.5, w: FontWeight.w700, c: inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---- 칭찬하기 CTA (design bottom:80)
                Positioned(
                  bottom: 80,
                  left: 24,
                  right: 24,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: coral,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: coral.withValues(alpha: .35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('♥', style: sans(17, c: Colors.white)),
                          const SizedBox(width: 8),
                          Text('${mock.petName} 칭찬하기',
                              style: sans(15,
                                  w: FontWeight.w800, c: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),

                // ---- 화면 아래로 빼꼼한 모리 (design bottom:-34)
                Positioned(
                  bottom: -34,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: PetFace(
                      size: 150,
                      eyesOpen: false,
                      cheeks: false,
                    ),
                  ),
                ),

                // ---- 닫기 ✕ (design top:62 right:20)
                Positioned(
                  top: 10,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .8),
                        shape: BoxShape.circle,
                      ),
                      child: Text('✕',
                          style: sans(15, w: FontWeight.w700, c: brown)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 아직 모리가 그림을 못 그린 초기 상태(#18) — 커플 그림을 지어내지 않고,
/// 낙서가 쌓이면 그림을 그리기 시작한다고 정직하게 안내한다.
class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.petName});

  final String petName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🎨', style: sans(34)),
        const SizedBox(height: 10),
        Text(
          '아직 그릴 만큼 배우지 못했어요',
          style: sans(13.5, w: FontWeight.w700, c: brown),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '둘이 손그림 낙서를 주고받으면\n$petName가 그림체를 배워 그리기 시작해요',
            textAlign: TextAlign.center,
            style: sans(11.5, c: brownWarm, h: 1.5),
          ),
        ),
      ],
    );
  }
}

/// 일기 scene0 — 손잡은 두 졸라맨 + 하트 + 억새 (design SVG viewBox 0 0 200 150).
class _ScenePainter extends CustomPainter {
  const _ScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 200, sy = size.height / 150;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * sy
      ..strokeCap = StrokeCap.round;

    // --- 코랄 졸라맨 (나)
    final coral3 = stroke(coral, 3);
    canvas.drawCircle(p(70, 52), 16 * sy, coral3);
    canvas.drawPath(
      Path()
        ..moveTo(63 * sx, 54 * sy)
        ..quadraticBezierTo(66 * sx, 58 * sy, 70 * sx, 55 * sy),
      stroke(coral, 2),
    );
    canvas.drawLine(p(70, 68), p(70, 104), coral3);
    canvas.drawLine(p(70, 80), p(96, 88), coral3);
    canvas.drawLine(p(70, 104), p(58, 128), coral3);
    canvas.drawLine(p(70, 104), p(82, 128), coral3);

    // --- 파랑 졸라맨 (상대)
    final blue3 = stroke(partnerBlue, 3);
    canvas.drawCircle(p(124, 54), 16 * sy, blue3);
    canvas.drawPath(
      Path()
        ..moveTo(118 * sx, 56 * sy)
        ..quadraticBezierTo(121 * sx, 60 * sy, 125 * sx, 57 * sy),
      stroke(partnerBlue, 2),
    );
    canvas.drawLine(p(124, 70), p(124, 106), blue3);
    canvas.drawLine(p(124, 82), p(96, 88), blue3);
    canvas.drawLine(p(124, 106), p(112, 130), blue3);
    canvas.drawLine(p(124, 106), p(136, 130), blue3);

    // --- 하트
    final heart = Path()
      ..moveTo(97 * sx, 26 * sy)
      ..cubicTo(94 * sx, 20 * sy, 86 * sx, 20 * sy, 86 * sx, 27 * sy)
      ..cubicTo(86 * sx, 32 * sy, 97 * sx, 39 * sy, 97 * sx, 39 * sy)
      ..cubicTo(97 * sx, 39 * sy, 108 * sx, 32 * sy, 108 * sx, 27 * sy)
      ..cubicTo(108 * sx, 20 * sy, 100 * sx, 20 * sy, 97 * sx, 26 * sy)
      ..close();
    canvas.drawPath(heart, Paint()..color = coral);

    // --- 억새 풀
    final grass = stroke(goldText, 2.5);
    canvas.drawLine(p(20, 138), p(30, 122), grass);
    canvas.drawLine(p(30, 138), p(38, 126), grass);
    canvas.drawLine(p(168, 138), p(176, 122), grass);
    canvas.drawLine(p(178, 138), p(184, 128), grass);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => false;
}
