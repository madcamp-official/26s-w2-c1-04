// 펫 "모리" — 디자인 SVG(viewBox 0 0 120 110)를 그대로 CustomPainter 로 옮김.
// 몸통 ellipse(60,62,rx42,ry38) + 귀 circle(30,26,r12)(90,26,r12) + 눈 + 볼 + 미소.
// 이웃집(1h)은 lilac 색, 펫꾸미기(1g)는 중절모 hat 옵션.

import 'package:flutter/material.dart';

import 'mock.dart';
import 'theme.dart';

/// 펫 + 착용 아이템 이모지 오버레이(#12). 132 기준 배치를 size 에 비례해 스케일.
/// 옷/가구/배경/소품/모자를 착용하면 캐릭터 위/주변에 이모지로 나타난다.
class DecoratedPet extends StatelessWidget {
  const DecoratedPet({
    super.key,
    required this.size,
    this.color = salmon,
    this.faceInk = ink,
    this.showBackground = true,
  });

  final double size;
  final Color color;
  final Color faceInk;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final s = size / 132;
    final hat = mock.equippedEmoji('hat');
    final clothes = mock.equippedEmoji('clothes');
    final acc = mock.equippedEmoji('accessory');
    final prop = mock.equippedEmoji('prop');
    final furniture = mock.equippedEmoji('furniture');
    final bg = mock.equippedEmoji('background');
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (showBackground && bg != null)
            Center(
              child: Opacity(
                opacity: .3,
                child: Text(bg, style: TextStyle(fontSize: 96 * s)),
              ),
            ),
          Center(child: PetFace(size: size, color: color, faceInk: faceInk)),
          if (hat != null)
            Positioned(
                top: -8 * s, child: Text(hat, style: TextStyle(fontSize: 36 * s))),
          if (acc != null)
            Positioned(
                top: 38 * s,
                right: 6 * s,
                child: Text(acc, style: TextStyle(fontSize: 24 * s))),
          if (clothes != null)
            Positioned(
                bottom: 18 * s,
                child: Text(clothes, style: TextStyle(fontSize: 30 * s))),
          if (prop != null)
            Positioned(
                bottom: 0,
                right: -6 * s,
                child: Text(prop, style: TextStyle(fontSize: 26 * s))),
          if (furniture != null)
            Positioned(
                bottom: 0,
                left: -6 * s,
                child: Text(furniture, style: TextStyle(fontSize: 26 * s))),
        ],
      ),
    );
  }
}

class PetFace extends StatelessWidget {
  const PetFace({
    super.key,
    this.size = 120,
    this.color = salmon,
    this.faceInk = ink,
    this.hat = false,
    this.cheeks = true,
    this.eyesOpen = true,
  });

  final double size;
  final Color color;
  final Color faceInk;
  final bool hat;
  final bool cheeks;
  final bool eyesOpen;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 110 / 120),
      painter: _PetPainter(
        color: color,
        faceInk: faceInk,
        hat: hat,
        cheeks: cheeks,
        eyesOpen: eyesOpen,
      ),
    );
  }
}

class _PetPainter extends CustomPainter {
  const _PetPainter({
    required this.color,
    required this.faceInk,
    required this.hat,
    required this.cheeks,
    required this.eyesOpen,
  });

  final Color color;
  final Color faceInk;
  final bool hat;
  final bool cheeks;
  final bool eyesOpen;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 120, sy = size.height / 110;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final body = Paint()..color = color;

    // 귀 → 몸통 (디자인 SVG 순서)
    canvas.drawCircle(p(30, 26), 12 * sx, body);
    canvas.drawCircle(p(90, 26), 12 * sx, body);
    canvas.drawOval(
      Rect.fromCenter(center: p(60, 62), width: 84 * sx, height: 76 * sy),
      body,
    );

    // 모자 (1g 중절모: rect 42,8,36x14 r7 + rect 50,0,20x14 r6)
    if (hat) {
      final hp = Paint()..color = faceInk;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(42 * sx, 8 * sy, 36 * sx, 14 * sy),
            Radius.circular(7 * sx)),
        hp,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(50 * sx, 0, 20 * sx, 14 * sy),
            Radius.circular(6 * sx)),
        hp,
      );
    }

    // 볼 (흰 55%)
    if (cheeks) {
      final cheek = Paint()..color = Colors.white.withValues(alpha: 0.55);
      canvas.drawOval(
        Rect.fromCenter(center: p(38, 70), width: 12 * sx, height: 8 * sy),
        cheek,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p(82, 70), width: 12 * sx, height: 8 * sy),
        cheek,
      );
    }

    // 눈
    final eye = Paint()..color = faceInk;
    if (eyesOpen) {
      canvas.drawCircle(p(46, 58), 4 * sx, eye);
      canvas.drawCircle(p(74, 58), 4 * sx, eye);
    } else {
      final st = Paint()
        ..color = faceInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * sx
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(42 * sx, 58 * sy)
          ..quadraticBezierTo(46 * sx, 54 * sy, 50 * sx, 58 * sy),
        st,
      );
      canvas.drawPath(
        Path()
          ..moveTo(70 * sx, 58 * sy)
          ..quadraticBezierTo(74 * sx, 54 * sy, 78 * sx, 58 * sy),
        st,
      );
    }

    // 미소 M56 66 Q60 70 64 66
    final smile = Paint()
      ..color = faceInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(56 * sx, 66 * sy)
        ..quadraticBezierTo(60 * sx, 70 * sy, 64 * sx, 66 * sy),
      smile,
    );
  }

  @override
  bool shouldRepaint(covariant _PetPainter old) =>
      old.color != color ||
      old.hat != hat ||
      old.cheeks != cheeks ||
      old.eyesOpen != eyesOpen;
}

/// 탭바용 미니 펫 아이콘 (design 2a 네 번째 탭).
class PetTabIcon extends StatelessWidget {
  const PetTabIcon({super.key, this.color = muted, this.size = 23});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _PetTabPainter(color));
  }
}

class _PetTabPainter extends CustomPainter {
  const _PetTabPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final body = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(12 * s, 13.5 * s), width: 16 * s, height: 14 * s),
      body,
    );
    canvas.drawCircle(Offset(6.5 * s, 6 * s), 2.6 * s, body);
    canvas.drawCircle(Offset(17.5 * s, 6 * s), 2.6 * s, body);
    final eye = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(9.3 * s, 13 * s), 1.1 * s, eye);
    canvas.drawCircle(Offset(14.7 * s, 13 * s), 1.1 * s, eye);
  }

  @override
  bool shouldRepaint(covariant _PetTabPainter old) => old.color != color;
}
