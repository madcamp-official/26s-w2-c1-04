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
                      Text('삐삐- 깜짝 선물!', style: hand(17, c: coral, ls: 2)),
                      const SizedBox(height: 4),
                      Text('${mock.petName}가 그림을 그렸어요',
                          style: sans(22, w: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('두 사람의 그림체를 배워서 그렸대요',
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
                            child: const SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: CustomPaint(painter: _ScenePainter()),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('억새밭에서 손잡은 우리',
                                      style: hand(18, c: brown)),
                                ),
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
