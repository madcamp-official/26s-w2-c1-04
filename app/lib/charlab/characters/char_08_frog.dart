// char_08_frog — "개굴이" (Gaeguri), the little frog.
//
// A soft matcha-green chibi frog drawn in the same crayon "hand" as the rest of
// the lab: a chubby wobbly body that widens at the bottom, a pale belly, and —
// the one cue that instantly reads *frog* — two big goggle eyes perched on TOP
// of the head like a pair of bumps. Wide smile, pink cheeks, tiny nostril dots,
// stubby webbed hands and feet, and a single leaf-sprout on the head that
// sways. Warm olive outline, never pure black.
//
// Cuteness cues distilled from the references studied (see [inspiration]):
//   · eyes as two round bumps sitting on top of the head ("like a hat")
//   · wide curved smile / Keroppi-style V-mouth
//   · round belly, wide at the bottom, pale belly patch
//   · pink blush under the eyes + two dot nostrils
//   · thick simple outline, soft round shapes

import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char08 extends PetCharacter {
  @override
  String get id => '08';
  @override
  String get name => '개굴이';
  @override
  String get concept =>
      '연잎에서 갓 나온 말랑 청개구리 — 머리 위로 뿅 솟은 큰 두 눈, 통통한 배, 새싹 하나.';
  @override
  String get signature =>
      '숨 쉴 때 통통한 배가 부풀고, 가끔 큰 두 눈을 깜빡이며 머리 위 새싹이 살랑인다.';
  @override
  List<String> get inspiration => const [
        'Keroppi / Kerokerokeroppi (Sanrio) — V-mouth, pink cheeks, eyes on top',
        'Vecteezy — "Adorable kawaii chibi style frog" cartoon mascot',
        'Dreamstime — Kawaii Frog Stickers illustration set',
        'drawcartoonstyle.com — How to Draw a Cute Chibi Frog',
        'popartsteps.com — cartoon frog, eyes resting on the face "like a hat"',
        'drawingsof.com — Cute Frog Drawing (round belly, wide mouth)',
        'letsdrawthat.com — How to Draw a Frog easy step-by-step',
        'Pinterest — Frog Chibi board',
        'Pinterest — Chibi Frog Kawaii board',
        'bunnyhello.com — Top 15 Cartoon Frog Characters',
        'iStock — Cute Frog royalty-free illustrations',
        'Vecteezy — Kawaii Frog vector art collection',
      ];
  @override
  Color get accent => const Color(0xFF9FCB86);

  @override
  Widget build(BuildContext context, {double? frozenT}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P08(f),
        size: Size.infinite,
      ),
    );
  }
}

class _P08 extends CustomPainter {
  _P08(this.f);
  final IdleFrame f;

  // Warm, soft palette — green frog, olive-brown outline (never pure black).
  static const _green = Color(0xFF9FCB86); // soft matcha body
  static const _greenShade = Color(0xFF86B96C); // deeper green for belly form
  static const _greenLimb = Color(0xFF93C078); // slightly deeper for limbs
  static const _belly = Color(0xFFF6EFD3); // pale cream belly
  static const _bellyShade = Color(0xFFE3D3A0); // faint deeper cream for shading
  static const _lily = Color(0xFF7FB35E); // lotus-pad green
  static const _ink = Color(0xFF7C7248); // warm olive outline
  static const _inkSoft = Color(0xFF5A5232); // darker warm for pupils/mouth
  static const _eyeWhite = Color(0xFFFFFDF5); // cream eye whites
  static const _blush = Color(0xFFF29CAB); // soft rose cheeks (harmonises w/ green)
  static const _leaf = Color(0xFF8CBE68); // leaf-sprout green

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    final cx = w / 2;
    final baseCy = h * 0.585 + f.bob;
    final rx = w * 0.315; // body ~63% of width
    final baseRy = w * 0.268; // squatter, rounder baby proportion
    final ry = baseRy * f.breath; // breathing puffs the round belly

    // Soft ground shadow (global, under everything).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseCy + ry * 1.02),
        width: rx * 1.7,
        height: ry * 0.26,
      ),
      Hand.fill(const Color(0x16000000)),
    );

    canvas.save();
    // whole-body horizontal drift with the idle loop (not frozen-stiff).
    canvas.translate(cx + f.sway * 0.6, baseCy);

    // -- lily pad the frog sits on ('연잎에서 갓 나온' payoff) -----------------
    final padCenter = Offset(0, ry * 0.92);
    final padOval = Path()
      ..addOval(Rect.fromCenter(
        center: padCenter,
        width: rx * 1.7,
        height: ry * 0.34,
      ));
    // pizza-slice notch cut on the front (edge → centre wedge).
    final padNotch = Path()
      ..moveTo(padCenter.dx, padCenter.dy)
      ..lineTo(padCenter.dx - rx * 0.13, padCenter.dy + ry * 0.24)
      ..lineTo(padCenter.dx + rx * 0.13, padCenter.dy + ry * 0.24)
      ..close();
    final pad = Path.combine(PathOperation.difference, padOval, padNotch);
    canvas.drawPath(pad, Hand.fill(_lily));
    canvas.drawPath(pad, Hand.outline(_ink, 3.4));

    // -- webbed feet (drawn first so the body tucks over their tops) ----------
    for (final s in const [-1.0, 1.0]) {
      final foot = Hand.blob(
        Offset(rx * 0.40 * s, ry * 0.80),
        rx * 0.22,
        ry: ry * 0.15,
        wobble: 2.0,
        seed: 20 + (s > 0 ? 1 : 0),
        squash: 0.0,
      );
      canvas.drawPath(foot, Hand.fill(_greenLimb));
      canvas.drawPath(foot, Hand.outline(_ink, 4.2));
      // little webbed toe notches
      for (var i = -1; i <= 1; i++) {
        final tx = rx * 0.40 * s + i * rx * 0.11;
        canvas.drawLine(
          Offset(tx, ry * 0.74),
          Offset(tx, ry * 0.86),
          Hand.outline(_ink, 2.2),
        );
      }
    }

    // -- stubby arms + webbed hands (also under the body) ---------------------
    for (final s in const [-1.0, 1.0]) {
      final arm = Hand.roughLine(
        [
          Offset(rx * 0.62 * s, ry * 0.02),
          Offset(rx * 0.92 * s, ry * 0.20),
          Offset(rx * 1.02 * s, ry * 0.40),
        ],
        wobble: 1.2,
        seed: 30 + (s > 0 ? 1 : 0),
      );
      canvas.drawPath(arm, Hand.outline(_greenLimb, 11));
      canvas.drawPath(arm, Hand.outline(_ink, 4.0));
      // stubby hands bob with the loop instead of being frozen — and wobble
      // like the rest of the drawing instead of being ruler-perfect circles.
      final hand = Offset(rx * 1.02 * s + f.sway * 0.5, ry * 0.44);
      final handBlob =
          Hand.blob(hand, rx * 0.12, wobble: 1.3, seed: 34 + (s > 0 ? 1 : 0));
      canvas.drawPath(handBlob, Hand.fill(_greenLimb));
      canvas.drawPath(handBlob, Hand.outline(_ink, 3.6));
    }

    // Eye geometry — defined BEFORE the body so the two goggle bumps can be
    // fused into the head silhouette (the unmistakable "frog" read).
    final eyeR = rx * 0.34; // oversized goggle/chibi eyes
    final eyeDx = rx * 0.42;
    final eyeCy = -ry * 0.86; // sit high so the bumps clearly crown the head

    // -- body — chubby wobbly blob with two eye-bumps fused on top -----------
    final bodyBase = Hand.blob(
      Offset.zero,
      rx,
      ry: ry,
      wobble: 3.0,
      seed: 8,
      squash: 0.20, // rounder, settled bottom
    );
    // Fuse two wobbly bumps into the outline so the silhouette itself GROWS the
    // goggle eyes (a thin green eyelid-rim shows around each cream disc). No
    // more two compass-perfect discs floating over the head.
    final bumpL =
        Hand.blob(Offset(-eyeDx, eyeCy), eyeR * 1.12, wobble: 1.4, seed: 42);
    final bumpR =
        Hand.blob(Offset(eyeDx, eyeCy), eyeR * 1.12, wobble: 1.4, seed: 43);
    final body = Path.combine(PathOperation.union,
        Path.combine(PathOperation.union, bodyBase, bumpL), bumpR);
    canvas.drawPath(body, Hand.fill(_green));
    // Soft lower-body shadow (clipped to the body) gives the belly roundness
    // so it stops reading as a flat sticker.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rx * 0.12, ry * 0.45),
        width: rx * 1.4,
        height: ry * 0.9,
      ),
      Hand.fill(_greenShade.withValues(alpha: 0.30)),
    );
    canvas.restore();
    canvas.drawPath(body, Hand.outline(_ink, 5.4));

    // Pale belly patch, lower-front.
    final belly = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(0, ry * 0.34),
        width: rx * 1.06,
        height: ry * 0.98,
      ));
    canvas.drawPath(belly, Hand.fill(_belly.withValues(alpha: 0.9)));
    // Faint top-edge shadow inside the belly so it curves under the chin.
    canvas.save();
    canvas.clipPath(belly);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, ry * 0.34 - ry * 0.55),
        width: rx * 1.1,
        height: ry * 0.7,
      ),
      Hand.fill(_bellyShade.withValues(alpha: 0.35)),
    );
    canvas.restore();
    canvas.drawPath(belly, Hand.outline(_ink.withValues(alpha: 0.35), 2.2));

    // -- eyes: cream goggle discs seated in the fused head bumps -------------
    for (final s in const [-1.0, 1.0]) {
      final at = Offset(eyeDx * s, eyeCy);
      // Wobbly cream disc (hand-drawn, not a compass-perfect circle).
      final white = Hand.blob(at, eyeR, wobble: 1.6, seed: 40 + (s > 0 ? 1 : 0));
      canvas.drawPath(white, Hand.fill(_eyeWhite));
      canvas.drawPath(white, Hand.outline(_ink, 4.6));
      if (f.blink > 0.5) {
        Hand.blinkEye(canvas, at, eyeR * 0.72, _inkSoft, width: 4.2);
      } else {
        // Live gaze: the big eyes must not be dead between blinks — the pupils
        // drift with the idle sway and lift a hair on each breath.
        final gaze = Offset(f.sway * 0.7, (f.breath - 1) * eyeR * 1.2);
        final pupil = at + Offset(-eyeR * 0.16 * s, eyeR * 0.12) + gaze;
        Hand.dotEye(canvas, pupil, eyeR * 0.46, _inkSoft);
        // A second wet sparkle lower-right for extra charm.
        canvas.drawCircle(
          pupil + Offset(eyeR * 0.16, eyeR * 0.20),
          eyeR * 0.09,
          Hand.fill(const Color(0xE6FFFFFF)),
        );
      }
    }

    // -- cheeks, nostrils, open grin -----------------------------------------
    // Cheeks hug just under the eye-bumps (pulled inboard so they belong to the
    // face, not the body edge) and glow in a softer rose that harmonises with
    // the matcha green + cream.
    final cheekY = eyeCy + eyeR * 1.3;
    Hand.blush(canvas, Offset(-rx * 0.50, cheekY), rx * 0.20, _blush,
        opacity: 0.40);
    Hand.blush(canvas, Offset(rx * 0.50, cheekY), rx * 0.20, _blush,
        opacity: 0.40);

    // Nostrils — two tiny dots just above the grin.
    canvas.drawCircle(Offset(-rx * 0.10, -ry * 0.12), rx * 0.035, Hand.fill(_inkSoft));
    canvas.drawCircle(Offset(rx * 0.10, -ry * 0.12), rx * 0.035, Hand.fill(_inkSoft));

    // A soft OPEN grin: a warm mouth-interior sliver under a Keroppi-ish smile,
    // with rosy dimples at the corners — more charm than a single plain arc.
    final mouthC = Offset(0, ry * 0.02);
    final mouthW = rx * 0.56, mouthD = rx * 0.22;
    final mouthFill = Path()
      ..moveTo(mouthC.dx - mouthW / 2, mouthC.dy)
      ..quadraticBezierTo(mouthC.dx, mouthC.dy + mouthD, // bottom = smile curve
          mouthC.dx + mouthW / 2, mouthC.dy)
      ..quadraticBezierTo(mouthC.dx, mouthC.dy + mouthD * 0.18, // top = lip line
          mouthC.dx - mouthW / 2, mouthC.dy)
      ..close();
    canvas.drawPath(mouthFill, Hand.fill(const Color(0xFFE7897F)));
    Hand.blush(canvas, Offset(-mouthW / 2, mouthC.dy + mouthD * 0.12),
        rx * 0.09, _blush, opacity: 0.5);
    Hand.blush(canvas, Offset(mouthW / 2, mouthC.dy + mouthD * 0.12),
        rx * 0.09, _blush, opacity: 0.5);
    Hand.smile(canvas, mouthC, mouthW, mouthD, _inkSoft, width: 3.6);

    canvas.restore();

    // -- leaf-sprout on the head, sways with the idle loop -------------------
    final headTop = baseCy - ry;
    // follow the body's horizontal drift so the sprout stays rooted on the head.
    _drawSprout(
        canvas, Offset(cx + rx * 0.04 + f.sway * 0.6, headTop + ry * 0.06), rx * 0.30);

    // Faint paper grain overlay.
    Hand.paperGrain(canvas, Offset.zero & size, seed: 6, dots: 100);
  }

  void _drawSprout(Canvas canvas, Offset base, double s) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(f.sway * 0.055); // livelier sway (~10deg)
    // stem
    final stem = Path()
      ..moveTo(0, s * 0.55)
      ..quadraticBezierTo(-s * 0.12, -s * 0.15, s * 0.05, -s * 0.75);
    canvas.drawPath(stem, Hand.outline(_ink, 3.4));
    // a single pointed leaf
    final leaf = Path()
      ..moveTo(s * 0.05, -s * 0.75)
      ..quadraticBezierTo(s * 0.95, -s * 0.95, s * 0.62, -s * 1.55)
      ..quadraticBezierTo(s * 0.10, -s * 1.20, s * 0.05, -s * 0.75)
      ..close();
    canvas.drawPath(leaf, Hand.fill(_leaf));
    canvas.drawPath(leaf, Hand.outline(_ink, 3.2));
    // center vein
    canvas.drawLine(
      Offset(s * 0.14, -s * 0.86),
      Offset(s * 0.60, -s * 1.32),
      Hand.outline(_ink.withValues(alpha: 0.5), 2.0),
    );
    // a tiny dew droplet resting on the leaf.
    final dew = Offset(s * 0.44, -s * 1.06);
    canvas.drawCircle(dew, s * 0.11, Hand.fill(const Color(0x77FFFFFF)));
    canvas.drawCircle(
      dew + Offset(-s * 0.03, -s * 0.04),
      s * 0.035,
      Hand.fill(const Color(0xCCFFFFFF)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_P08 old) => old.f.t != f.t;
}
