// char_09_sprout — "새콩이" (Saekongi), the sprout bean.
//
// A plump pistachio-green bean with two little sprout leaves waving on a stem
// from the top of its head and warm soil-coloured cheeks. Drawn in the crayon
// hand of the family — thick warm-olive outline, low glossy dot eyes, a soft
// smile — with a silhouette you can read at a glance: a bean body crowned by a
// simple two-leaf seedling.
//
// Tuned for small sizes (reads clearly at 56px): the strongest shapes only —
// bean + two confident leaves + a friendly face. Fussy marks (soil crumbs,
// bean seam, leaf veins, extra sparkles) were dropped so nothing turns to mud
// when shrunk.
//
// Reactive face: the eyes / mouth / cheeks switch on [PetExpression] — happy
// ^_^, sleepy closed eyes + a drifting "zzz", eating a little 'o', excited
// wide eyes + a sparkle, curious up-look, focused calm — while the idle blink
// still pulses on top of any open-eyed look.
//
// Cuteness cues:
//   · plump rounded bean body in soft pastel green
//   · TWO leaves on a short stem from the top of the head (the 🌱 signature)
//   · big low-placed glossy dot eyes (kawaii rule)
//   · earthy soil-toned blush instead of pink (흙빛 볼)
//   · a soft ground shadow so it feels planted

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char09 extends PetCharacter {
  @override
  String get id => '09';
  @override
  String get name => '새콩이';
  @override
  String get concept => '흙에서 막 돋은 콩 — 통통한 연둣빛 몸, 머리 위 새싹 두 잎, 흙빛 볼.';
  @override
  String get signature => '숨 쉬며 통통 부풀고, 머리 위 새싹 두 잎이 바람에 살랑살랑, 가끔 깜빡.';
  @override
  List<String> get inspiration => const [
        'Redbubble — Kawaii Plant Sprout stickers (chibi, thick outline)',
        'Redbubble — Bean Sprout stickers (smol bean, blush face)',
        'Redbubble — Kawaii Bean stickers',
        'Stickers.cloud — bean sprout sticker pack',
        'Pinterest (momowynaut) — Bean Sprout kawaii board',
        'Pinterest — Sprout Drawing Cute ideas',
        'Pinterest — Cartoon Plant Sprout ideas',
        'Emojipedia — 🌱 Seedling emoji (two leaves from a brown earth mound)',
        'emojicombos — Sprout ("tiny green kawaii smol bean")',
        "Dandy's World — Sprout Seedly (leaves crowning a blobby toon)",
        'Among Us Wiki — Young Sprout (sprout on head)',
        'Pinterest — Blob Character Design ideas',
        'Shutterstock — Kawaii Blush (blush cheeks, thick outline)',
        'LINE Friends — Brown & Cony (rosy-cheeked soft minimal mascot family)',
      ];
  @override
  Color get accent => const Color(0xFF9CCB6A);

  @override
  Widget build(BuildContext context,
      {double? frozenT, PetExpression expression = PetExpression.neutral}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P09(f, expression),
        size: Size.infinite,
      ),
    );
  }
}

class _P09 extends CustomPainter {
  _P09(this.f, this.expr);
  final IdleFrame f;
  final PetExpression expr;

  // Warm, soft palette — nothing pure black.
  static const _bean = Color(0xFFC7E39C); // pistachio bean body
  static const _beanLight = Color(0xFFE4F3C8); // belly highlight
  static const _ink = Color(0xFF7C8A4E); // warm olive outline
  static const _inkSoft = Color(0xFF5E6A38); // face features
  static const _leaf = Color(0xFF9ECD68); // sprout leaves
  static const _leafDark = Color(0xFF6E9440); // leaf outline
  static const _stem = Color(0xFF89B857); // sprout stem
  static const _blush = Color(0xFFD79B72); // 흙빛 earthy-terracotta cheeks
  static const _mouth = Color(0xFFB4705A); // warm open-mouth interior
  static const _shadow = Color(0x14000000);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    final cx = w / 2;
    final baseCy = h * 0.60 + f.bob;
    final rx = w * 0.31; // body ~62% of the stage width
    final ry = w * 0.29 * f.breath; // height breathes

    // Soft ground shadow, pinned to the ground so the body bobs ABOVE it — the
    // shadow shrinks a touch as the bean lifts, which sells the little hop.
    final shadowScale = 1 + f.bob * 0.02;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.60 + ry * 1.04),
        width: rx * 1.7 * shadowScale,
        height: ry * 0.28 * shadowScale,
      ),
      Hand.fill(_shadow),
    );

    canvas.save();
    canvas.translate(cx, baseCy);
    // Gentle whole-body rock as it breathes, against the pinned shadow → weight.
    canvas.rotate(f.sway * 0.012);

    // --- Sprout: stem + two leaves, drawn first so the base tucks behind the
    //     body. Rotates about the head-top so the tips wave (the signature). ---
    canvas.save();
    canvas.translate(0, -ry * 0.94);
    canvas.rotate(f.sway * 0.05);
    _drawSprout(canvas, rx);
    canvas.restore();

    // --- Body: a plump wobbly bean, cream-green fill + soft thick outline. ---
    final body =
        Hand.blob(Offset.zero, rx, ry: ry, wobble: 3.0, seed: 12, squash: 0.16);
    canvas.drawPath(body, Hand.fill(_bean));
    // Belly highlight — a single soft lighter blob up-left, inside the body.
    // One confident shape reads better small than layered shading.
    final belly = Hand.blob(
      Offset(-rx * 0.20, -ry * 0.18),
      rx * 0.50,
      ry: ry * 0.48,
      wobble: 2.0,
      seed: 21,
    );
    canvas.drawPath(belly, Hand.fill(_beanLight.withValues(alpha: 0.85)));
    canvas.drawPath(body, Hand.outline(_ink, 5.5));

    // --- Face — low on the body (kawaii rule), reacting to [expr]. ---
    _09Face(canvas, rx, ry);

    canvas.restore();

    // Faint paper grain overlay for texture.
    Hand.paperGrain(canvas, Offset.zero & size, seed: 9, dots: 60);
  }

  /// Stem rising from the origin (head-top) that forks into two sprout leaves.
  void _drawSprout(Canvas canvas, double rx) {
    // Stem stretches a touch with the body breath so the sprout 'breathes'.
    final stemTop = Offset(0, -rx * 0.62 * f.breath);
    final stem = Hand.roughLine(
      [const Offset(0, 0), Offset(rx * 0.03, stemTop.dy * 0.52), stemTop],
      wobble: 1.0,
      seed: 41,
    );
    canvas.drawPath(stem, Hand.outline(_stem, 6.0));

    // Two leaves branching from the top of the stem — each rotates about
    // stemTop with an independent, counter-phased flutter so the fork waves as
    // two leaves, not one rigid crown.
    canvas.save();
    canvas.translate(stemTop.dx, stemTop.dy);
    canvas.rotate(-f.sway * 0.02);
    canvas.translate(-stemTop.dx, -stemTop.dy);
    _leafAt(canvas, stemTop, Offset(-rx * 0.60, -rx * 0.50), rx * 0.38,
        seed: 47); // left, larger
    canvas.restore();

    canvas.save();
    canvas.translate(stemTop.dx, stemTop.dy);
    canvas.rotate(f.sway * 0.02);
    canvas.translate(-stemTop.dx, -stemTop.dy);
    _leafAt(canvas, stemTop, Offset(rx * 0.52, -rx * 0.44), rx * 0.33,
        seed: 58); // right, smaller
    canvas.restore();
  }

  /// A single rounded leaf: base at [base], tip at base+[dir], half-width [wid].
  /// A confident filled blade with a soft outline — no vein (it only muddies at
  /// small sizes), just a little hand jitter so it reads pen-drawn.
  void _leafAt(Canvas canvas, Offset base, Offset dir, double wid,
      {int seed = 51}) {
    final tip0 = base + dir;
    final mid = base + dir * 0.5;
    final len = dir.distance;
    // Unit perpendicular to the leaf axis → controls the belly of each side.
    final perp = Offset(-dir.dy, dir.dx) / (len == 0 ? 1.0 : len);
    final j = wid * 0.14;
    final c1 = mid + perp * (wid + handNoise(1.3, seed: seed) * j);
    final c2 = mid - perp * (wid + handNoise(4.4, seed: seed) * j);
    final tip = tip0 +
        Offset(handNoise(8.5, seed: seed), handNoise(9.1, seed: seed)) *
            (j * 0.6);

    final leaf = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(c1.dx, c1.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, base.dx, base.dy)
      ..close();
    canvas.drawPath(leaf, Hand.fill(_leaf));
    canvas.drawPath(leaf, Hand.outline(_leafDark, 3.2));
  }

  /// The face — a few confident shapes that read at 56px, switching on [expr].
  /// The idle blink pulse still fires on top of any open-eyed look, so the pet
  /// keeps blinking whatever mood it's in.
  void _09Face(Canvas canvas, double rx, double ry) {
    final baseEyeY = ry * 0.32;
    final eyeDx = rx * 0.36;
    final eyeR = rx * 0.18; // bold round baby eyes that survive shrinking

    // Curious looks up a touch, with a hair of head-tilt feel (eyes offset up).
    final lookUp = expr == PetExpression.curious ? eyeR * 0.55 : 0.0;
    final tilt = expr == PetExpression.curious ? eyeR * 0.12 : 0.0;
    final eyeY = baseEyeY - lookUp;
    final lEye = Offset(-eyeDx, eyeY - tilt);
    final rEye = Offset(eyeDx, eyeY + tilt);

    final blinking = f.blink > 0.5;

    // --- Eyes ---------------------------------------------------------------
    if (blinking || expr.eyesClosed) {
      // Idle blink pulse OR a sleeping face → gentle closed arcs.
      Hand.blinkEye(canvas, lEye, eyeR, _inkSoft, width: 3.8);
      Hand.blinkEye(canvas, rEye, eyeR, _inkSoft, width: 3.8);
    } else if (expr == PetExpression.happy) {
      // ^_^ — blinkEye flipped into an upward happy squint.
      _09HappyEye(canvas, lEye, eyeR, _inkSoft);
      _09HappyEye(canvas, rEye, eyeR, _inkSoft);
    } else if (expr == PetExpression.focused) {
      // Calm narrowed eyes — short level lines.
      _09NarrowEye(canvas, lEye, eyeR, _inkSoft);
      _09NarrowEye(canvas, rEye, eyeR, _inkSoft);
    } else {
      // Open glossy dot eyes — neutral / eating / curious / excited.
      final er = expr == PetExpression.excited ? eyeR * 1.14 : eyeR;
      Hand.dotEye(canvas, lEye, er, _inkSoft);
      Hand.dotEye(canvas, rEye, er, _inkSoft);
      if (expr == PetExpression.excited) {
        // A tiny glint up-right of the eyes.
        _09Sparkle(canvas, Offset(eyeDx * 1.42, eyeY - eyeR * 2.3), rx * 0.11);
      }
    }

    // --- Cheeks — earthy soil-toned blush; fuller/brighter for some moods. --
    var blushR = rx * 0.15;
    var blushOp = 0.6;
    if (expr.eyesHappy) {
      // happy / excited → slightly stronger blush.
      blushR = rx * 0.16;
      blushOp = 0.72;
    } else if (expr == PetExpression.eating) {
      // Fuller cheeks while munching.
      blushR = rx * 0.20;
      blushOp = 0.7;
    }
    final cheekY = baseEyeY + eyeR * 1.5;
    Hand.blush(canvas, Offset(-eyeDx * 1.16, cheekY), blushR, _blush,
        opacity: blushOp);
    Hand.blush(canvas, Offset(eyeDx * 1.16, cheekY), blushR, _blush,
        opacity: blushOp);

    // --- Mouth --------------------------------------------------------------
    final mouthAt = Offset(0, baseEyeY + eyeR * 2.1);
    switch (expr) {
      case PetExpression.eating:
        // Small open round 'o' — a warm little munch.
        final mr = rx * 0.10;
        canvas.drawCircle(mouthAt, mr, Hand.fill(_mouth));
        canvas.drawCircle(mouthAt, mr, Hand.outline(_inkSoft, 3.0));
        break;
      case PetExpression.excited:
        // Open happy smile.
        _09OpenSmile(canvas, mouthAt, rx * 0.34, rx * 0.22);
        break;
      case PetExpression.happy:
        // A bigger grin.
        Hand.smile(canvas, mouthAt, rx * 0.34, rx * 0.20, _inkSoft, width: 3.6);
        break;
      case PetExpression.sleepy:
        // A tiny sleepy mouth.
        Hand.smile(canvas, mouthAt, rx * 0.13, rx * 0.06, _inkSoft, width: 3.0);
        break;
      case PetExpression.focused:
        // A small set mouth — a short level line.
        canvas.drawLine(mouthAt - Offset(rx * 0.09, 0),
            mouthAt + Offset(rx * 0.09, 0), Hand.outline(_inkSoft, 3.2));
        break;
      case PetExpression.curious:
        // A gentle, near-neutral little smile.
        Hand.smile(canvas, mouthAt, rx * 0.22, rx * 0.11, _inkSoft, width: 3.2);
        break;
      case PetExpression.neutral:
        // The warm default grin.
        Hand.smile(canvas, mouthAt, rx * 0.26, rx * 0.15, _inkSoft, width: 3.4);
        break;
    }

    // --- Sleepy 'zzz' drifting off the head, bobbing with the idle loop -----
    if (expr == PetExpression.sleepy) {
      _09Zzz(canvas, Offset(eyeDx * 1.5, -ry * 0.72), rx * 0.16);
    }
  }

  /// Happy ^_^ eye — an upward dome arc (Hand.blinkEye flipped vertically).
  void _09HappyEye(Canvas c, Offset at, double r, Color ink,
      {double width = 3.8}) {
    final rect = Rect.fromCircle(center: at, radius: r);
    c.drawArc(
        rect, math.pi * 1.15, math.pi * 0.7, false, Hand.outline(ink, width));
  }

  /// Calm narrowed eye — a short level line (focused look).
  void _09NarrowEye(Canvas c, Offset at, double r, Color ink,
      {double width = 3.8}) {
    c.drawLine(at - Offset(r * 0.72, 0), at + Offset(r * 0.72, 0),
        Hand.outline(ink, width));
  }

  /// A tiny warm sparkle glint — a soft plus (excited look).
  void _09Sparkle(Canvas c, Offset at, double s) {
    final p = Hand.outline(const Color(0xFFF4B740), math.max(2.0, s * 0.34));
    c.drawLine(at - Offset(s, 0), at + Offset(s, 0), p);
    c.drawLine(at - Offset(0, s), at + Offset(0, s), p);
  }

  /// An open happy smile — a filled arc mouth (excited look).
  void _09OpenSmile(Canvas c, Offset at, double w, double depth) {
    final path = Path()
      ..moveTo(at.dx - w / 2, at.dy)
      ..quadraticBezierTo(at.dx, at.dy + depth, at.dx + w / 2, at.dy)
      ..close();
    c.drawPath(path, Hand.fill(_mouth));
    c.drawPath(path, Hand.outline(_inkSoft, 3.4));
  }

  /// Three little 'z's drifting up off the head, bobbing with the idle phase.
  void _09Zzz(Canvas c, Offset at, double s) {
    const steps = <List<double>>[
      [0.0, 0.0, 0.95],
      [0.9, -1.0, 1.2],
      [2.0, -2.3, 1.5],
    ];
    for (final z in steps) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            color: _inkSoft.withValues(alpha: 0.78),
            fontSize: s * z[2],
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Gentle per-letter bob so the little zzz breathes with the idle loop.
      final bob = math.sin((f.t + z[0] * 0.2) * math.pi * 2) * s * 0.18;
      final pos = at +
          Offset(z[0] * s * 0.7, z[1] * s + bob) -
          Offset(tp.width / 2, tp.height / 2);
      tp.paint(c, pos);
    }
  }

  @override
  bool shouldRepaint(_P09 old) => old.f.t != f.t || old.expr != expr;
}
