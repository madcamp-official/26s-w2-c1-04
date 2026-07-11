// char_06_seal — "말랑" (Malang), the baby seal.
//
// A freshly-born harp-seal pup drawn in soft crayon: a plump, wobbly cream
// body (wider than it is tall, so it never reads as an egg), big low dot eyes,
// a tiny dusty-rose nose over an ω mouth, radiating whiskers, a downy cowlick
// on the head, little side flippers and a fanned tail poking out the bottom —
// with a scatter of sesame spots as a nod to the 점박이물범 (spotted seal).
//
// Cuteness cues distilled from the references studied (see [inspiration]):
//   · SHAPE   — round dumpling/bean body, no neck, head melts into body.
//   · PROP    — body plump & low; face pushed low; eyes close together.
//   · EYES    — big round glossy black dots ("limpid pools").
//   · BLUSH   — pink cheek dabs just under the eyes.
//   · SIGNATURE — whiskers, a small nose, clasped side flippers, sesame spots,
//                 a soft white body (harp-seal pup / Mamegoma / Umimaru).
//
// Idle signature: the two front flippers wave hello while the tail fans and the
// head cowlick and whiskers sway, the whole pup breathing and bobbing.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char06 extends PetCharacter {
  @override
  String get id => '06';
  @override
  String get name => '말랑';
  @override
  String get concept =>
      '갓 태어난 하프물범 새끼 — 뽀얀 몸에 참깨빛 점박이, 큰 눈과 살랑이는 수염.';
  @override
  String get signature =>
      '앞지느러미로 살랑살랑 인사하고, 꼬리 부채와 머리 솜털이 나풀거린다.';
  @override
  List<String> get inspiration => const [
        'Mamegoma (San-X) — 콩알 물범 마스코트, 흰/분홍/파랑 (blippo.com/blogs/characters/mamegoma)',
        'Umimaru — 일본 해상보안청 하프물범 마스코트, 동글한 흰 몸에 큰 눈',
        'Harp seal pup — 뽀얀 흰 털에 크고 검은 눈 (animalfactguide.com harp-seal)',
        '점박이물범 / ゴマフアザラシ (sesame-spotted seal) — 참깨빛 점 무늬',
        'Vecteezy — cute kawaii seal chibi mascot vector (vecteezy.com/vector-art/23169748)',
        'Dreamstime — chibi seal / kawaii seal stock illustrations',
        'iStock — 물개 새끼 / baby seal royalty-free vectors',
        'Redbubble — kawaii seal stickers: thick outline, clasped flippers, dot eyes',
        'Cartoon seal sticker — light-gray spotted body, small round eyes, whiskers',
        'Pinterest — cute seal outline / kawaii seal collections',
        'Clipartkorea — 물범 스톡 일러스트',
        'modeS blog — San-X Mamegoma seals feature',
      ];
  @override
  Color get accent => const Color(0xFF9DC6D6); // soft ocean blue chip

  @override
  Widget build(BuildContext context, {double? frozenT}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P06(f),
        size: Size.infinite,
      ),
    );
  }
}

class _P06 extends CustomPainter {
  _P06(this.f);
  final IdleFrame f;

  static const _cream = Color(0xFFF9F5EE); // pup body
  static const _belly = Color(0xFFFFFEFB); // lighter tummy
  static const _ink = Color(0xFF8B7862); // warm outline (never black)
  static const _inkSoft = Color(0xFF5E4C3C); // face features
  static const _spot = Color(0xFFCEBCA6); // sesame spots
  static const _nose = Color(0xFFCE9391); // dusty-rose nose (blush-harmonised)
  static const _blush = Color(0xFFF2AEB2);
  static const _ice = Color(0xFF9DC6D6); // soft ocean-blue floe

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    final cx = w / 2;
    final rx = w * 0.31; // half-width  → body ~0.62w
    final ry = w * 0.29 * f.breath; // half-height (plump, a touch < rx)
    final baseCy = h * 0.575 + f.bob;

    // Ground stays put while the pup bobs, so it reads as gently lifting.
    final groundY = h * 0.575 + ry * 1.16;

    // Ice floe the pup rests on — one calm pale-blue slab (no fussy bubbles
    // that would just turn to noise when the pup shrinks to a thumbnail).
    final ice = Hand.blob(Offset(cx, groundY + ry * 0.10), rx * 1.12,
        ry: ry * 0.30, wobble: 3.0, seed: 61, squash: 0.10);
    canvas.drawPath(ice, Hand.fill(_ice.withValues(alpha: 0.5)));
    canvas.drawPath(ice, Hand.outline(_ink, 3.4));

    // Soft grounding shadow — shrinks a touch on the up-bob.
    final shW = rx * (1.5 - f.bob * 0.04);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY), width: shW, height: ry * 0.24),
      Hand.fill(const Color(0x16000000)),
    );

    canvas.save();
    canvas.translate(cx, baseCy);

    // -- fanned tail (drawn behind the body, peeks out the bottom) ----------
    _tail(canvas, rx, ry);

    // -- body --------------------------------------------------------------
    final body = Hand.blob(Offset.zero, rx, ry: ry, wobble: 3.0, seed: 6, squash: 0.12);
    canvas.drawPath(body, Hand.fill(_cream));
    // soft lighter belly for roundness (crayon-soft blob edge, not a hard oval)
    final belly = Hand.blob(Offset(0, ry * 0.26), rx * 0.58,
        ry: ry * 0.52, wobble: 2.2, seed: 7, squash: 0.10);
    canvas.drawPath(belly, Hand.fill(_belly));
    canvas.drawPath(body, Hand.outline(_ink, 5.4));
    // soft crayon volume — a shade pooled low, fading up, for roundness.
    final volRect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
    final volShader = RadialGradient(
      center: const Alignment(0, 0.55),
      radius: 0.95,
      colors: [_spot.withValues(alpha: 0.12), _spot.withValues(alpha: 0.0)],
    ).createShader(volRect);
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(volRect, Paint()..shader = volShader);
    canvas.restore();

    // -- front flippers (wave hello) ---------------------------------------
    _flipper(canvas, rx, ry, -1);
    _flipper(canvas, rx, ry, 1);

    // -- a few confident sesame spots (spotted-seal nod, kept legible) ------
    final spotP = Hand.fill(_spot.withValues(alpha: 0.5));
    canvas.drawCircle(Offset(-rx * 0.30, -ry * 0.50), rx * 0.062, spotP);
    canvas.drawCircle(Offset(rx * 0.16, -ry * 0.62), rx * 0.05, spotP);
    canvas.drawCircle(Offset(rx * 0.42, -ry * 0.30), rx * 0.056, spotP);

    // -- head cowlick (downy pup fuzz, sways) ------------------------------
    _fluff(canvas, rx, ry);

    // -- face (pushed low, kawaii) -----------------------------------------
    final eyeY = ry * 0.24; // pushed lower → bigger babyish crown above
    final eyeDx = rx * 0.34; // well spaced
    final eyeR = rx * 0.16; // big "limpid pool" dots
    if (f.blink > 0.5) {
      Hand.blinkEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft, width: 3.6);
      Hand.blinkEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft, width: 3.6);
    } else {
      Hand.dotEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft);
      Hand.dotEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft);
    }

    // blush on the cheeks — just below & outside the eyes.
    Hand.blush(canvas, Offset(-eyeDx - eyeR * 1.0, eyeY + eyeR * 1.5), rx * 0.16, _blush);
    Hand.blush(canvas, Offset(eyeDx + eyeR * 1.0, eyeY + eyeR * 1.5), rx * 0.16, _blush);

    // whiskers — two per side, gentle sway.
    _whiskers(canvas, rx, eyeY + eyeR * 2.5);

    // nose — a small rounded dusty-rose dot with a highlight.
    final noseY = eyeY + eyeR * 1.85;
    final noseR = eyeR * 0.6;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, noseY), width: noseR * 2.2, height: noseR * 1.7),
      Hand.fill(_nose),
    );
    canvas.drawCircle(
      Offset(-noseR * 0.35, noseY - noseR * 0.35),
      noseR * 0.34,
      Hand.fill(Colors.white.withValues(alpha: 0.7)),
    );

    // ω mouth — two little smiles under the nose (no fussy philtrum line).
    final mouthY = noseY + eyeR * 0.72;
    Hand.smile(canvas, Offset(-rx * 0.10, mouthY), rx * 0.22, rx * 0.11, _inkSoft, width: 3.0);
    Hand.smile(canvas, Offset(rx * 0.10, mouthY), rx * 0.22, rx * 0.11, _inkSoft, width: 3.0);

    canvas.restore();

    // faint paper grain overlay
    Hand.paperGrain(canvas, Offset.zero & size, seed: 6, dots: 90);
  }

  // ---- pieces --------------------------------------------------------------

  void _tail(Canvas canvas, double rx, double ry) {
    canvas.save();
    canvas.translate(0, ry * 0.98);
    canvas.rotate(f.sway * 0.012); // whole tail sways a touch
    for (final side in const [-1, 1]) {
      canvas.save();
      canvas.translate(side * rx * 0.24, 0);
      // each fluke fans a little further on the sway
      canvas.rotate(side * (0.5 + f.sway * 0.03));
      final fluke = Hand.blob(Offset.zero, rx * 0.20, ry: rx * 0.12,
          wobble: 1.4, seed: 20 + side);
      canvas.drawPath(fluke, Hand.fill(_cream));
      canvas.drawPath(fluke, Hand.outline(_ink, 4.2));
      canvas.restore();
    }
    canvas.restore();
  }

  void _flipper(Canvas canvas, double rx, double ry, int side) {
    canvas.save();
    canvas.translate(side * rx * 0.66, ry * 0.30);
    // hang down-outward and wave — bigger swing, and desynced with a const
    // offset on the right so the two flippers alternate instead of mirror-locking.
    canvas.rotate(side * (0.62 + f.sway * 0.11) - (side > 0 ? 0.10 : 0.0));
    final paddle =
        Hand.blob(Offset(0, rx * 0.16), rx * 0.135, ry: rx * 0.24, wobble: 1.3, seed: 30 + side);
    canvas.drawPath(paddle, Hand.fill(_cream));
    canvas.drawPath(paddle, Hand.outline(_ink, 4.4));
    canvas.restore();
  }

  void _fluff(Canvas canvas, double rx, double ry) {
    canvas.save();
    canvas.translate(0, -ry * 0.9);
    canvas.rotate(f.sway * 0.02);
    final p = Hand.outline(_ink, 3.2);
    for (var i = -1; i <= 1; i++) {
      final bx = i * rx * 0.11;
      final tip = f.sway * 1.6;
      canvas.drawPath(
        Hand.roughLine([
          Offset(bx, 0),
          Offset(bx + tip * 0.4, -ry * 0.14),
          Offset(bx + tip, -ry * 0.24),
        ], wobble: 0.8, seed: 40 + i),
        p,
      );
    }
    canvas.restore();
  }

  // Downy newborn fuzz — a row of tiny soft tufts hugging the upper dome, each
  // with its own wobble so the pup reads fluffy, not rubber-smooth.
  void _downy(Canvas canvas, double rx, double ry, Path body) {
    canvas.save();
    canvas.clipPath(body);
    final p = Hand.outline(_ink.withValues(alpha: 0.20), 1.6);
    for (var i = -3; i <= 3; i++) {
      final bx = i * rx * 0.15;
      final by = -ry * 0.9 + (bx * bx) / (rx * 2.6); // follow the sphere
      final tip = f.sway * 0.6 - rx * 0.02;
      canvas.drawPath(
        Hand.roughLine([
          Offset(bx, by),
          Offset(bx + tip, by - ry * 0.11),
        ], wobble: 0.5, seed: 70 + i),
        p,
      );
    }
    canvas.restore();
  }

  void _whiskers(Canvas canvas, double rx, double baseY) {
    final p = Hand.outline(_inkSoft.withValues(alpha: 0.85), 2.0);
    const angs = [-0.24, -0.02, 0.20]; // upper / mid / lower whisker
    for (final side in const [-1, 1]) {
      final baseX = side * rx * 0.16;
      for (final a in angs) {
        final len = rx * (0.44 + a.abs() * 0.2);
        final sway = f.sway * 1.1;
        final tip = Offset(
          baseX + side * math.cos(a) * len,
          baseY + math.sin(a) * len + sway,
        );
        final mid = Offset(
          (baseX + tip.dx) / 2 + side * rx * 0.02,
          (baseY + tip.dy) / 2 - rx * 0.02,
        );
        canvas.drawPath(
          Hand.roughLine([Offset(baseX, baseY), mid, tip], wobble: 0.6, seed: 50),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_P06 old) => old.f.t != f.t;
}
