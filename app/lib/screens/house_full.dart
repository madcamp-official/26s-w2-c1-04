// 우리 집 전체 모습을 풀스크린으로 보는 화면(#13).
// 펫하우스의 '확대' 버튼으로 진입 — 이웃집이 아니라 우리 집 전경을 본다.

import 'package:flutter/material.dart';

import '../mock.dart';
import '../pet.dart';
import '../theme.dart';

class HouseFullscreenScreen extends StatelessWidget {
  const HouseFullscreenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mock.roomColor,
      body: ListenableBuilder(
        listenable: mock,
        builder: (context, _) => Stack(
          children: [
            // 바닥
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 200,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(color: Colors.black.withValues(alpha: .05)),
              ),
            ),
            // 러그
            Positioned(
              left: 0,
              right: 0,
              bottom: 150,
              child: Center(
                child: Container(
                  width: 260,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            // 우리 집 (지붕만 간단히)
            Positioned(
              left: 24,
              bottom: 236,
              child: CustomPaint(
                  size: const Size(96, 84), painter: _RoofPainter()),
            ),
            // 펫(착용 아이템 포함 #12)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 172,
              child: Center(child: DecoratedPet(size: 200)),
            ),
            // 말풍선
            Positioned(
              left: 0,
              right: 0,
              bottom: 404,
              child: Center(child: _bubble('여기가 우리 집이야!')),
            ),
            // 상단 바
            SafeArea(
              child: Stack(
                children: [
                  Positioned(top: 10, left: 20, child: _closeButton(context)),
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(child: _namePill()),
                  ),
                ],
              ),
            ),
            // 하단: 펫 이름 + 레벨
            Positioned(
              left: 0,
              right: 0,
              bottom: 92,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(mock.petName, style: sans(18, w: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: coral,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('Lv.${mock.petLevel}',
                        style: sans(12, w: FontWeight.w800, c: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Text(text, style: hand(18, c: inkSoft)),
      );

  Widget _namePill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${mock.petName}네 집', style: sans(14, w: FontWeight.w800)),
            const SizedBox(width: 8),
            Text('D+${mock.dDay}',
                style: sans(12, w: FontWeight.w700, c: brownWarm)),
          ],
        ),
      );

  Widget _closeButton(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, size: 20, color: ink),
        ),
      );
}

/// 간단한 집 지붕/몸통.
class _RoofPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()..color = const Color(0xFFF6C9C0);
    final roof = Paint()..color = coral;
    // 몸통
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.18, h * 0.42, w * 0.64, h * 0.58),
          const Radius.circular(8)),
      body,
    );
    // 지붕
    final p = Path()
      ..moveTo(w * 0.08, h * 0.46)
      ..lineTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.92, h * 0.46)
      ..close();
    canvas.drawPath(p, roof);
  }

  @override
  bool shouldRepaint(covariant _RoofPainter old) => false;
}
