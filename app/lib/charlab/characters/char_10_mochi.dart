// char_10_mochi — "말랑이" (Mallangi), the squishy rice-cake blob.
//
// A soft mochi (떡) pillow: a wobbly rounded-square silhouette — wider than
// tall, settled at the bottom the way a warm rice cake slumps — with a warm
// crayon outline, two low glossy dot eyes, rosy cheeks, a tiny smile, two
// stubby feet, and a little green sakura-mochi leaf perched on top. Its idle
// move is a squash-and-stretch *jiggle* (mallang = 말랑, "squishy"), area-
// conserving so it reads as a bouncy rice cake rather than a breathing balloon.
// Its face reacts to the pet's mood (PetExpression): happy ^_^, sleepy zzz, an
// eating "o", an excited sparkle — small changes that read big even at 56px.
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
  String get signature =>
      '숨 대신 몸이 통통 눌렸다 늘어나는 떡 젤리 저글(squash-and-stretch), 잎사귀는 살랑, 기분(PetExpression)에 따라 눈·입이 바뀐다.';
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
  Widget build(BuildContext context,
      {double? frozenT, PetExpression expression = PetExpression.neutral}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P10(f, expression),
        size: Size.infinite,
      ),
    );
  }
}

class _P10 extends CustomPainter {
  _P10(this.f, this.expr);
  final IdleFrame f;
  final PetExpression expr;

  // Warm, soft palette — a faintly pink rice-cake cream, never pure white/black.
  static const _10dough = Color(0xFFFDF2EE); // mochi cream (hint of pink)
  static const _10doughShade = Color(0xFFF3DDD5); // underside settle
  static const _10ink = Color(0xFF9E8468); // warm brown outline
  static const _10inkSoft = Color(0xFF6E5C48); // eyes / smile
  static const _10blush = Color(0xFFF29AA0); // warm coral-rose cheek
  static const _10leaf = Color(0xFFA9CE8E); // sakura-mochi leaf
  static const _10leafInk = Color(0xFF7FA968);
  static const _10mouth = Color(0xFFE0929A); // soft warm mouth interior
  static const _10glintC = Color(0xFFF4B740); // excited sparkle glint (gold)

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

    // Face — placed low on the pillow (kawaii rule), reacting to [expr].
    final sleepy = expr == PetExpression.sleepy;
    final happy = expr == PetExpression.happy;
    final excited = expr == PetExpression.excited;
    final eating = expr == PetExpression.eating;
    final curious = expr == PetExpression.curious;
    final focused = expr == PetExpression.focused;

    final baseEyeY = ry * 0.32;
    final eyeDx = rx * 0.34;
    final eyeR = rx * 0.14;
    // Curious looks up a touch — a small head-tilt feel via raised eyes.
    final eyeY = curious ? baseEyeY - eyeR * 0.7 : baseEyeY;

    // Eyes. Blink pulse wins over any open-eyed expression; sleepy stays shut.
    if (f.blink > 0.5 || expr.eyesClosed) {
      Hand.blinkEye(canvas, Offset(-eyeDx, eyeY), eyeR, _10inkSoft, width: 4.0);
      Hand.blinkEye(canvas, Offset(eyeDx, eyeY), eyeR, _10inkSoft, width: 4.0);
    } else if (happy) {
      // Joyful ^_^ squint.
      _10happyEye(canvas, Offset(-eyeDx, eyeY), eyeR);
      _10happyEye(canvas, Offset(eyeDx, eyeY), eyeR);
    } else if (focused) {
      // Narrowed, calm eyes — short horizontal strokes.
      for (final s in const [-1.0, 1.0]) {
        canvas.drawLine(
          Offset(s * eyeDx - eyeR * 0.62, eyeY),
          Offset(s * eyeDx + eyeR * 0.62, eyeY),
          Hand.outline(_10inkSoft, 4.0),
        );
      }
    } else {
      // Open glossy dot eyes — excited opens them wide + adds a glint.
      final r = excited ? eyeR * 1.24 : eyeR;
      Hand.dotEye(canvas, Offset(-eyeDx, eyeY), r, _10inkSoft);
      Hand.dotEye(canvas, Offset(eyeDx, eyeY), r, _10inkSoft);
      if (excited) {
        _10glint(canvas, Offset(eyeDx + r * 1.35, eyeY - r * 1.2), rx * 0.11);
      }
    }

    // Rosy cheeks — fuller for eating, brighter for happy/excited.
    final brightBlush = expr.eyesHappy;
    final blushR = eating ? rx * 0.20 : (brightBlush ? rx * 0.185 : rx * 0.16);
    final blushOp = brightBlush ? 0.62 : (eating ? 0.58 : 0.5);
    for (final s in const [-1.0, 1.0]) {
      Hand.blush(
        canvas,
        Offset(eyeDx * 1.5 * s, baseEyeY + eyeR * 1.9),
        blushR,
        _10blush,
        opacity: blushOp,
      );
    }

    // Mouth — changes with the mood.
    final mouthAt = Offset(0, baseEyeY + eyeR * 2.4);
    if (expr.mouthOpen) {
      if (eating) {
        // A small open round "o".
        canvas.drawCircle(mouthAt, rx * 0.09, Hand.fill(_10mouth));
        canvas.drawCircle(mouthAt, rx * 0.09, Hand.outline(_10inkSoft, 3.2));
      } else {
        // Excited — a big open happy grin.
        _10openMouth(canvas, mouthAt, rx * 0.30, rx * 0.22);
      }
    } else if (happy) {
      Hand.smile(canvas, mouthAt, rx * 0.34, rx * 0.20, _10inkSoft, width: 4.0);
    } else if (sleepy) {
      Hand.smile(canvas, mouthAt, rx * 0.12, rx * 0.055, _10inkSoft,
          width: 3.4);
    } else if (focused) {
      // A small, set mouth.
      Hand.smile(canvas, mouthAt, rx * 0.15, rx * 0.03, _10inkSoft, width: 3.6);
    } else {
      // neutral / curious — the gentle default smile.
      Hand.smile(canvas, mouthAt, rx * 0.26, rx * 0.14, _10inkSoft, width: 3.8);
    }

    // Sleepy drifts a little "zzz" up beside its head, bobbing with the loop.
    if (sleepy) {
      _10zzz(canvas, Offset(rx * 0.5, -ry * 0.92), rx * 0.22);
    }

    canvas.restore();

    // Sakura-mochi leaf on top — sways gently with the idle sway.
    final headTop = baseCy - ry + f.bob * 0.3;
    _10drawLeaf(
      canvas,
      Offset(cx - rx * 0.16 + f.sway * 1.2, headTop + ry * 0.06),
      rx * 0.32,
    );
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
    canvas.restore();
  }

  // An upward arch ⌒ eye — the joyful ^_^ squint.
  void _10happyEye(Canvas c, Offset at, double r) {
    final path = Path()
      ..moveTo(at.dx - r, at.dy + r * 0.34)
      ..quadraticBezierTo(at.dx, at.dy - r * 0.72, at.dx + r, at.dy + r * 0.34);
    c.drawPath(path, Hand.outline(_10inkSoft, 4.2));
  }

  // A big open happy grin — a filled downward arc closed along the top.
  void _10openMouth(Canvas c, Offset at, double w, double depth) {
    final path = Path()
      ..moveTo(at.dx - w / 2, at.dy)
      ..quadraticBezierTo(at.dx, at.dy + depth * 1.4, at.dx + w / 2, at.dy)
      ..close();
    c.drawPath(path, Hand.fill(_10mouth));
    c.drawPath(path, Hand.outline(_10inkSoft, 3.6));
  }

  // A tiny 4-point star glint for the excited sparkle.
  void _10glint(Canvas c, Offset at, double s) {
    final star = Path()
      ..moveTo(at.dx, at.dy - s)
      ..quadraticBezierTo(at.dx + s * 0.22, at.dy - s * 0.22, at.dx + s, at.dy)
      ..quadraticBezierTo(at.dx + s * 0.22, at.dy + s * 0.22, at.dx, at.dy + s)
      ..quadraticBezierTo(at.dx - s * 0.22, at.dy + s * 0.22, at.dx - s, at.dy)
      ..quadraticBezierTo(at.dx - s * 0.22, at.dy - s * 0.22, at.dx, at.dy - s)
      ..close();
    c.drawPath(star, Hand.fill(_10glintC));
  }

  // A small drifting "zzz" for the sleepy face — bobs up with the idle loop.
  void _10zzz(Canvas canvas, Offset base, double s) {
    final rise = math.sin(f.t * math.pi * 2) * 0.5 + 0.5; // 0..1 drift
    for (var i = 0; i < 3; i++) {
      final fs = s * (0.62 + i * 0.28);
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            color: _10inkSoft.withValues(alpha: 0.85),
            fontSize: fs,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = base.dx + i * s * 0.52;
      final dy = base.dy - i * s * 0.6 - rise * s * 0.45;
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(_P10 old) => old.f.t != f.t || old.expr != expr;
}
