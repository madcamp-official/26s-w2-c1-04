// char_00_reference — "몽실" (Mongsil), the reference character.
//
// A soft egg-shaped blob with a warm brown hand-drawn outline, two dot eyes, a
// tiny smile, pink blush, and a little heart perched on its head — the cozy
// crayon look of the brief's first reference. It exists to prove the toolkit,
// the idle animation, and the QA screenshot pipeline. The ten generated
// characters replace this look while keeping the same [PetCharacter] contract.

import 'package:flutter/material.dart';

import '../toolkit.dart';

class ReferenceCharacter extends PetCharacter {
  @override
  String get id => '00';
  @override
  String get name => '몽실';
  @override
  String get concept => '크레용으로 그린 듯한 달걀 블롭 — 따뜻한 갈색 외곽선, 점 눈, 머리 위 작은 하트.';
  @override
  String get signature => '숨 쉴 때 몸이 살짝 부풀고, 가끔 눈을 깜빡이며, 하트가 좌우로 살랑인다.';
  @override
  List<String> get inspiration => const ['cozy crayon blob mascot', 'egg character with heart'];
  @override
  Color get accent => const Color(0xFFE8A0A8);

  @override
  Widget build(BuildContext context, {double? frozenT}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _MongsilPainter(f),
        size: Size.infinite,
      ),
    );
  }
}

class _MongsilPainter extends CustomPainter {
  _MongsilPainter(this.f);
  final IdleFrame f;

  static const _cream = Color(0xFFFFFDF7);
  static const _ink = Color(0xFF9A8267); // warm brown outline
  static const _inkSoft = Color(0xFF6B5B47);
  static const _heart = Color(0xFFE8969E);
  static const _heartDark = Color(0xFFD97F88);
  static const _blush = Color(0xFFF3B0B4);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Hand.paperGrain(canvas, Offset.zero & size, seed: 4, dots: 70);

    final cx = w / 2;
    final baseCy = h * 0.60 + f.bob;
    final rx = w * 0.30;
    final ry = w * 0.36 * f.breath;

    canvas.save();
    canvas.translate(cx, baseCy);

    // Body — a wobbly egg, cream fill + soft thick outline.
    final body = Hand.blob(Offset.zero, rx, ry: ry, wobble: 3.2, seed: 5, squash: 0.10);
    // soft drop to ground the shape
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, ry * 0.98), width: rx * 1.5, height: ry * 0.28),
      Hand.fill(const Color(0x14000000)),
    );
    canvas.drawPath(body, Hand.fill(_cream));
    canvas.drawPath(body, Hand.outline(_ink, 5.5));

    // Face — placed low on the body (kawaii rule).
    final eyeY = ry * 0.18;
    final eyeDx = rx * 0.42;
    final eyeR = rx * 0.11;
    if (f.blink > 0.5) {
      Hand.blinkEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft, width: 3.4);
      Hand.blinkEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft, width: 3.4);
    } else {
      Hand.dotEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft);
      Hand.dotEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft);
    }
    Hand.blush(canvas, Offset(-eyeDx * 1.15, eyeY + eyeR * 1.9), rx * 0.16, _blush);
    Hand.blush(canvas, Offset(eyeDx * 1.15, eyeY + eyeR * 1.9), rx * 0.16, _blush);
    Hand.smile(canvas, Offset(0, eyeY + eyeR * 2.4), rx * 0.22, rx * 0.12, _inkSoft, width: 3.2);

    canvas.restore();

    // Heart on the head — sways gently.
    final headTop = baseCy - ry + f.bob * 0.4;
    final hx = cx + f.sway * 1.4;
    final hy = headTop - rx * 0.16;
    _drawHeart(canvas, Offset(hx, hy), rx * 0.34);
  }

  void _drawHeart(Canvas canvas, Offset center, double s) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(f.sway * 0.02);
    final path = Path();
    path.moveTo(0, s * 0.30);
    path.cubicTo(-s * 1.0, -s * 0.55, -s * 0.55, -s * 1.1, 0, -s * 0.45);
    path.cubicTo(s * 0.55, -s * 1.1, s * 1.0, -s * 0.55, 0, s * 0.30);
    path.close();
    canvas.drawPath(path, Hand.fill(_heart));
    canvas.drawPath(path, Hand.outline(_heartDark, 3.5));
    // tiny face on the heart
    Hand.dotEye(canvas, Offset(-s * 0.28, -s * 0.30), s * 0.10, _heartDark, glossy: false);
    Hand.dotEye(canvas, Offset(s * 0.10, -s * 0.30), s * 0.10, _heartDark, glossy: false);
    Hand.smile(canvas, Offset(-s * 0.08, -s * 0.12), s * 0.28, s * 0.10, _heartDark, width: 2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MongsilPainter old) => old.f.t != f.t;
}
