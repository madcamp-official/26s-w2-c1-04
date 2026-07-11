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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char03 extends PetCharacter {
  @override
  String get id => '03';
  @override
  String get name => '고미';
  @override
  String get concept => '크레용으로 그린 통통한 아기 꿀곰 — 둥근 두 귀, 크림빛 주둥이와 배 무늬, 낮게 앉은 점 눈과 발그레한 볼, 발치엔 작은 꿀단지.';
  @override
  String get signature => '오른 귀를 살짝 갸웃 기울인 채 숨 쉴 때 몸이 부풀고, 두 귀가 번갈아 살랑이며 앞발이 살랑, 발 옆 꿀단지엔 작은 벌이 맴돈다.';
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
  Widget build(BuildContext context, {double? frozenT}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P03(f),
        size: Size.infinite,
      ),
    );
  }
}

class _P03 extends CustomPainter {
  _P03(this.f);
  final IdleFrame f;

  // Warm honey palette — never pure black.
  static const _fur = Color(0xFFE7B482); // honey tan body
  static const _cream = Color(0xFFF8E7CC); // muzzle / inner ear / paws
  static const _ink = Color(0xFF9C6B44); // warm brown outline
  static const _inkSoft = Color(0xFF5A3A22); // eyes / mouth ink
  static const _nose = Color(0xFF6E4526); // rounded nose
  static const _innerEar = Color(0xFFEFC4B4); // soft warm-pink ear
  static const _blush = Color(0xFFF4AEA0); // warm rosy-peach cheeks (harmonized)

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    final cx = w / 2;
    final baseCy = h * 0.58 + f.bob;
    final rx = w * 0.31; // chubby: a touch wider than tall (distinct from egg)
    final ry = w * 0.255 * f.breath;

    // Soft ground shadow (world space, under the body).
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
    // An alternating "쫑긋" wiggle: one ear rises as the other settles.
    // QA-Silhouette: ears ride higher on the crown and a touch larger so the
    // two round bumps clearly break the top contour (the #1 bear read).
    final earBaseY = -ry * 0.86;
    final earDx = rx * 0.58;
    _ear(canvas, Offset(-earDx - f.sway * 0.35, earBaseY + f.sway * 0.45), rx * 0.46, -1);
    _ear(canvas, Offset(earDx + f.sway * 0.35, earBaseY - f.sway * 0.45), rx * 0.46, 1);

    // --- Little arm nubs (poke out at the sides, body drawn over inner part) -
    _paw(canvas, Offset(-rx * 0.88, ry * 0.34 - f.sway * 0.25), rx * 0.19);
    _paw(canvas, Offset(rx * 0.88, ry * 0.34 + f.sway * 0.25), rx * 0.19);

    // --- Body — chubby wobbly blob -----------------------------------------
    final body = Hand.blob(Offset.zero, rx, ry: ry, wobble: 3.0, seed: 8, squash: 0.08);
    canvas.drawPath(body, Hand.fill(_fur));

    // QA-Texture: plush volume — a deep-honey crescent settles the belly and a
    // soft cream highlight lifts the upper-left, so the flat fill reads as fur.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(
      Hand.blob(Offset(0, ry * 0.55), rx * 0.86, ry: ry * 0.55, wobble: 2.2, seed: 14),
      Hand.fill(const Color(0x1F8A5A30)),
    );
    canvas.drawPath(
      Hand.blob(Offset(-rx * 0.22, -ry * 0.5), rx * 0.52, ry: ry * 0.42, wobble: 1.6, seed: 15),
      Hand.fill(const Color(0x22FFF3E0)),
    );
    canvas.restore();
    canvas.drawPath(body, Hand.outline(_ink, 5.5));

    // QA-Texture: a few short fur tufts nick the cheek line so the outline
    // feels fuzzy rather than laser-cut.
    for (final s in const [-1, 1]) {
      for (var k = 0; k < 2; k++) {
        final ty = ry * (-0.06 + k * 0.16);
        final bx = rx * math.sqrt((1 - (ty / ry) * (ty / ry)).clamp(0.0, 1.0));
        final tx = s * bx * 0.96;
        final tuft = Hand.roughLine(
          [Offset(tx, ty), Offset(tx + s * rx * 0.07, ty - rx * 0.01)],
          wobble: 0.4,
          seed: 100 + k + (s > 0 ? 7 : 0),
        );
        canvas.drawPath(tuft, Hand.outline(_ink, 2.0));
      }
    }

    // --- Cream tummy crescent — Gomi's signature belly mark ------------------
    final tummy =
        Hand.blob(Offset(0, ry * 0.52), rx * 0.30, ry: ry * 0.22, wobble: 1.6, seed: 27);
    canvas.drawPath(tummy, Hand.fill(_cream));
    canvas.drawPath(tummy, Hand.outline(_ink, 2.4));

    // --- Feet — two rounded pads at the very bottom, in front ----------------
    _foot(canvas, Offset(-rx * 0.36, ry * 0.90), rx * 0.20, ry * 0.15);
    _foot(canvas, Offset(rx * 0.36, ry * 0.90), rx * 0.20, ry * 0.15);

    // --- Muzzle patch (cream), low-center -----------------------------------
    final muzzleC = Offset(0, ry * 0.30);
    final muzzle = Hand.blob(muzzleC, rx * 0.44, ry: ry * 0.30, wobble: 1.8, seed: 21);
    canvas.drawPath(muzzle, Hand.fill(_cream));
    canvas.drawPath(muzzle, Hand.outline(_ink, 2.6));

    // --- Eyes — small, glossy, set low and close ----------------------------
    // QA-FaceCharm: eyes a hair larger and closer for a sweeter baby cluster,
    // with a second low catch-light so they read wet & lively, not flat dots.
    final eyeY = ry * 0.01;
    final eyeDx = rx * 0.30;
    final eyeR = rx * 0.15;
    if (f.blink > 0.5) {
      Hand.blinkEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft, width: 3.6);
      Hand.blinkEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft, width: 3.6);
    } else {
      Hand.dotEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft);
      Hand.dotEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft);
      final spark = Hand.fill(Colors.white.withValues(alpha: 0.6));
      canvas.drawCircle(
          Offset(-eyeDx, eyeY) + Offset(eyeR * 0.30, eyeR * 0.34), eyeR * 0.17, spark);
      canvas.drawCircle(
          Offset(eyeDx, eyeY) + Offset(eyeR * 0.30, eyeR * 0.34), eyeR * 0.17, spark);
    }

    // --- Cheeks -------------------------------------------------------------
    // QA-BlushColor: softer peach ties into the cream/inner-ear hues, sat a
    // touch lower & inward so it hugs the muzzle like fat cheeks.
    Hand.blush(canvas, Offset(-rx * 0.56, ry * 0.16), rx * 0.185, _blush);
    Hand.blush(canvas, Offset(rx * 0.56, ry * 0.16), rx * 0.185, _blush);

    // --- Nose + philtrum + smile (on the muzzle) ----------------------------
    final noseC = Offset(0, ry * 0.10);
    final noseR = rx * 0.13;
    final nose = Hand.blob(noseC, noseR, ry: noseR * 0.78, wobble: 1.0, seed: 33);
    canvas.drawPath(nose, Hand.fill(_nose));
    canvas.drawPath(nose, Hand.outline(_inkSoft, 2.0));
    // tiny nose gloss
    canvas.drawCircle(
      noseC + Offset(-noseR * 0.28, -noseR * 0.28),
      noseR * 0.22,
      Hand.fill(Colors.white.withValues(alpha: 0.7)),
    );
    // philtrum line down to the smile
    final philtrum = Hand.roughLine(
      [noseC + Offset(0, noseR * 0.7), Offset(0, ry * 0.30)],
      wobble: 0.8,
      seed: 41,
    );
    canvas.drawPath(philtrum, Hand.outline(_inkSoft, 2.6));
    Hand.smile(canvas, Offset(0, ry * 0.31), rx * 0.42, rx * 0.14, _inkSoft, width: 2.8);

    // --- A tiny bee genuinely orbiting the right ear (QA-IdleLife) ----------
    // A real elliptical orbit off the loop phase (not a straight sway-drift),
    // with wings that flutter fast so it reads as a buzzing, living bee.
    final beeAng = f.t * math.pi * 2;
    final beeAnchor = Offset(earDx + rx * 0.44, earBaseY - ry * 0.10);
    final beeC = beeAnchor +
        Offset(math.cos(beeAng) * rx * 0.17, math.sin(beeAng) * rx * 0.12);
    final beeR = rx * 0.055;
    canvas.drawCircle(beeC, beeR, Hand.fill(const Color(0xFFE9B84C))); // body
    canvas.drawCircle(
        beeC + Offset(beeR * 1.5, 0), beeR * 0.9, Hand.fill(_inkSoft)); // head
    final flutter = 1.9 + math.sin(f.t * math.pi * 12) * 0.7; // buzzing wings
    canvas.drawArc(
      Rect.fromCircle(center: beeC + Offset(beeR * 0.6, -beeR * 1.1), radius: beeR),
      3.4,
      flutter,
      false,
      Hand.outline(Colors.white.withValues(alpha: 0.85), 1.6),
    ); // wing

    canvas.restore();

    // --- Honey pot beside the right foot (world space) — the 'honey cub' prop
    final potC = Offset(cx + rx * 0.78, baseCy + ry * 0.92);
    final pot = Hand.blob(potC, rx * 0.16, ry: rx * 0.14, wobble: 1.4, seed: 91);
    canvas.drawPath(pot, Hand.fill(const Color(0xFFD79A55)));
    canvas.drawPath(pot, Hand.outline(_ink, 4.0));
    // cream rim across the top
    final rim = Hand.roughLine([
      potC + Offset(-rx * 0.15, -rx * 0.09),
      potC + Offset(rx * 0.15, -rx * 0.09),
    ], wobble: 0.6, seed: 92);
    canvas.drawPath(rim, Hand.outline(_cream, 5.0));
    // a short honey drip spilling over the rim
    final drip = Hand.roughLine([
      potC + Offset(rx * 0.06, -rx * 0.06),
      potC + Offset(rx * 0.055, rx * 0.11),
    ], wobble: 0.5, seed: 93);
    canvas.drawPath(drip, Hand.outline(const Color(0xFFE7B44E), 3.0));

    // --- Faint paper grain overlay ------------------------------------------
    Hand.paperGrain(canvas, Offset.zero & size, seed: 7, dots: 74);
  }

  /// A round bear ear: outer fur semicircle-ish blob + inner warm-pink patch.
  /// [side] is -1 (left) or 1 (right); the inner ear nudges toward the face.
  void _ear(Canvas canvas, Offset center, double r, int side) {
    // The right ear cocks at a jaunty ~9° tilt — asymmetry that breaks the
    // generic bilateral silhouette and gives Gomi a signature perk.
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

  @override
  bool shouldRepaint(_P03 old) => old.f.t != f.t;
}
