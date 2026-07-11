// char_02_bunny — "토리" (Tori), the crayon bunny.
//
// A soft, upright egg-body bunny in the cozy hand-drawn family: warm brown
// outline, cream fur, two tall pink-lined ears that sway like they're catching
// a breeze, low dot eyes set wide apart, a little rose nose over two tiny buck
// teeth, and pink blush. Built only from the Charlab toolkit so it shares the
// same "hand" as the reference egg while reading, unmistakably, as a bunny.
//
// Cuteness cues distilled from the references studied (see [inspiration]):
//   · tall ears are THE silhouette — slender, upright, pink inner lining;
//   · round chubby body, big head, tiny feet peeking at the base;
//   · eyes placed LOW and wide, small triangular rose nose;
//   · signature bunny detail = two little front teeth (앞니) under an ω mouth;
//   · soft pink blush, warm off-white fur, thick soft outline (never black).

import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char02 extends PetCharacter {
  @override
  String get id => '02';
  @override
  String get name => '토리';
  @override
  String get concept => '크레용으로 그린 듯한 토끼 — 살랑이는 긴 귀, 동그란 몸, 앞니 두 개.';
  @override
  String get signature => '숨 쉴 때 몸이 부풀고, 긴 귀가 바람결처럼 살랑 기울며, 가끔 눈을 깜빡인다.';
  @override
  List<String> get inspiration => const [
        'Miffy (Dick Bruna) — minimalist upright long-ear bunny, primary shapes',
        'Molang — chubby round white bunny, tiny dot eyes',
        'My Melody (Sanrio) — rabbit with soft pink inner ears',
        'Cinnamoroll (Sanrio) — fluffy cream body, long floppy ears',
        'Aniteez DDEONGbyeoli — pink rabbit, round face, buck teeth',
        'Vecteezy "Adorable chibi kawaii bunny" — little dot eyes, bold outline',
        'Kore Kawaii Bunny Sticker Pack — big blush, sparkle-eyed chibi bunny',
        'Shutterstock chibi bunny — tall upright ears, pink inner lining, fluffy chest',
        'Super Cute Kawaii!! bunny rabbits roundup — simple pastel line mascots',
        'Redbubble Korean bunny stickers — pastel, blush cheeks, floppy ears',
        'Pinterest "Cute Chibi Bunny" boards — plump body, tiny limbs, buck teeth',
      ];
  @override
  Color get accent => const Color(0xFFF2A9BE);

  @override
  Widget build(BuildContext context,
      {double? frozenT, PetExpression expression = PetExpression.neutral}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P02(f),
        size: Size.infinite,
      ),
    );
  }
}

class _P02 extends CustomPainter {
  _P02(this.f);
  final IdleFrame f;

  static const _fur = Color(0xFFFFF6EF); // warm cream
  static const _ink = Color(0xFF9C7B62); // warm brown outline
  static const _inkSoft = Color(0xFF7C6350); // softer brown for face
  static const _innerEar = Color(0xFFF4B9C6); // soft pink inner ear
  static const _blush = Color(0xFFF3A6B4);
  static const _nose = Color(0xFFE98BA0); // rose nose
  static const _tooth = Color(0xFFFFFDFA);
  static const _inkWax = Color(0x2E9C7B62); // waxy crayon bloom under the outline
  static const _furShade = Color(0xFFEFDDCF); // soft tan for fur tufts + underside

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    final cx = w / 2;
    final ryBase = w * 0.285; // shorter → chubbier, less egg-tall
    final rx = w * 0.30; // width ≈ 0.60w > height ⇒ round, head-heavy chibi read
    final ry = ryBase * f.breath; // breathe: body height flexes
    final bodyCyBase = h * 0.63;
    final cy = bodyCyBase + f.bob; // whole bunny bobs

    // Soft ground shadow (fixed to the floor; shrinks a touch as the body lifts).
    final groundY = bodyCyBase + ryBase * 1.02;
    final shadowW = rx * (1.7 + f.bob * 0.03);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, groundY), width: shadowW, height: ryBase * 0.22),
      Hand.fill(const Color(0x16000000)),
    );

    canvas.save();
    canvas.translate(cx, cy);

    // --- Ears (behind the body so their base tucks into the head) ----------
    _02ear(canvas, -1, rx, ry);
    _02ear(canvas, 1, rx, ry);

    // --- Body: a wobbly upright egg, cream fill + soft thick outline --------
    final body =
        Hand.blob(Offset.zero, rx, ry: ry, wobble: 3.8, seed: 12, squash: 0.12);
    canvas.drawPath(body, Hand.fill(_fur));
    // Soft volume so the egg reads round, not paper-flat: a top sheen, a faint
    // warm underside, and a soft tan fur-shadow that gives the cream mass depth.
    Hand.blush(canvas, Offset(0, -ry * 0.35), rx * 0.6, const Color(0xFFFFFFFF),
        opacity: 0.22);
    Hand.blush(canvas, Offset(0, ry * 0.5), rx * 0.5, _blush, opacity: 0.10);
    Hand.blush(canvas, Offset(0, ry * 0.6), rx * 0.62, _furShade, opacity: 0.45);
    // Crayon edge: a soft waxy bloom under a crisp core stroke → hand-drawn
    // "손맛" instead of one mechanical outline (this is a *crayon* bunny).
    canvas.drawPath(body, Hand.outline(_inkWax, 9.0));
    canvas.drawPath(body, Hand.outline(_ink, 5.0));

    // --- Tiny feet peeking at the base -------------------------------------
    for (final s in const [-1.0, 1.0]) {
      final foot = Hand.blob(Offset(s * rx * 0.32, ry * 0.92), rx * 0.20,
          ry: rx * 0.13, wobble: 1.2, seed: s < 0 ? 31 : 33);
      canvas.drawPath(foot, Hand.fill(_fur));
      canvas.drawPath(foot, Hand.outline(_ink, 4.0));
    }

    // --- A tiny carrot tucked beside the right foot (story prop) ------------
    final carrotC = Offset(rx * 0.55, ry * 0.9);
    final carrot =
        Hand.blob(carrotC, rx * 0.10, ry: rx * 0.20, wobble: 1.2, seed: 41);
    canvas.drawPath(carrot, Hand.fill(const Color(0xFFF6A24B)));
    canvas.drawPath(carrot, Hand.outline(_ink, 3.5));
    final carrotTop = carrotC + Offset(0, -rx * 0.20);
    const leaf = Color(0xFF9BC26A);
    canvas.drawPath(
      Hand.roughLine([carrotTop, carrotTop + Offset(-rx * 0.09, -rx * 0.17)],
          seed: 42),
      Hand.outline(leaf, 3.0),
    );
    canvas.drawPath(
      Hand.roughLine([carrotTop, carrotTop + Offset(rx * 0.07, -rx * 0.19)],
          seed: 43),
      Hand.outline(leaf, 3.0),
    );

    // --- Face (placed LOW on the body — the kawaii rule) --------------------
    final eyeY = ry * 0.24;
    final eyeDx = rx * 0.38; // grouped a touch closer ⇒ sweeter face
    final eyeR = rx * 0.165; // bigger, more magnetic eyes
    if (f.blink > 0.5) {
      Hand.blinkEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft, width: 3.4);
      Hand.blinkEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft, width: 3.4);
    } else {
      Hand.dotEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft);
      Hand.dotEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft);
      // A second wet-sparkle lowlight makes the eyes read glossy and alive.
      for (final s in const [-1.0, 1.0]) {
        canvas.drawCircle(
          Offset(s * eyeDx + eyeR * 0.30, eyeY + eyeR * 0.44),
          eyeR * 0.17,
          Hand.fill(Colors.white.withValues(alpha: 0.7)),
        );
      }
    }

    // Blush under the eyes.
    Hand.blush(canvas, Offset(-eyeDx * 1.16, eyeY + eyeR * 1.7), rx * 0.16, _blush);
    Hand.blush(canvas, Offset(eyeDx * 1.16, eyeY + eyeR * 1.7), rx * 0.16, _blush);

    // Fluffy cheeks — soft cream fur clumps beside the muzzle so the "fur"
    // actually reads, kept clear of the central features to stay tidy.
    final cheekY = eyeY + eyeR * 1.4;
    for (final s in const [-1.0, 1.0]) {
      final base = Offset(s * rx * 0.64, cheekY);
      final fluff = Hand.roughLine([
        base + Offset(-s * rx * 0.02, ry * 0.05),
        base + Offset(s * rx * 0.05, 0),
        base + Offset(s * rx * 0.10, ry * 0.045),
        base + Offset(s * rx * 0.16, 0),
        base + Offset(s * rx * 0.21, ry * 0.05),
      ], wobble: 0.5, seed: s < 0 ? 64 : 68);
      canvas.drawPath(fluff, Hand.outline(_furShade, 2.4));
    }

    // Bunny nose sniff — a gentle deterministic quiver (handNoise, no clock/Random)
    // so the snout twitches like it's smelling the carrot = extra idle life.
    final sniff = Offset(
      handNoise(f.t * 10, seed: 9) * rx * 0.012,
      handNoise(f.t * 10 + 40, seed: 9).abs() * rx * 0.014,
    );
    canvas.save();
    canvas.translate(sniff.dx, sniff.dy);
    _02muzzle(canvas, rx, eyeY + eyeR * 2.0);
    canvas.restore();

    canvas.restore();

    // Faint paper grain, overlaid last for texture.
    Hand.paperGrain(canvas, Offset.zero & size, seed: 6, dots: 190);
  }

  // One ear: an elongated wobbly blob with a pink inner lining, pivoting at the
  // head-top so [f.sway] tilts the whole pair like a breeze catches them.
  void _02ear(Canvas c, double sign, double rx, double ry) {
    c.save();
    c.translate(sign * rx * 0.34, -ry * 0.78);
    // Base splay + a per-ear lagging flutter so the pair shimmers rather than
    // tilting as one rigid V = the signature "긴 귀가 살랑".
    c.rotate(sign * 0.14 + (f.sway + sign * 0.6) * 0.028);

    // Slimmer, taller ears for a cleaner long-ear read; tips lift on inhale.
    final earH = ry * 1.32 * f.breath;
    final earW = rx * 0.23;
    final earCy = -earH * 0.5;

    final outer = Hand.blob(Offset(0, earCy), earW,
        ry: earH * 0.5, wobble: 1.8, seed: sign < 0 ? 21 : 23);
    c.drawPath(outer, Hand.fill(_fur));
    c.drawPath(outer, Hand.outline(_inkWax, 7.5)); // matching crayon bloom
    c.drawPath(outer, Hand.outline(_ink, 4.2));

    final inner = Hand.blob(Offset(0, earCy - earH * 0.03), earW * 0.50,
        ry: earH * 0.40, wobble: 1.1, seed: sign < 0 ? 25 : 27);
    c.drawPath(inner, Hand.fill(_innerEar));

    c.restore();
  }

  // Nose + ω mouth + two little buck teeth, centered under the eyes.
  void _02muzzle(Canvas c, double rx, double ny) {
    // Rose nose — a small rounded downward triangle.
    final nw = rx * 0.13;
    final nose = Path()
      ..moveTo(-nw, ny - nw * 0.45)
      ..quadraticBezierTo(0, ny - nw * 0.65, nw, ny - nw * 0.45)
      ..quadraticBezierTo(nw * 0.55, ny + nw * 0.55, 0, ny + nw * 0.75)
      ..quadraticBezierTo(-nw * 0.55, ny + nw * 0.55, -nw, ny - nw * 0.45)
      ..close();
    c.drawPath(nose, Hand.fill(_nose));
    c.drawPath(nose, Hand.outline(_inkSoft, 2.2));

    final nby = ny + nw * 0.75; // nose bottom

    // Two front teeth — a small white rounded rect split down the middle.
    final tw = rx * 0.065; // half-width
    final th = rx * 0.13;
    final ty = nby + rx * 0.02;
    final teeth = RRect.fromRectAndRadius(
      Rect.fromLTWH(-tw, ty, tw * 2, th),
      Radius.circular(tw * 0.6),
    );
    c.drawRRect(teeth, Hand.fill(_tooth));
    c.drawRRect(teeth, Hand.outline(_inkSoft, 2.4));
    c.drawLine(Offset(0, ty), Offset(0, ty + th), Hand.outline(_inkSoft, 2.0));

    // ω mouth — two little arcs wrapping around the top of the teeth.
    final my = ty + th * 0.18;
    final left = Path()
      ..moveTo(0, my)
      ..quadraticBezierTo(-rx * 0.12, my + rx * 0.11, -rx * 0.20, my + rx * 0.01);
    final right = Path()
      ..moveTo(0, my)
      ..quadraticBezierTo(rx * 0.12, my + rx * 0.11, rx * 0.20, my + rx * 0.01);
    c.drawPath(left, Hand.outline(_inkSoft, 3.0));
    c.drawPath(right, Hand.outline(_inkSoft, 3.0));
  }

  @override
  bool shouldRepaint(_P02 old) => old.f.t != f.t;
}
