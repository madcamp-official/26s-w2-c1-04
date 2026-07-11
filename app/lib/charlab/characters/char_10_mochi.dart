// char_10_mochi — "말랑이" (Mallangi), the squishy rice-cake blob.
//
// A soft mochi (떡) pillow: a wobbly rounded-square silhouette — wider than
// tall, settled at the bottom the way a warm rice cake slumps — with a warm
// crayon outline, two low glossy dot eyes, rosy cheeks, a tiny smile, two
// stubby feet, and a little green sakura-mochi leaf perched on top. Its idle
// move is a squash-and-stretch *jiggle* (mallang = 말랑, "squishy"), area-
// conserving so it reads as a bouncy rice cake rather than a breathing balloon,
// while a couple of rice-powder sparkles twinkle in the air beside it.
//
// Look learned from mochi / rice-cake mascots (see [inspiration]). Minimal,
// thick-lined, doodle-cat simplicity — one strong silhouette plus a few
// confident shapes, so it stays legible shrunk to a 56px roster thumbnail.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char10 extends PetCharacter {
  @override
  String get id => '10';
  @override
  String get name => '말랑이';
  @override
  String get concept => '말랑말랑한 떡 블롭 — 둥근 사각 실루엣, 낮은 점 눈, 볼터치, 머리 위 작은 잎사귀.';
  @override
  String get signature => '숨 대신 몸이 통통 눌렸다 늘어나는 떡 젤리 저글(squash-and-stretch), 잎사귀는 살랑, 쌀가루 반짝임이 흩날린다.';
  @override
  List<String> get inspiration => const [
        'Molang — round white rice-cake rabbit, blushy pink cheeks + dark button eyes (Hye-Ji Yoon)',
        'Mochi Mochi Peach Cat / Meowchi — pastel squishy rounded mochi kittens (Tasty Peach Studios)',
        'Dreamstime "Mochi Character" vector set — bold outline, rounded squishy body',
        'Shutterstock "Mochi Face Round Eyes Blush Cheeks" vector',
        'PIXTA 112868196 — Cute Mochi Mascot Character kawaii cartoon',
        'Freepik "Cute cartoon mochi mascot design character"',
        'Sakura Mochi Design Co. — Chibi Mochi collection (leaf-topped daifuku)',
        'DuduBubuShop "How to Draw Cute Mochi Cat" step-by-step (dot eyes + blush)',
        'Redbubble / Etsy kawaii mochi sticker sets — minimal thick-outline doodle mochi',
        'Pinterest kawaii doodles + "Mochi Drawing Cute" — pillow silhouette, tiny smile',
        'strawberry daifuku (ichigo mochi) — pale dusting + green leaf topping motif',
      ];
  @override
  Color get accent => const Color(0xFFF3C6CC);

  @override
  Widget build(BuildContext context, {double? frozenT}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P10(f),
        size: Size.infinite,
      ),
    );
  }
}

class _P10 extends CustomPainter {
  _P10(this.f);
  final IdleFrame f;

  // Warm, soft palette — a faintly pink rice-cake cream, never pure white/black.
  static const _10dough = Color(0xFFFDF2EE); // mochi cream (hint of pink)
  static const _10doughShade = Color(0xFFF3DDD5); // underside settle
  static const _10ink = Color(0xFF9E8468); // warm brown outline
  static const _10inkSoft = Color(0xFF6E5C48); // eyes / smile
  static const _10blush = Color(0xFFF29AA0); // warm coral-rose cheek
  static const _10leaf = Color(0xFFA9CE8E); // sakura-mochi leaf
  static const _10leafInk = Color(0xFF7FA968);
  static const _10sparkle = Color(0xFFEBB9BE); // rice-powder twinkle

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Faint paper grain — kept sparse so it never hazes into mud when shrunk.
    Hand.paperGrain(canvas, Offset.zero & size, seed: 7, dots: 36);

    final cx = w / 2;
    final baseCy = h * 0.56 + f.bob; // whole-body bob

    // Squash-and-stretch mochi jiggle, area-conserving (widens as it squishes
    // shorter) so it reads as a springy rice cake, not a breathing balloon.
    // Body height scales with f.breath; a faster secondary wobble adds bounce.
    final wob = math.sin(f.t * math.pi * 4) * 0.016;
    final stretchY = f.breath + wob; // taller as it inhales / bounces up
    final stretchX = (1 / f.breath) - wob; // conserves area → widens on squash

    final baseRx = w * 0.31; // body ~62% of the stage width
    final baseRy = w * 0.255; // wider than tall — the mochi pillow
    final rx = baseRx * stretchX;
    final ry = baseRy * stretchY;

    // Soft ground shadow — spreads a touch as the body squishes flatter/wider.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseCy + ry * 1.05),
        width: rx * 1.7,
        height: ry * 0.24,
      ),
      Hand.fill(const Color(0x18000000)),
    );

    canvas.save();
    canvas.translate(cx, baseCy);

    // Two stubby feet peeking out below (drawn first so the body overlaps them
    // into two clean foot-bumps at the bottom of the silhouette).
    for (final s in const [-1.0, 1.0]) {
      final foot = _10squircle(
        Offset(rx * 0.42 * s, ry * 0.94),
        rx * 0.20,
        rx * 0.14,
        exp: 0.66,
        wobble: 1.4,
        seed: 30 + (s > 0 ? 1 : 0),
      );
      canvas.drawPath(foot, Hand.fill(_10dough));
      canvas.drawPath(foot, Hand.outline(_10ink, 4.5));
    }

    // Body — a wobbly rounded-square mochi pillow, settled at the bottom.
    final body = _10squircle(
      Offset.zero,
      rx,
      ry,
      exp: 0.62, // < 1 → squarer corners (a pillow, not an ellipse)
      wobble: 3.0,
      seed: 11,
      squash: 0.12,
    );
    // Soft doughy underside shade for a squishy read.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, ry * 0.42),
        width: rx * 1.5,
        height: ry * 0.9,
      ),
      Hand.fill(_10doughShade),
    );
    canvas.drawPath(body, Hand.fill(_10dough));
    // One soft glossy squish highlight, upper-left.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-rx * 0.34, -ry * 0.40),
        width: rx * 0.5,
        height: ry * 0.32,
      ),
      Hand.fill(Colors.white.withValues(alpha: 0.38)),
    );
    canvas.drawPath(body, Hand.outline(_10ink, 5.5));

    // Face — placed low on the pillow (kawaii rule), eyes spaced wide.
    final eyeY = ry * 0.32;
    final eyeDx = rx * 0.34;
    final eyeR = rx * 0.14;
    if (f.blink > 0.5) {
      Hand.blinkEye(canvas, Offset(-eyeDx, eyeY), eyeR, _10inkSoft, width: 4.0);
      Hand.blinkEye(canvas, Offset(eyeDx, eyeY), eyeR, _10inkSoft, width: 4.0);
    } else {
      Hand.dotEye(canvas, Offset(-eyeDx, eyeY), eyeR, _10inkSoft);
      Hand.dotEye(canvas, Offset(eyeDx, eyeY), eyeR, _10inkSoft);
    }
    // Rosy cheeks — one soft dab each, sitting just below & outside the eyes.
    for (final s in const [-1.0, 1.0]) {
      Hand.blush(
        canvas,
        Offset(eyeDx * 1.5 * s, eyeY + eyeR * 1.9),
        rx * 0.16,
        _10blush,
        opacity: 0.5,
      );
    }
    // A small, gentle smile.
    Hand.smile(
      canvas,
      Offset(0, eyeY + eyeR * 2.4),
      rx * 0.26,
      rx * 0.14,
      _10inkSoft,
      width: 3.8,
    );

    canvas.restore();

    // Sakura-mochi leaf on top — sways gently with the idle sway.
    final headTop = baseCy - ry + f.bob * 0.3;
    _10drawLeaf(
      canvas,
      Offset(cx - rx * 0.16 + f.sway * 1.2, headTop + ry * 0.06),
      rx * 0.32,
    );

    // A couple of rice-powder sparkles twinkling in the air beside the mochi —
    // kept minimal so they read as sparkle, not scatter. Each pulses in size +
    // opacity on its own phase, and drifts with the sway, so the air feels alive.
    final sway = f.sway * 0.7;
    double tw(double phase) => 0.7 + 0.3 * math.sin(f.t * math.pi * 2 + phase);
    _10sparkleAt(canvas, Offset(cx + rx * 0.72 + sway, baseCy - ry * 0.58), 5.5,
        twinkle: tw(0.0));
    _10sparkleAt(canvas, Offset(cx - rx * 0.76 - sway, baseCy - ry * 0.36), 4.4,
        twinkle: tw(3.1));
  }

  // A wobbly superellipse (squircle) — the mochi pillow. exp < 1 squares the
  // corners; [squash] settles the bottom like soft dough.
  Path _10squircle(
    Offset center,
    double rx,
    double ry, {
    double exp = 0.62,
    double wobble = 3.0,
    int seed = 11,
    double squash = 0.0,
    int samples = 56,
  }) {
    final pts = <Offset>[];
    final span = samples * 0.3; // noise-domain length across one full loop
    for (var i = 0; i < samples; i++) {
      final a = (i / samples) * math.pi * 2;
      final ct = math.cos(a), st = math.sin(a);
      // Periodic value noise: cross-fade each raw sample with its wrapped
      // neighbour so the closed silhouette meets itself seamlessly — no kink
      // where the path closes (sample 0 and sample N now share one value).
      final u = i / samples;
      final n = (handNoise(i * 0.3, seed: seed) * (1 - u) +
              handNoise(i * 0.3 - span, seed: seed) * u) *
          wobble;
      var px = _10sgnPow(ct, exp) * (rx + n);
      var py = _10sgnPow(st, exp) * (ry + n);
      if (squash > 0 && py > 0) py *= (1 - squash * (py / ry));
      pts.add(center + Offset(px, py));
    }
    return _10smoothClosed(pts);
  }

  double _10sgnPow(double v, double p) =>
      (v < 0 ? -1.0 : 1.0) * math.pow(v.abs(), p).toDouble();

  Path _10smoothClosed(List<Offset> p) {
    final path = Path();
    if (p.isEmpty) return path;
    final n = p.length;
    final mid0 = (p[0] + p[n - 1]) / 2;
    path.moveTo(mid0.dx, mid0.dy);
    for (var i = 0; i < n; i++) {
      final cur = p[i];
      final next = p[(i + 1) % n];
      final mid = (cur + next) / 2;
      path.quadraticBezierTo(cur.dx, cur.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  void _10drawLeaf(Canvas canvas, Offset center, double s) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.35 + f.sway * 0.02);
    // Almond leaf: two mirrored arcs meeting at tip and base.
    final leaf = Path()
      ..moveTo(0, s * 0.5)
      ..quadraticBezierTo(s * 0.85, s * 0.05, 0, -s * 0.55)
      ..quadraticBezierTo(-s * 0.85, s * 0.05, 0, s * 0.5)
      ..close();
    canvas.drawPath(leaf, Hand.fill(_10leaf));
    canvas.drawPath(leaf, Hand.outline(_10leafInk, 3.2));
    // One confident center vein so it reads as a leaf — no scattered detail.
    final vein = Hand.roughLine(
      [Offset(0, s * 0.4), Offset(0, -s * 0.42)],
      wobble: 0.7,
      seed: 22,
    );
    canvas.drawPath(vein, Hand.outline(_10leafInk, 2.6));
    canvas.restore();
  }

  void _10sparkleAt(Canvas canvas, Offset at, double s, {double twinkle = 1.0}) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    final ss = s * twinkle; // pulse the size with the twinkle phase
    final i = ss * 0.28;
    final star = Path()
      ..moveTo(0, -ss)
      ..quadraticBezierTo(i, -i, ss, 0)
      ..quadraticBezierTo(i, i, 0, ss)
      ..quadraticBezierTo(-i, i, -ss, 0)
      ..quadraticBezierTo(-i, -i, 0, -ss)
      ..close();
    // ...and its opacity, so it reads as a real drifting glint.
    canvas.drawPath(
        star, Hand.fill(_10sparkle.withValues(alpha: 0.55 + 0.45 * twinkle)));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_P10 old) => old.f.t != f.t;
}
