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
// Cuteness cues:
//   · plump rounded bean body in soft pastel green
//   · TWO leaves on a short stem from the top of the head (the 🌱 signature)
//   · big low-placed glossy dot eyes (kawaii rule)
//   · earthy soil-toned blush instead of pink (흙빛 볼)
//   · a soft ground shadow so it feels planted

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
  Widget build(BuildContext context, {double? frozenT}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P09(f),
        size: Size.infinite,
      ),
    );
  }
}

class _P09 extends CustomPainter {
  _P09(this.f);
  final IdleFrame f;

  // Warm, soft palette — nothing pure black.
  static const _bean = Color(0xFFC7E39C); // pistachio bean body
  static const _beanLight = Color(0xFFE4F3C8); // belly highlight
  static const _ink = Color(0xFF7C8A4E); // warm olive outline
  static const _inkSoft = Color(0xFF5E6A38); // face features
  static const _leaf = Color(0xFF9ECD68); // sprout leaves
  static const _leafDark = Color(0xFF6E9440); // leaf outline
  static const _stem = Color(0xFF89B857); // sprout stem
  static const _blush = Color(0xFFD79B72); // 흙빛 earthy-terracotta cheeks
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

    // --- Face — low on the body (kawaii rule), eyes well spaced. ---
    final eyeY = ry * 0.32;
    final eyeDx = rx * 0.36;
    final eyeR = rx * 0.18; // bold round baby eyes that survive shrinking
    if (f.blink > 0.5) {
      Hand.blinkEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft, width: 3.8);
      Hand.blinkEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft, width: 3.8);
    } else {
      Hand.dotEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft);
      Hand.dotEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft);
    }
    // Earthy soil-toned cheeks, sitting just under-and-outside each eye.
    Hand.blush(canvas, Offset(-eyeDx * 1.16, eyeY + eyeR * 1.5), rx * 0.15,
        _blush,
        opacity: 0.6);
    Hand.blush(
        canvas, Offset(eyeDx * 1.16, eyeY + eyeR * 1.5), rx * 0.15, _blush,
        opacity: 0.6);
    // Warm little grin.
    Hand.smile(canvas, Offset(0, eyeY + eyeR * 2.1), rx * 0.26, rx * 0.15,
        _inkSoft,
        width: 3.4);

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

  @override
  bool shouldRepaint(_P09 old) => old.f.t != f.t;
}
