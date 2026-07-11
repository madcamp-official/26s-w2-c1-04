// char_07_ghost — "유리" (Yuri), the soft translucent ghost.
//
// A little water-droplet spirit: a rounded dome head melting into a body that
// ends in a wavy, rippling hem. Semi-transparent milk-lavender fill with a
// glowing halo behind it so it reads as *see-through*, warm mauve hand-drawn
// outline, two low dot eyes, an open little "oh~" smile, rosy cheeks, and two
// stubby raised arms mid a shy little "boo". Its name 유리 (= glass) is a pun on
// its translucency. Drawn in the same crayon hand as the reference egg, but a
// clearly readable ghost silhouette — never a plain circle or the reference egg.
//
// Cuteness cues distilled from studied references (see [inspiration]):
//   · rounded dome top + flowing wavy/scalloped bottom hem (the ghost tell)
//   · translucent milky body → a soft glow halo behind, lighter inner belly
//   · big low-placed dot eyes with a catch-light (kawaii rule)
//   · rosy round blush + a small open smile
//   · little stubby raised nub arms (the pastel "boo!"/"yay" pose)
//   · signature: floats (bob) while the wavy hem ripples side to side like cloth

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char07 extends PetCharacter {
  @override
  String get id => '07';
  @override
  String get name => '유리';
  @override
  String get concept =>
      '반투명 물방울 유령 — 둥근 돔 머리, 아래 물결 자락, 은은한 무리(halo), 살짝 든 몽당 팔.';
  @override
  String get signature => '둥실 떠오르며 아래 물결 자락이 천처럼 살랑살랑 일렁이고, 가끔 눈을 깜빡인다.';
  @override
  List<String> get inspiration => const [
        'Dreamstime — Adorable Chibi Ghost (large round eyes, joyful blush marks)',
        'iStock — Small Cute Ghost, watercolour (rosy cheeks, curious round eyes)',
        'Southeastprints — Cute Kawaii Ghost (big eyes, rosy-orange cheeks, wavy sheet)',
        'Vecteezy — Cute Ghost / Playful Boo (flat cartoon, rounded top wavy bottom)',
        'colormadehappy — 15 Ghost Drawing Ideas (rounded top, flowing wavy bottom)',
        'colorfulfor — 18 Easy Cute Ghost Drawings (wavy 5–6 point hem, center longer)',
        'Hi Hello There — Ghost Sticker Doodle minis (hand-drawn, thick outline)',
        'Milky Tomato — Silly Doodle Ghost Stickers (comic-book doodle ghosts)',
        'Holli Rose Art — Ghost Sticker (simple single thick outline)',
        'Cults3D — Flexi Kawaii Boo (adorable articulated ghost, kawaii dot eyes)',
        'tryfreetemplates — Hamster-in-ghost doodle (wavy hem, cream paper, clean lines)',
        'Emojipedia — 👻 Ghost emoji (little raised arms, playful boo pose)',
        'Pinterest — Kawaii Ghost / Chibi Ghost boards (pastel, blush, floating)',
        'LINE Friends — soft rosy-cheeked minimal mascot family (hand-drawn warmth)',
      ];
  @override
  Color get accent => const Color(0xFFC7BCE8);

  @override
  Widget build(BuildContext context, {double? frozenT}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P07(f),
        size: Size.infinite,
      ),
    );
  }
}

class _P07 extends CustomPainter {
  _P07(this.f);
  final IdleFrame f;

  // Warm-cool, soft palette — translucent milk with a lavender cast; nothing
  // pure black. Outline is a warm mauve-taupe so it still feels crayon-drawn.
  static const _body = Color(0xFFF6F4FB); // milky lavender-white
  static const _belly = Color(0xFFFFFFFF); // inner sheen highlight
  static const _halo = Color(0xFFCFC3EC); // soft glow behind the body
  static const _ink = Color(0xFF7E6E7A); // warm mauve outline
  static const _inkSoft = Color(0xFF6E6478); // face features
  static const _mouth = Color(0xFF8A6E80); // open-smile fill
  static const _blush = Color(0xFFF4A69E); // warm peach-rose — pops on cool milk-lavender

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    final cx = w / 2;
    final baseCy = h * 0.47 + f.bob * 2.0; // centred a touch low, floats with bob
    final rx = w * 0.30; // half-width → body ~60% of the stage
    final ryTop = rx * 1.28 * f.breath; // taller rounder dome → head reads bigger (breathes)
    final ryBot = rx * 1.05 * f.breath; // shorter, chunkier body → cuter head:body (breathes)

    // --- Ground shadow, drawn in absolute space so it stays put while the
    //     ghost floats. It shrinks/fades as the ghost lifts (bob < 0). ---
    final lift = -f.bob; // >0 when floating up
    final shW = rx * 1.55 - lift * 5.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.86),
        width: shW,
        height: shW * 0.24,
      ),
      Hand.fill(Color.fromARGB((0x18 - lift * 3).clamp(6, 24).toInt(), 0, 0, 0)),
    );

    canvas.save();
    canvas.translate(cx + f.sway * 0.8, baseCy);

    // --- Halo: a blurred lavender glow behind the body → the translucent,
    //     ethereal feel without a real background to show through. ---
    final glow = Paint()
      ..color = _halo.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(
      _07body(rx * 1.06, ryTop * 1.06, ryBot * 1.04, f.t * math.pi * 2),
      glow,
    );

    // --- Stubby raised arms, drawn behind the body so their inner edge tucks
    //     under it and they read as attached. They sway (the shy "boo"). ---
    final armLift = f.sway * 0.5;
    _07arm(canvas, Offset(-rx * 0.86, ryBot * 0.18 - armLift.abs() * 0.3),
        rx * 0.20, -1, armLift);
    _07arm(canvas, Offset(rx * 0.86, ryBot * 0.18 - armLift.abs() * 0.3),
        rx * 0.20, 1, armLift);

    // --- Body: the ghost silhouette — dome + rippling wavy hem. ---
    final body = _07body(rx, ryTop, ryBot, f.t * math.pi * 2);
    canvas.drawPath(body, Hand.fill(_body.withValues(alpha: 0.94)));

    // Inner sheen — a soft lighter blob up-left, clipped to the body, giving
    // volume and the see-through milkiness.
    canvas.save();
    canvas.clipPath(body);
    final sheen = Hand.blob(
      Offset(-rx * 0.24, -ryTop * 0.30),
      rx * 0.60,
      ry: ryTop * 0.62,
      wobble: 2.2,
      seed: 24,
    );
    canvas.drawPath(sheen, Hand.fill(_belly.withValues(alpha: 0.55)));
    canvas.restore();

    canvas.drawPath(body, Hand.outline(_ink, 5.2));

    // --- Face — low on the body (kawaii rule). ---
    final eyeY = ryBot * 0.18;
    final eyeDx = rx * 0.31; // eyes a touch closer → sweeter, more focused face
    final eyeR = rx * 0.17; // bigger round kawaii dot eyes
    if (f.blink > 0.5) {
      Hand.blinkEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft, width: 3.6);
      Hand.blinkEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft, width: 3.6);
    } else {
      Hand.dotEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft);
      Hand.dotEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft);
    }

    // Rosy round cheeks tucked under the eyes.
    Hand.blush(canvas, Offset(-eyeDx * 1.22, eyeY + eyeR * 1.8), rx * 0.18, _blush,
        opacity: 0.55);
    Hand.blush(canvas, Offset(eyeDx * 1.22, eyeY + eyeR * 1.8), rx * 0.18, _blush,
        opacity: 0.55);

    // Small open "oh~" smile: a filled mouth pulled up under the eyes so the
    // features read as one sweet cluster.
    final mouthC = Offset(0, eyeY + eyeR * 2.1);
    final mouth = Path()
      ..addOval(Rect.fromCenter(
          center: mouthC, width: rx * 0.23, height: rx * 0.19));
    canvas.drawPath(mouth, Hand.fill(_mouth.withValues(alpha: 0.85)));
    canvas.drawPath(mouth, Hand.outline(_inkSoft, 2.4));
    // A tiny highlight in the mouth → a glistening, lively little "oh".
    canvas.drawCircle(
      mouthC + Offset(-rx * 0.05, -rx * 0.045),
      rx * 0.035,
      Hand.fill(_belly.withValues(alpha: 0.5)),
    );

    canvas.restore();

    // --- Twinkles: shimmer shed by the little spirit, breathing with the loop
    //     — a big one by the head and a small anti-phase one drifting lower-left,
    //     so it reads as a glowing spirit rather than one lone decoration. ---
    final tw = 0.5 + 0.5 * math.sin(f.t * math.pi * 2);
    _07sparkle(canvas, Offset(cx + rx * 1.06, baseCy - ryTop * 0.55),
        rx * 0.10 * (0.6 + tw * 0.4));
    final tw2 = 0.5 + 0.5 * math.sin(f.t * math.pi * 2 + math.pi * 0.6);
    _07sparkle(canvas, Offset(cx - rx * 1.0, baseCy + ryBot * 0.12),
        rx * 0.065 * (0.5 + tw2 * 0.5));

    // Faint paper grain overlay for texture.
    Hand.paperGrain(canvas, Offset.zero & size, seed: 7, dots: 72);
  }

  /// The ghost silhouette: a wobbly rounded dome flowing into a wavy hem.
  /// [ripple] (radians) sways the inner hem tails so the fabric lives.
  Path _07body(double rx, double ryTop, double ryBot, double ripple) {
    final pts = <Offset>[];

    // Dome — top half, sampled from left shoulder over the top to the right.
    const domeSamples = 22;
    for (var i = 0; i <= domeSamples; i++) {
      final a = math.pi + (i / domeSamples) * math.pi; // π..2π (upper arc)
      final n = handNoise(i * 0.4, seed: 71) * 3.4;
      pts.add(Offset(math.cos(a) * (rx + n), math.sin(a) * (ryTop + n)));
    }

    // Wavy hem — right shoulder → left, alternating down-tails and up-notches.
    const hemN = 8; // even → both ends land as edge tails at ±rx
    final scallop = ryBot * 0.30; // deeper notches → a crisp wavy-hem ghost tell
    for (var i = 0; i <= hemN; i++) {
      final tt = i / hemN;
      final x = rx - tt * (2 * rx); // rx → -rx
      final tail = i.isEven; // down tip vs up notch
      // Down-tails droop, longest at the centre (the classic cute-ghost hem);
      // the two shoulder tails stay put so the dome join stays clean.
      final droop = tail ? ryBot * 0.16 * (1 - (tt - 0.5).abs() * 2) : 0.0;
      var y = tail ? ryBot + droop : ryBot - scallop;
      var dx = 0.0;
      // Ripple the interior tails only; keep the two edge tails stable.
      if (tail && i != 0 && i != hemN) {
        dx = math.sin(ripple + i * 0.9) * (ryBot * 0.055);
        y += math.sin(ripple * 1.3 + i) * (ryBot * 0.03);
      }
      final n = handNoise(i * 0.6 + 40, seed: 71) * 3.0;
      pts.add(Offset(x + dx + n, y + n));
    }

    return _07smoothClosed(pts);
  }

  /// A stubby raised arm nub. [side] = -1 left / +1 right; [lift] raises the tip.
  void _07arm(Canvas canvas, Offset at, double r, int side, double lift) {
    final blob = Hand.blob(
      Offset(at.dx + side * r * 0.2, at.dy - lift),
      r,
      ry: r * 1.15,
      wobble: 1.4,
      seed: side > 0 ? 52 : 61,
    );
    canvas.drawPath(blob, Hand.fill(_body.withValues(alpha: 0.94)));
    canvas.drawPath(blob, Hand.outline(_ink, 4.4));
  }

  /// A tiny four-point sparkle.
  void _07sparkle(Canvas canvas, Offset at, double s) {
    if (s < 0.6) return;
    final p = Path()
      ..moveTo(at.dx, at.dy - s)
      ..quadraticBezierTo(at.dx, at.dy, at.dx + s, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + s)
      ..quadraticBezierTo(at.dx, at.dy, at.dx - s, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - s)
      ..close();
    canvas.drawPath(p, Hand.fill(_halo.withValues(alpha: 0.85)));
  }

  /// Close a point ring into a smooth path (midpoint quadratics), matching the
  /// toolkit's hand-drawn blob smoothing.
  Path _07smoothClosed(List<Offset> p) {
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

  @override
  bool shouldRepaint(_P07 old) => old.f.t != f.t;
}
