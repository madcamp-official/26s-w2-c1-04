// char_03_bear — "고미" (Gomi), a tiny honey bear cub.
//
// A chubby crayon-drawn baby bear: a body a touch wider than tall, two round
// ears perked on top, a cream muzzle with a soft dark nose, low dot eyes and
// warm pink cheeks — the cozy "Hamster Talk / Rilakkuma / LINE Brown" blush
// mascot family, redrawn as a honey cub. Built entirely on the charlab
// toolkit so it shares the same hand and idle breath as the other pets.
//
// References studied (STEP 1, 12+):
//   · Rilakkuma & Korilakkuma (San-X) — relaxed round body, tiny dark dot eyes,
//     short cream muzzle, low-placed features.
//   · Brown / LINE Friends — minimal face, two tiny round ears, stub silhouette.
//   · Gloomy Bear (Mori Chack) — big bright round eyes, pastel fur.
//   · Care Bears (Elena Kucharik) — round belly, small round ears, tummy accent.
//   · Cinnamoroll bear-costume plush (Sanrio) — pink cheeks, chubby proportions.
//   · Pusheen / We Bare Bears — simple dot eyes, small mouth, big head:body.
//   · iStock / Dreamstime "chubby baby bear" doodles — pink cheeks, black nose.
//   · Etsy / Vecteezy "kawaii bear stickers" — thick warm outline, dot eyes+nose.
//   · Super Cute Kawaii bear roundup — round semicircle ears + blush.
//   · Teddy-bear how-to-draw tutorials — muzzle oval + nose + philtrum + smile.
// Recurring cuteness cues extracted: round semicircle ears on top (the #1 bear
// read), chubby body wider than tall, features placed LOW, small glossy dot
// eyes set close, cream muzzle patch with a rounded dark nose, pink oval blush.
//
// Tuned to read at ~56px (picker thumbnail): only bold, confident shapes are
// kept — no scattered fur nicks, internal shading, paper grain, orbiting bee
// or honey pot. The face reacts to [PetExpression].

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char03 extends PetCharacter {
  @override
  String get id => '03';
  @override
  String get name => '고미';
  @override
  String get concept =>
      '크레용으로 그린 통통한 아기 꿀곰 — 둥근 두 귀, 크림빛 주둥이와 배 무늬, 낮게 앉은 반짝 점 눈과 발그레한 볼.';
  @override
  String get signature =>
      '오른 귀를 살짝 갸웃 기울인 채 숨 쉴 때 몸이 부풀고, 두 귀가 번갈아 살랑이며 앞발이 살랑인다 — 기분에 따라 눈과 입이 바뀐다.';
  @override
  List<String> get inspiration => const [
        'Rilakkuma & Korilakkuma (San-X)',
        'Brown / LINE Friends',
        'Gloomy Bear (Mori Chack)',
        'Care Bears (Elena Kucharik)',
        'Cinnamoroll bear-costume plush (Sanrio)',
        'Pusheen chubby proportions',
        'We Bare Bears simple faces',
        'iStock / Dreamstime chubby baby bear doodles',
        'Etsy / Vecteezy kawaii bear stickers (thick outline, dot nose)',
        'Super Cute Kawaii — Kawaii Bears roundup',
        'teddy-bear how-to-draw muzzle + nose + philtrum',
        'kawaii chibi bear blush mascots',
      ];
  @override
  Color get accent => const Color(0xFFE7B482);

  @override
  Widget build(BuildContext context,
      {double? frozenT, PetExpression expression = PetExpression.neutral}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P03(f, expression),
        size: Size.infinite,
      ),
    );
  }
}

class _P03 extends CustomPainter {
  _P03(this.f, this.expr);
  final IdleFrame f;
  final PetExpression expr;

  // Warm honey palette — never pure black.
  static const _fur = Color(0xFFE7B482); // honey tan body
  static const _cream = Color(0xFFF8E7CC); // muzzle / inner ear / paws
  static const _ink = Color(0xFF9C6B44); // warm brown outline
  static const _inkSoft = Color(0xFF5A3A22); // eyes / mouth ink
  static const _nose = Color(0xFF6E4526); // rounded nose
  static const _mouth = Color(0xFF7A4A2E); // open-mouth interior
  static const _innerEar = Color(0xFFEFC4B4); // soft warm-pink ear
  static const _blush = Color(0xFFF4AEA0); // warm rosy-peach cheeks

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    final cx = w / 2;
    final baseCy = h * 0.58 + f.bob;
    final rx = w * 0.31; // body ~62% of the stage — chubby, wider than tall
    final ry = w * 0.255 * f.breath;

    // --- Soft ground shadow (world space, under the body) -------------------
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseCy + ry * 1.02),
        width: rx * 1.7,
        height: ry * 0.26,
      ),
      Hand.fill(const Color(0x14000000)),
    );

    canvas.save();
    canvas.translate(cx, baseCy);
    canvas.rotate(f.sway * 0.007); // gentle head-wobble with the sway

    // --- Ears (behind the head so the body overlaps their base) -------------
    // An alternating "쫑긋" wiggle: one ear rises as the other settles. Two
    // round bumps break the top contour — the #1 bear read.
    final earBaseY = -ry * 0.86;
    final earDx = rx * 0.58;
    _ear(canvas, Offset(-earDx - f.sway * 0.35, earBaseY + f.sway * 0.45), rx * 0.46, -1);
    _ear(canvas, Offset(earDx + f.sway * 0.35, earBaseY - f.sway * 0.45), rx * 0.46, 1);

    // --- Little arm nubs (poke out at the sides) ----------------------------
    _paw(canvas, Offset(-rx * 0.88, ry * 0.34 - f.sway * 0.25), rx * 0.19);
    _paw(canvas, Offset(rx * 0.88, ry * 0.34 + f.sway * 0.25), rx * 0.19);

    // --- Body — chubby wobbly blob ------------------------------------------
    final body = Hand.blob(Offset.zero, rx, ry: ry, wobble: 3.0, seed: 8, squash: 0.08);
    canvas.drawPath(body, Hand.fill(_fur));
    canvas.drawPath(body, Hand.outline(_ink, 5.5));

    // --- Cream tummy crescent — Gomi's signature belly mark ------------------
    final tummy =
        Hand.blob(Offset(0, ry * 0.52), rx * 0.30, ry: ry * 0.22, wobble: 1.6, seed: 27);
    canvas.drawPath(tummy, Hand.fill(_cream));
    canvas.drawPath(tummy, Hand.outline(_ink, 2.4));

    // --- Feet — two rounded pads at the very bottom, in front ----------------
    _foot(canvas, Offset(-rx * 0.36, ry * 0.90), rx * 0.20, ry * 0.15);
    _foot(canvas, Offset(rx * 0.36, ry * 0.90), rx * 0.20, ry * 0.15);

    // --- Muzzle patch (cream), low-center -----------------------------------
    final muzzle =
        Hand.blob(Offset(0, ry * 0.30), rx * 0.44, ry: ry * 0.30, wobble: 1.8, seed: 21);
    canvas.drawPath(muzzle, Hand.fill(_cream));
    canvas.drawPath(muzzle, Hand.outline(_ink, 2.6));

    // --- Nose — one confident rounded shape on the muzzle -------------------
    final noseC = Offset(0, ry * 0.10);
    final noseR = rx * 0.13;
    final nose = Hand.blob(noseC, noseR, ry: noseR * 0.78, wobble: 1.0, seed: 33);
    canvas.drawPath(nose, Hand.fill(_nose));
    canvas.drawPath(nose, Hand.outline(_inkSoft, 2.0));

    // --- Face — blush + eyes + mouth, reacting to the expression -------------
    _face(canvas, rx, ry);

    canvas.restore();
  }

  /// Draws the reactive face: cheeks, eyes and mouth per [expr], plus the
  /// blink pulse and small extras (sleepy zzz, excited glint).
  void _face(Canvas canvas, double rx, double ry) {
    // -- Cheeks: fuller / brighter for happy · excited · eating --------------
    var blushR = rx * 0.185;
    var blushO = 0.45;
    if (expr == PetExpression.happy || expr == PetExpression.excited) {
      blushO = 0.6;
    } else if (expr == PetExpression.eating) {
      blushR = rx * 0.23; // fuller cheeks
      blushO = 0.55;
    }
    Hand.blush(canvas, Offset(-rx * 0.56, ry * 0.16), blushR, _blush, opacity: blushO);
    Hand.blush(canvas, Offset(rx * 0.56, ry * 0.16), blushR, _blush, opacity: blushO);

    // -- Eyes ---------------------------------------------------------------
    final eyeY = ry * 0.01;
    final eyeDx = rx * 0.30;
    final eyeR = rx * 0.15;
    // Curious looks up a touch → a small head-tilt feel.
    final look = expr == PetExpression.curious ? -ry * 0.07 : 0.0;
    final le = Offset(-eyeDx, eyeY + look);
    final re = Offset(eyeDx, eyeY + look);

    if (f.blink > 0.5 || expr.eyesClosed) {
      // Blink pulse (rides on top of any expression) or a sleepy shut eye.
      Hand.blinkEye(canvas, le, eyeR, _inkSoft, width: 3.6);
      Hand.blinkEye(canvas, re, eyeR, _inkSoft, width: 3.6);
    } else if (expr == PetExpression.happy) {
      // ^_^ — smile-style upward arcs for eyes.
      Hand.smile(canvas, le, eyeR * 1.7, eyeR * 0.95, _inkSoft, width: 3.4);
      Hand.smile(canvas, re, eyeR * 1.7, eyeR * 0.95, _inkSoft, width: 3.4);
    } else {
      // Open glossy dot eyes; excited widens, focused narrows.
      var r = eyeR;
      if (expr == PetExpression.excited) r = eyeR * 1.16;
      if (expr == PetExpression.focused) r = eyeR * 0.66;
      Hand.dotEye(canvas, le, r, _inkSoft);
      Hand.dotEye(canvas, re, r, _inkSoft);
      if (expr == PetExpression.excited) {
        _glint(canvas, re + Offset(eyeR * 1.25, -eyeR * 1.35), eyeR * 0.55);
      }
    }

    // -- Mouth --------------------------------------------------------------
    final mouthC = Offset(0, ry * 0.31);
    if (expr.mouthOpen) {
      // Eating → small round 'o'; excited → wider open grin.
      final mw = expr == PetExpression.excited ? rx * 0.26 : rx * 0.17;
      final mh = expr == PetExpression.excited ? rx * 0.20 : rx * 0.17;
      final rect = Rect.fromCenter(center: mouthC, width: mw, height: mh);
      canvas.drawOval(rect, Hand.fill(_mouth));
      canvas.drawOval(rect, Hand.outline(_inkSoft, 2.2));
    } else if (expr == PetExpression.focused) {
      // A small, calm, set mouth — a short horizontal line.
      final line = Hand.roughLine(
        [mouthC + Offset(-rx * 0.09, 0), mouthC + Offset(rx * 0.09, 0)],
        wobble: 0.4,
        seed: 44,
      );
      canvas.drawPath(line, Hand.outline(_inkSoft, 2.6));
    } else {
      // Gentle smile; bigger for happy, tiny for sleepy.
      final happy = expr == PetExpression.happy;
      final sleepy = expr == PetExpression.sleepy;
      final sw = sleepy ? rx * 0.22 : (happy ? rx * 0.52 : rx * 0.42);
      final sd = sleepy ? rx * 0.07 : (happy ? rx * 0.18 : rx * 0.14);
      Hand.smile(canvas, mouthC, sw, sd, _inkSoft, width: 2.8);
    }

    // -- Sleepy zzz, drifting near the head ---------------------------------
    if (expr == PetExpression.sleepy) {
      _zzz(canvas, Offset(rx * 0.60, -ry * 1.00), rx * 0.17);
    }
  }

  /// A round bear ear: outer fur blob + inner warm-pink patch.
  /// [side] is -1 (left) or 1 (right); the right ear cocks at a jaunty tilt.
  void _ear(Canvas canvas, Offset center, double r, int side) {
    final tilted = side > 0;
    if (tilted) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(0.16);
      canvas.translate(-center.dx, -center.dy);
    }
    final outer = Hand.blob(center, r, ry: r * 0.92, wobble: 1.6, seed: 51 + side);
    canvas.drawPath(outer, Hand.fill(_fur));
    canvas.drawPath(outer, Hand.outline(_ink, 5.0));
    final innerC = center + Offset(side * r * 0.10, r * 0.10);
    final inner = Hand.blob(innerC, r * 0.52, ry: r * 0.50, wobble: 1.0, seed: 61 + side);
    canvas.drawPath(inner, Hand.fill(_innerEar));
    if (tilted) canvas.restore();
  }

  /// A small fur arm nub resting against the body.
  void _paw(Canvas canvas, Offset center, double r) {
    final paw = Hand.blob(center, r, ry: r * 1.1, wobble: 1.4, seed: 71);
    canvas.drawPath(paw, Hand.fill(_fur));
    canvas.drawPath(paw, Hand.outline(_ink, 4.4));
  }

  /// A rounded cream foot pad at the base of the body.
  void _foot(Canvas canvas, Offset center, double fx, double fy) {
    final foot = Hand.blob(center, fx, ry: fy, wobble: 1.4, seed: 81);
    canvas.drawPath(foot, Hand.fill(_cream));
    canvas.drawPath(foot, Hand.outline(_ink, 4.0));
  }

  /// A tiny 4-point sparkle glint (for the excited eyes).
  void _glint(Canvas canvas, Offset c, double r) {
    final p = Hand.outline(Colors.white.withValues(alpha: 0.95), 2.0);
    canvas.drawLine(c + Offset(0, -r), c + Offset(0, r), p);
    canvas.drawLine(c + Offset(-r, 0), c + Offset(r, 0), p);
    final p2 = Hand.outline(Colors.white.withValues(alpha: 0.65), 1.4);
    canvas.drawLine(c + Offset(-r * 0.6, -r * 0.6), c + Offset(r * 0.6, r * 0.6), p2);
    canvas.drawLine(c + Offset(r * 0.6, -r * 0.6), c + Offset(-r * 0.6, r * 0.6), p2);
  }

  /// A small drifting "z z z" that bobs with the idle loop.
  void _zzz(Canvas canvas, Offset at, double fontSize) {
    final drift = math.sin(f.t * math.pi * 2) * fontSize * 0.22;
    final bob = math.cos(f.t * math.pi * 2) * fontSize * 0.18;
    final tp = TextPainter(
      text: TextSpan(
        text: 'z z z',
        style: TextStyle(
          color: _inkSoft.withValues(alpha: 0.72),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(at.dx + drift, at.dy + bob);
    canvas.rotate(-0.12);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_P03 old) => old.f.t != f.t || old.expr != expr;
}
