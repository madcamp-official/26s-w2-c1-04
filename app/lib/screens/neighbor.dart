// 1h 이웃 집 방문 — 풀스크린 라일락 방 + 그룹 코드로 집 찾아가기.
// 디자인: Memory Pager 디자인.dc.html #1h (390x844).

import 'package:flutter/material.dart';

import '../pet.dart';
import '../theme.dart';

class NeighborScreen extends StatefulWidget {
  const NeighborScreen({super.key});

  @override
  State<NeighborScreen> createState() => _NeighborScreenState();
}

class _NeighborScreenState extends State<NeighborScreen> {
  bool _showSearch = false;
  int _likes = 128;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lilacBg,
      body: Stack(
        children: [
          // ---- 바닥
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: ColoredBox(color: Color(0xFFE3D5F7)),
          ),

          // ---- 창문 (top:190 left:42, 106x106 — 상태바 52 제외 좌표)
          const Positioned(
            top: 138,
            left: 42,
            child: CustomPaint(size: Size(106, 106), painter: _WindowPainter()),
          ),

          // ---- 플로어 램프 (right:38, 바닥 위)
          const Positioned(
            right: 38,
            bottom: 190,
            child: CustomPaint(size: Size(48, 106), painter: _LampPainter()),
          ),

          // ---- 러그
          Positioned(
            left: 0,
            right: 0,
            bottom: 158,
            child: Center(
              child: Container(
                width: 256,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8C6F2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),

          // ---- 펫 (별이)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 184,
            child: Center(
              child: SizedBox(
                width: 172,
                height: 160,
                child: PetFace(
                  size: 172,
                  color: lilac,
                  faceInk: Color(0xFF2E2440),
                ),
              ),
            ),
          ),

          // ---- 말풍선
          Positioned(
            left: 0,
            right: 0,
            bottom: 352,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      offset: const Offset(0, 3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  '어서와, 우리 집은 처음이지?',
                  style: hand(18, c: lilacInk),
                ),
              ),
            ),
          ),

          // ---- 상단 바 + 검색 카드
          SafeArea(
            child: Stack(
              children: [
                // 뒤로가기
                Positioned(
                  top: 10,
                  left: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF785AA0)
                                .withValues(alpha: 0.18),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CustomPaint(
                          size: Size(17, 17),
                          painter: _ChevronPainter(
                              color: lilacInk, forward: false),
                        ),
                      ),
                    ),
                  ),
                ),

                // 집 이름 필
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF785AA0)
                                .withValues(alpha: 0.12),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('별이네 집',
                              style: sans(14, w: FontWeight.w800)),
                          const SizedBox(width: 8),
                          Text(
                            '하늘 ♥ 바다 · D+89',
                            style: sans(12,
                                w: FontWeight.w700,
                                c: const Color(0xFF8A7A9B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 검색 버튼
                Positioned(
                  top: 10,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => setState(() => _showSearch = !_showSearch),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: lilac,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF785AA0)
                                .withValues(alpha: 0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: CustomPaint(
                          size: Size(17, 17),
                          painter: _SearchPainter(),
                        ),
                      ),
                    ),
                  ),
                ),

                // 그룹 코드 찾아가기 카드
                if (_showSearch)
                  Positioned(
                    top: 62,
                    right: 20,
                    child: Container(
                      width: 224,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF785AA0)
                                .withValues(alpha: 0.22),
                            offset: const Offset(0, 10),
                            blurRadius: 26,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '그룹 코드로 집 찾아가기',
                            style:
                                sans(12, w: FontWeight.w800, c: lilacInk),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F0FA),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Text(
                                    '코드 입력',
                                    style: sans(13,
                                        ls: 2,
                                        c: const Color(0xFFB0A3C2)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: lilac,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Center(
                                  child: CustomPaint(
                                    size: Size(15, 15),
                                    painter: _ChevronPainter(
                                        color: Colors.white, forward: true),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ---- 하단: 펫 이름 + 레벨
          Positioned(
            left: 0,
            right: 0,
            bottom: 92,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('별이', style: sans(17, w: FontWeight.w800)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: lilac,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Lv.6',
                    style: sans(12, w: FontWeight.w800, c: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // ---- 하단: 좋아요 필
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _likes += 1),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFF785AA0).withValues(alpha: 0.2),
                        offset: const Offset(0, 8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('♥', style: sans(18, c: coral)),
                      const SizedBox(width: 8),
                      Text('$_likes',
                          style: sans(15, w: FontWeight.w800, c: coral)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- painters

/// 창문 — viewBox 0 0 60 60: 흰 라운드 프레임 + 라일락 십자.
class _WindowPainter extends CustomPainter {
  const _WindowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 60;
    const frame = Color(0xFFC9B8E8);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(3 * s, 3 * s, 54 * s, 54 * s),
      Radius.circular(10 * s),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFFDFBFF));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = frame
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * s,
    );

    final cross = Paint()
      ..color = frame
      ..strokeWidth = 4 * s;
    canvas.drawLine(Offset(30 * s, 8 * s), Offset(30 * s, 52 * s), cross);
    canvas.drawLine(Offset(8 * s, 30 * s), Offset(52 * s, 30 * s), cross);
  }

  @override
  bool shouldRepaint(covariant _WindowPainter old) => false;
}

/// 플로어 램프 — viewBox 0 0 40 90: 라일락 갓 + 회보라 기둥·받침.
class _LampPainter extends CustomPainter {
  const _LampPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 40, sy = size.height / 90;
    const pole = Color(0xFF8A7A9B);

    // 갓 M8 24 L32 24 L26 4 L14 4 Z
    final shade = Path()
      ..moveTo(8 * sx, 24 * sy)
      ..lineTo(32 * sx, 24 * sy)
      ..lineTo(26 * sx, 4 * sy)
      ..lineTo(14 * sx, 4 * sy)
      ..close();
    canvas.drawPath(shade, Paint()..color = lilac);

    // 기둥
    canvas.drawLine(
      Offset(20 * sx, 24 * sy),
      Offset(20 * sx, 78 * sy),
      Paint()
        ..color = pole
        ..strokeWidth = 4 * sx,
    );

    // 받침
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(20 * sx, 82 * sy),
          width: 24 * sx,
          height: 10 * sy),
      Paint()..color = pole,
    );
  }

  @override
  bool shouldRepaint(covariant _LampPainter old) => false;
}

/// 좌/우 셰브론 — stroke 2.5, round cap/join.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color, required this.forward});

  final Color color;
  final bool forward;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = forward
        ? (Path()
          ..moveTo(10 * s, 6 * s)
          ..lineTo(16 * s, 12 * s)
          ..lineTo(10 * s, 18 * s))
        : (Path()
          ..moveTo(14 * s, 6 * s)
          ..lineTo(8 * s, 12 * s)
          ..lineTo(14 * s, 18 * s));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter old) =>
      old.color != color || old.forward != forward;
}

/// 돋보기 — 흰 stroke 2.5.
class _SearchPainter extends CustomPainter {
  const _SearchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(10 * s, 10 * s), 6 * s, paint);
    canvas.drawLine(Offset(15 * s, 15 * s), Offset(20 * s, 20 * s), paint);
  }

  @override
  bool shouldRepaint(covariant _SearchPainter old) => false;
}
