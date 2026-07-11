// char_01_cat — "나비" (Nabi), the rounded kitten.
//
// A soft potato-round kitten drawn in warm crayon: a wobbly butter-cream
// body, wide triangular ears with rosy inner triangles, low-set dot eyes, a
// tiny "ω" cat mouth, three whisker strands per cheek, stubby paws, and a
// chubby tail that flicks side to side. Built entirely on the charlab toolkit
// so it shares the same hand as the reference egg while reading, at a glance,
// as unmistakably a cat.
//
// Cuteness cues distilled from the reference study (see [inspiration]):
//   · big head fused into a round body (chibi 2–3 head ratio, no neck)
//   · wide-set triangular ears, rounded, with pink inner triangles
//   · dot eyes placed LOW and far apart, soft blush right under them
//   · minimal upward "ω" mouth + tiny triangle nose
//   · a thick curling tail as the signature silhouette read
//
// Idle: the body breathes, the whole cat bobs, the ears perk, and the tail
// swishes — a contented sitting kitten.

import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char01 extends PetCharacter {
  @override
  String get id => '01';
  @override
  String get name => '나비';
  @override
  String get concept => '크레용으로 그린 둥근 아기 고양이 — 삼각 귀, 낮게 박힌 점 눈, 통통한 꼬리.';
  @override
  String get signature => '숨 쉬며 통통해지고, 꼬리를 살랑살랑, 목의 방울이 잘랑, 가끔 귀를 쫑긋하며 눈을 깜빡인다.';
  @override
  List<String> get inspiration => const [
        'catdrawing.app — Chibi Cat Drawing Tutorial (super-cute kawaii style)',
        'Dreamstime — Chibi Cat stock illustrations (big-head SD proportion)',
        'Vecteezy — "cute cat hug fish kawaii chibi mascot, outline style"',
        'Freepik — kawaii cat chibi mascot, thick-outline style',
        'Pinterest — "64 Chibi cat ideas" board',
        'drawtwist.com — 41 Easy Cute Cat Doodle drawing ideas',
        'diaryofajournalplanner.com — 100+ Cat Doodles (round body, triangle ears)',
        'scroodlydoodle.com — 20 Easy / 14 Simple Cat Doodles',
        'Pusheen (pusheen.com, Wikipedia) — round loaf-cat IP',
        'supercutekawaii.com — Cute Characters: Kawaii Cats',
        'iStock / Dreamstime — Round Cat & Kitten-Face vector illustrations',
        'christinebritton.com — Mini Cute Cat drawing ideas (dot eyes + whiskers)',
      ];
  @override
  Color get accent => const Color(0xFFF2A96A);

  @override
  Widget build(BuildContext context,
      {double? frozenT, PetExpression expression = PetExpression.neutral}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P01(f),
        size: Size.infinite,
      ),
    );
  }
}

class _P01 extends CustomPainter {
  _P01(this.f);
  final IdleFrame f;

  static const _cream = Color(0xFFFFF3E1); // warm butter body
  static const _ink = Color(0xFF9C7B57); // warm brown outline (never black)
  static const _inkSoft = Color(0xFF7E6244); // softer brown for face lines
  static const _earPink = Color(0xFFF2B091); // rosy inner ear / paw beans
  static const _nose = Color(0xFFE68F7C); // little heart-nose
  static const _blush = Color(0xFFF3A79F); // cheek blush
  static const _shade = Color(0x0F5A3F27); // faint inner volume shadow
  static const _tabby = Color(0xFFF2A96A); // orange tabby accent (stripes + tail tip)
  static const _collar = Color(0xFFE58AA6); // rose collar band
  static const _bell = Color(0xFFF6C64B); // little gold jingle bell

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final baseCy = h * 0.585 + f.bob;

    final rx = w * 0.315; // body half-width  → body ≈ 63% of stage width
    final ry = w * 0.300 * f.breath; // body half-height, breathes vertically

    // Ground shadow (absolute, so it stays put while the cat bobs above it).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseCy + ry * 1.02),
        width: rx * 1.7,
        height: ry * 0.30,
      ),
      Hand.fill(const Color(0x18000000)),
    );

    canvas.save();
    canvas.translate(cx, baseCy);

    // --- Tail (behind the body so its base tucks under the silhouette) ------
    _drawTail(canvas, rx, ry);

    // --- Ears (behind the body; only the tips read above the head curve) ----
    _drawEar(canvas, Offset(-rx * 0.50, -ry * 0.58), -1, rx, ry);
    _drawEar(canvas, Offset(rx * 0.50, -ry * 0.58), 1, rx, ry);

    // --- Body: one wobbly round loaf (head fused in, no neck) ---------------
    final body = Hand.blob(Offset.zero, rx, ry: ry, wobble: 3.0, seed: 11, squash: 0.09);
    canvas.drawPath(body, Hand.fill(_cream));
    // gentle lower-belly shading for a bit of roundness
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, ry * 0.42), width: rx * 1.5, height: ry * 0.7),
      Hand.fill(_shade),
    );
    // faint crayon hatching inside the loaf → the stated waxy grain, clipped to
    // the silhouette so no stroke leaks past the edge.
    canvas.save();
    canvas.clipPath(body);
    final crayon = Hand.outline(const Color(0x0C9C7B57), 2.4);
    for (var i = 0; i < 6; i++) {
      final yy = -ry * 0.55 + ry * 0.26 * i;
      canvas.drawPath(
        Hand.roughLine([
          Offset(-rx * 0.78, yy),
          Offset(0, yy + ry * 0.06),
          Offset(rx * 0.78, yy - ry * 0.04),
        ], wobble: 2.2, seed: 60 + i),
        crayon,
      );
    }
    canvas.restore();
    canvas.drawPath(body, Hand.outline(_ink, 5.5));
    // fake crayon double-edge: a faint offset second contour
    canvas.drawPath(
      body.shift(const Offset(1.2, 1.0)),
      Hand.outline(const Color(0x559C7B57), 3),
    );

    // --- Stubby front paws sitting at the base ------------------------------
    _drawPaw(canvas, Offset(-rx * 0.40, ry * 0.80), rx);
    _drawPaw(canvas, Offset(rx * 0.40, ry * 0.80), rx);

    // --- Collar + bell: this loaf is plainly somebody's beloved pet ---------
    _drawCollar(canvas, rx, ry);

    // --- Face (kawaii rule: everything low on the head) ---------------------
    final eyeY = ry * 0.18;
    final eyeDx = rx * 0.42; // set wider apart → babyish, kawaii spacing
    final eyeR = rx * 0.170; // bigger eyes for a rounder, cuter head ratio
    // gaze drifts side to side with the idle sway — a subtle "look around".
    final eyeLook = f.sway * 0.7;

    // Gentle head tilt: the face cluster leans with the idle sway — a slow
    // secondary motion that runs OUT OF PHASE with the breath/bob pump.
    canvas.save();
    canvas.rotate(f.sway * 0.012);

    // tabby forehead stripes between the ears — the "나비" identity mark
    _drawForeheadStripes(canvas, rx, ry);

    // whiskers first, so eyes/nose sit cleanly on top
    _drawWhiskers(canvas, -1, eyeY, rx, eyeR);
    _drawWhiskers(canvas, 1, eyeY, rx, eyeR);

    // blush pads just under the eyes
    Hand.blush(canvas, Offset(-eyeDx * 1.22, eyeY + eyeR * 1.9), rx * 0.18, _blush);
    Hand.blush(canvas, Offset(eyeDx * 1.22, eyeY + eyeR * 1.9), rx * 0.18, _blush);

    if (f.blink > 0.5) {
      Hand.blinkEye(
          canvas, Offset(-eyeDx + eyeLook, eyeY), eyeR, _inkSoft, width: 3.6);
      Hand.blinkEye(
          canvas, Offset(eyeDx + eyeLook, eyeY), eyeR, _inkSoft, width: 3.6);
    } else {
      final le = Offset(-eyeDx + eyeLook, eyeY);
      final re = Offset(eyeDx + eyeLook, eyeY);
      Hand.dotEye(canvas, le, eyeR, _inkSoft);
      Hand.dotEye(canvas, re, eyeR, _inkSoft);
      // a second, lower glint under the primary catch-light → wet, lively eyes
      final glint = Hand.fill(Colors.white.withValues(alpha: 0.7));
      canvas.drawCircle(le + Offset(eyeR * 0.30, eyeR * 0.42), eyeR * 0.16, glint);
      canvas.drawCircle(re + Offset(eyeR * 0.30, eyeR * 0.42), eyeR * 0.16, glint);
    }

    // little triangle nose + "ω" cat mouth
    final noseY = eyeY + eyeR * 1.55;
    _drawNose(canvas, Offset(0, noseY), rx * 0.085);
    _drawMouth(canvas, Offset(0, noseY + eyeR * 0.55), rx * 0.16);

    canvas.restore(); // end head tilt

    canvas.restore();

    // --- Paper grain overlay across the whole stage -------------------------
    // Denser for the stated crayon look; a second offset pass deepens the
    // grain (per-fleck alpha lives in the shared toolkit) without editing it.
    Hand.paperGrain(canvas, Offset.zero & size, seed: 6, dots: 130);
    Hand.paperGrain(canvas, Offset.zero & size, seed: 17, dots: 130);
  }

  // A chubby curling tail, drawn as a fat outlined stroke that swishes at the
  // base with the idle sway — the character's signature move. Its base is
  // pushed out past the body edge so the whole curl emerges into silhouette,
  // and it carries an orange tabby tip to match the forehead stripes.
  void _drawTail(Canvas canvas, double rx, double ry) {
    final base = Offset(rx * 0.60, ry * 0.55);
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(f.sway * 0.055); // swish — bigger now that the tail is visible
    final pts = <Offset>[
      Offset.zero,
      Offset(rx * 0.45, ry * 0.08),
      Offset(rx * 0.85, -ry * 0.15),
      Offset(rx * 0.98, -ry * 0.55),
      Offset(rx * 0.80, -ry * 0.70), // tip lands well past the body edge
    ];
    final path = Hand.roughLine(pts, wobble: 1.4, seed: 21);
    final tailW = rx * 0.30;
    // fake outline: fat ink stroke first, cream stroke on top
    canvas.drawPath(
      path,
      Hand.outline(_ink, tailW + 6)..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Hand.outline(_cream, tailW)..strokeCap = StrokeCap.round,
    );
    // orange tabby tip: paint the upper curl over the cream, still framed by
    // the ink contour underneath.
    final tipPath = Hand.roughLine([
      Offset(rx * 0.92, -ry * 0.36),
      Offset(rx * 0.98, -ry * 0.55),
      Offset(rx * 0.80, -ry * 0.70),
    ], wobble: 1.0, seed: 22);
    canvas.drawPath(
      tipPath,
      Hand.outline(_tabby, tailW)..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  // Two-three short forehead stripes between the ears in the orange accent —
  // this is what makes the loaf read specifically as an orange-and-cream
  // tabby ("나비") rather than any round cat.
  void _drawForeheadStripes(Canvas canvas, double rx, double ry) {
    final paint = Hand.outline(_tabby, 4);
    final strokes = <List<Offset>>[
      [Offset(-rx * 0.22, -ry * 0.40), Offset(-rx * 0.26, -ry * 0.60)],
      [Offset(0, -ry * 0.43), Offset(0, -ry * 0.64)],
      [Offset(rx * 0.22, -ry * 0.40), Offset(rx * 0.26, -ry * 0.60)],
    ];
    for (var i = 0; i < strokes.length; i++) {
      canvas.drawPath(
          Hand.roughLine(strokes[i], wobble: 1.0, seed: 50 + i), paint);
    }
  }

  // A wide triangular ear with a rounded rosy inner triangle. [sign] is -1 for
  // the left ear, +1 for the right. Perks slightly with the idle sway.
  void _drawEar(Canvas canvas, Offset baseMid, double sign, double rx, double ry) {
    canvas.save();
    canvas.translate(baseMid.dx, baseMid.dy);
    canvas.rotate(sign * f.sway * 0.020); // ear twitch / perk
    final earH = ry * 0.78;
    final half = rx * 0.34;
    // slight hand wobble on the corners
    Offset j(double x, double y, int s) =>
        Offset(x + handNoise(s.toDouble(), seed: 30) * 1.6,
            y + handNoise(s.toDouble() + 9, seed: 30) * 1.6);
    final inner = j(sign * -half * 0.15, 6, 1);
    final outer = j(sign * half, 8, 2);
    final apex = j(sign * half * 0.42, -earH, 3);

    final path = Path()
      ..moveTo(inner.dx, inner.dy)
      ..quadraticBezierTo(
          sign * half * 0.55, -earH * 0.55, apex.dx, apex.dy)
      ..quadraticBezierTo(
          sign * half * 1.02, -earH * 0.30, outer.dx, outer.dy)
      ..close();
    canvas.drawPath(path, Hand.fill(_cream));
    canvas.drawPath(path, Hand.outline(_ink, 4.6));

    // inner ear triangle, scaled toward the apex
    final innerPath = Path()
      ..moveTo(inner.dx * 0.55 + apex.dx * 0.10, inner.dy - 2)
      ..quadraticBezierTo(sign * half * 0.34, -earH * 0.42,
          apex.dx * 0.72, apex.dy * 0.66)
      ..quadraticBezierTo(sign * half * 0.60, -earH * 0.22,
          outer.dx * 0.55, outer.dy - 2)
      ..close();
    canvas.drawPath(innerPath, Hand.fill(_earPink));
    canvas.restore();
  }

  void _drawPaw(Canvas canvas, Offset at, double rx) {
    final r = Rect.fromCenter(
        center: at, width: rx * 0.40, height: rx * 0.30);
    canvas.drawOval(r, Hand.fill(_cream));
    canvas.drawOval(r, Hand.outline(_ink, 4.2));
    // tiny toe divider
    canvas.drawLine(
      Offset(at.dx, at.dy - rx * 0.06),
      Offset(at.dx, at.dy + rx * 0.12),
      Hand.outline(_inkSoft, 2.2),
    );
  }

  // A rose collar band across the chest with a small gold bell — a touch of
  // story (a cared-for house cat) plus an extra warm colour note. The bell
  // swings a hair with the idle sway for a soft, believable jingle.
  void _drawCollar(Canvas canvas, double rx, double ry) {
    final band = Hand.roughLine([
      Offset(-rx * 0.32, ry * 0.60),
      Offset(0, ry * 0.70),
      Offset(rx * 0.32, ry * 0.60),
    ], wobble: 1.0, seed: 71);
    // ink frame under, rose band on top (same fake-outline trick as the tail)
    canvas.drawPath(band, Hand.outline(_ink, 9)..strokeCap = StrokeCap.round);
    canvas.drawPath(band, Hand.outline(_collar, 6)..strokeCap = StrokeCap.round);

    // the bell swings a hair with the idle sway → a gentle jingle
    final swing = f.sway * 0.28;
    final bc = Offset(swing, ry * 0.71);
    final br = rx * 0.10;
    canvas.drawCircle(bc, br, Hand.fill(_bell));
    canvas.drawCircle(bc, br, Hand.outline(_ink, 3.0));
    // cross slit + soft highlight so it reads as a metal bell
    canvas.drawLine(Offset(bc.dx - br * 0.7, bc.dy + br * 0.12),
        Offset(bc.dx + br * 0.7, bc.dy + br * 0.12), Hand.outline(_inkSoft, 2.0));
    canvas.drawLine(Offset(bc.dx, bc.dy + br * 0.12),
        Offset(bc.dx, bc.dy + br * 0.95), Hand.outline(_inkSoft, 2.0));
    canvas.drawCircle(bc + Offset(-br * 0.32, -br * 0.36), br * 0.28,
        Hand.fill(Colors.white.withValues(alpha: 0.6)));
  }

  void _drawWhiskers(
      Canvas canvas, double sign, double eyeY, double rx, double eyeR) {
    final startX = sign * rx * 0.46;
    final endX = sign * rx * 1.14;
    final ys = <double>[eyeY + eyeR * 0.4, eyeY + eyeR * 1.35, eyeY + eyeR * 2.3];
    for (var i = 0; i < ys.length; i++) {
      final y = ys[i];
      final dip = (i - 1) * eyeR * 0.55; // fan up/level/down
      final path = Hand.roughLine([
        Offset(startX, y),
        Offset((startX + endX) / 2, y + dip * 0.4),
        Offset(endX, y + dip),
      ], wobble: 0.9, seed: 40 + i);
      canvas.drawPath(path, Hand.outline(_inkSoft, 2.1));
    }
  }

  void _drawNose(Canvas canvas, Offset at, double s) {
    final path = Path()
      ..moveTo(at.dx - s, at.dy - s * 0.5)
      ..lineTo(at.dx + s, at.dy - s * 0.5)
      ..quadraticBezierTo(at.dx, at.dy + s * 1.2, at.dx, at.dy + s * 1.2)
      ..quadraticBezierTo(at.dx, at.dy + s * 1.2, at.dx - s, at.dy - s * 0.5)
      ..close();
    canvas.drawPath(path, Hand.fill(_nose));
  }

  // The classic "ω" kitten mouth: two little upward arcs meeting under the nose.
  void _drawMouth(Canvas canvas, Offset at, double w) {
    final paint = Hand.outline(_inkSoft, 3.0);
    final left = Path()
      ..moveTo(at.dx, at.dy)
      ..quadraticBezierTo(at.dx - w * 0.5, at.dy + w * 0.6,
          at.dx - w, at.dy - w * 0.12);
    final right = Path()
      ..moveTo(at.dx, at.dy)
      ..quadraticBezierTo(at.dx + w * 0.5, at.dy + w * 0.6,
          at.dx + w, at.dy - w * 0.12);
    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
  }

  @override
  bool shouldRepaint(_P01 old) => old.f.t != f.t;
}
