// char_04_chick — "삐약이" (Ppiyagi), the just-hatched chick.
//
// A round, buttery-yellow chick blob drawn in the shared crayon "hand": warm
// brown outline (never pure black), two low dot eyes set close together, a
// little orange diamond beak, pink cheek blush, stubby tucked wings, tiny
// three-toed feet — and the signature charm every cute chick shares: a single
// sprout of head feather ("머리 깃털 한 올") curling up top. It breathes, blinks,
// flaps its wings a hair, and the head feather sways side to side.
//
// Cuteness cues distilled from the references studied (see [inspiration]):
//   · one round chubby ball body (big-head baby proportion), no neck
//   · dot eyes placed LOW and close; short blink curves when shut
//   · small orange triangle/diamond beak, split upper/lower
//   · round pink blush on the cheeks
//   · two small stubby wings hugging the sides
//   · ONE springy head-feather strand — the reads-as-a-chick signature
//   · warm pastel-yellow body, amber-orange beak & feet
//
// Toolkit-only, deterministic (handNoise/seeds), no assets/Random/DateTime.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char04 extends PetCharacter {
  @override
  String get id => '04';
  @override
  String get name => '삐약이';
  @override
  String get concept =>
      '이제 막 껍질을 깬 병아리 — 통통 노란 몸에 콕 찍은 눈, 머리 위 삐죽 솟은 깃털 한 올.';
  @override
  String get signature =>
      '머리 깃털 한 올이 좌우로 살랑이고, 숨 쉴 때 통통 부풀며 작은 날개를 팔랑, 가끔 눈을 깜빡인다.';
  @override
  List<String> get inspiration => const [
        'Vecteezy — cute kawaii chicken chibi mascot (bold outline, big eyes)',
        'Adobe Stock — cute kawaii chicken chibi mascot vector cartoon style',
        'Redbubble CozyKawaiiArt — "Cute Baby Chicken Chick Blushing" sticker',
        'Dreamstime — minimalist kawaii baby-chick outline (large eyes, simple beak)',
        'HowToDrawForKids — chick tutorial: dot eye + triangle beak',
        'Dessindigo — baby-chick drawing (very round oversized head proportion)',
        'EmilyDrawing — baby chick with closed happy-curve eyes + head-feather squiggle',
        'LetsDrawThat — cartoon baby chick step-by-step',
        'iStock 병아리 — side-view walking flat-vector chick',
        'Sanrio Shakipiyo — round light-yellow chick in eggshell',
        'Sanrio Gudetama / Hyoko — round egg-yolk mascot proportions',
        'Squishmallows "Aimee the Chick" — round body, pale belly, orange beak, fluffy wings',
        'Bellzi "Mini Chicki the Chick" — blushy cheeks, tiny wings, feet',
      ];
  @override
  Color get accent => const Color(0xFFFBD36A);

  @override
  Widget build(BuildContext context,
      {double? frozenT, PetExpression expression = PetExpression.neutral}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P04(f),
        size: Size.infinite,
      ),
    );
  }
}

class _P04 extends CustomPainter {
  _P04(this.f);
  final IdleFrame f;

  // Warm palette — soft, no pure black.
  static const _sun = Color(0xFFFBD36A); // body yellow
  static const _sunDeep = Color(0xFFF6C34E); // wing / shading
  static const _belly = Color(0xFFFFECAF); // fluffy tummy
  static const _ink = Color(0xFF9C7B45); // warm brown outline
  static const _inkSoft = Color(0xFF7C5E33); // eyes / smile
  static const _beak = Color(0xFFF4A64C); // amber orange
  static const _beakDeep = Color(0xFFD9812F); // beak / feet outline
  static const _blush = Color(0xFFF79680); // peach-coral cheeks (bridge yellow↔amber)
  static const _mouth = Color(0xFFB6613F); // warm inner-beak (never pure black)

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;

    final rx = w * 0.30;
    final ry = w * 0.318 * f.breath; // rounder ball → baby-cute head:body ratio
    final baseCy = h * 0.55 + f.bob;

    // --- soft ground shadow (stays grounded; shrinks as the chick lifts) ---
    final groundY = h * 0.55 + ry * 0.98;
    final sScale = 1 - (f.bob / 2.4) * 0.10;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY),
        width: rx * 1.55 * sScale,
        height: ry * 0.24 * sScale,
      ),
      Hand.fill(const Color(0x16000000)),
    );

    canvas.save();
    canvas.translate(cx, baseCy);

    // --- feet first, so the legs tuck under the round body ---
    _04foot(canvas, -rx * 0.30, ry * 0.66, rx * 0.34);
    _04foot(canvas, rx * 0.30, ry * 0.66, rx * 0.34);

    // --- body: one wobbly round blob ---
    final body =
        Hand.blob(Offset.zero, rx, ry: ry, wobble: 3.0, seed: 11, squash: 0.08);
    canvas.drawPath(body, Hand.fill(_sun));

    // fluffy belly patch, clipped inside the body so it never spills out
    canvas.save();
    canvas.clipPath(body);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, ry * 0.30),
        width: rx * 1.05,
        height: ry * 0.95,
      ),
      Hand.fill(_belly.withValues(alpha: 0.75)),
    );
    // soft bottom-shading crescent so the body isn't a flat single fill
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, ry * 0.55),
        width: rx * 1.6,
        height: ry * 0.8,
      ),
      Hand.fill(_sunDeep.withValues(alpha: 0.22)),
    );
    canvas.restore();

    canvas.drawPath(body, Hand.outline(_ink, 5.4));

    // just-hatched cracked eggshell cradling the body base — the story cue
    _04shell(canvas, rx, ry);
    // downy fluff ticks along the crown so the top edge reads feathery
    _04fluff(canvas, rx, ry);

    // --- stubby wings hugging the sides, with a faint idle flap ---
    final flap = math.sin(f.t * math.pi * 2) * 0.14;
    _04wing(canvas, -1, -rx * 0.92, -ry * 0.02, rx * 0.58, flap);
    _04wing(canvas, 1, rx * 0.92, -ry * 0.02, rx * 0.58, flap);

    // --- face, set low with a big baby forehead (kawaii ratio) ---
    final eyeY = ry * 0.16; // lower face → larger forehead (baby cue)
    final eyeDx = rx * 0.32;
    final eyeR = rx * 0.165; // bigger, younger eyes
    if (f.blink > 0.5) {
      Hand.blinkEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft, width: 3.6);
      Hand.blinkEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft, width: 3.6);
    } else {
      Hand.dotEye(canvas, Offset(-eyeDx, eyeY), eyeR, _inkSoft);
      Hand.dotEye(canvas, Offset(eyeDx, eyeY), eyeR, _inkSoft);
      // a second, drifting sparkle → livelier, sweeter eyes
      final spark = Hand.fill(Colors.white.withValues(alpha: 0.85));
      final sx = f.sway * 0.14;
      for (final ex in [-eyeDx, eyeDx]) {
        canvas.drawCircle(Offset(ex + eyeR * 0.30 + sx, eyeY - eyeR * 0.44),
            eyeR * 0.15, spark);
      }
    }

    // peach-coral cheeks, tucked in under the eyes and softly blended
    Hand.blush(canvas, Offset(-eyeDx * 1.12, eyeY + eyeR * 1.5), rx * 0.155,
        _blush, opacity: 0.42);
    Hand.blush(canvas, Offset(eyeDx * 1.12, eyeY + eyeR * 1.5), rx * 0.155, _blush,
        opacity: 0.42);

    // beak — an orange bill that opens and closes as the chick chirps ("삐약!").
    // Opens on the up-beat of the bob so the whole body reads as one chirp.
    final beakOpen = math.max(0.0, math.sin(f.t * math.pi * 2)) * 0.7;
    final beakC = Offset(0, eyeY + eyeR * 1.5);
    _04beak(canvas, beakC, rx * 0.16, beakOpen);

    // --- signature: one head-feather strand curling up, swaying with sway ---
    _04tuft(canvas, -ry, rx, ry, f.sway);

    canvas.restore();

    // faint paper grain overlay
    Hand.paperGrain(canvas, Offset.zero & size, seed: 4, dots: 72);
  }

  // A stubby tucked wing pointing down the body side; [side] = -1 left / 1 right.
  void _04wing(
      Canvas c, int side, double shx, double shy, double len, double flap) {
    c.save();
    c.translate(shx, shy);
    c.rotate(side * -flap);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
          side * len * 0.92, len * 0.18, side * len * 0.26, len * 0.98)
      ..quadraticBezierTo(side * len * 0.02, len * 0.52, 0, 0)
      ..close();
    c.drawPath(path, Hand.fill(_sunDeep));
    c.drawPath(path, Hand.outline(_ink, len * 0.12));
    c.restore();
  }

  // Cracked half-eggshell cradle — the just-hatched story. A white cup that
  // hugs the body base, with a jagged cracked rim across the open top.
  void _04shell(Canvas c, double rx, double ry) {
    final cy = ry * 0.60;
    final halfW = rx * 0.85;
    final halfH = ry * 0.45;
    final rect = Rect.fromCenter(
        center: Offset(0, cy), width: halfW * 2, height: halfH * 2);
    // zigzag rim points across the opening, alternating up / down
    final zig = <Offset>[];
    const teeth = 7;
    for (var i = 0; i <= teeth; i++) {
      final tx = -halfW + (2 * halfW) * (i / teeth);
      zig.add(Offset(tx, cy + (i.isEven ? -ry * 0.07 : ry * 0.05)));
    }
    // filled cup: bottom half of the oval, closed back across the jagged rim
    final cup = Path()..moveTo(-halfW, cy);
    cup.arcTo(rect, math.pi, math.pi, false); // bottom half: left -> right
    for (var i = zig.length - 1; i >= 0; i--) {
      cup.lineTo(zig[i].dx, zig[i].dy);
    }
    cup.close();
    c.drawPath(cup, Hand.fill(const Color(0xFFFFF6E2)));
    // outline the rounded bottom, then the cracked rim on top
    final bottom = Path()..moveTo(-halfW, cy);
    bottom.arcTo(rect, math.pi, math.pi, false);
    c.drawPath(bottom, Hand.outline(_ink, 5.0));
    c.drawPath(
        Hand.roughLine(zig, wobble: 0.7, seed: 33), Hand.outline(_ink, 5.0));
  }

  // A few downy fluff ticks along the crown so the top reads feathery.
  void _04fluff(Canvas c, double rx, double ry) {
    final ink = Hand.outline(_sunDeep, 3.0);
    const xs = [-0.28, 0.0, 0.28];
    for (var i = 0; i < xs.length; i++) {
      final bx = xs[i] * rx;
      final by = -ry * (0.95 - (bx.abs() / rx) * 0.16);
      final tip = Offset(bx * 1.14, by - ry * 0.11);
      c.drawPath(
        Hand.roughLine([Offset(bx, by), tip], wobble: 0.6, seed: 50 + i),
        ink,
      );
    }
  }

  // Orange bill split into an upper + lower half; [open] (0..1) drops the lower
  // half to reveal a warm inner mouth, so the chick reads as mid-chirp.
  void _04beak(Canvas c, Offset at, double s, double open) {
    c.save();
    c.translate(at.dx, at.dy);
    final gap = s * 0.34 * open; // how far the lower bill swings down
    // inner mouth peeks through the gap (drawn first, behind the bills)
    if (open > 0.03) {
      final mouth = Path()
        ..moveTo(-s * 0.5, 0)
        ..lineTo(s * 0.5, 0)
        ..lineTo(0, s * 0.42 + gap)
        ..close();
      c.drawPath(mouth, Hand.fill(_mouth));
    }
    // upper bill
    final upper = Path()
      ..moveTo(0, -s * 0.55)
      ..lineTo(s * 0.74, 0)
      ..lineTo(-s * 0.74, 0)
      ..close();
    c.drawPath(upper, Hand.fill(_beak));
    c.drawPath(upper, Hand.outline(_beakDeep, s * 0.16));
    // lower bill, hinged open by [gap]
    final lower = Path()
      ..moveTo(-s * 0.62, gap)
      ..lineTo(s * 0.62, gap)
      ..lineTo(0, s * 0.66 + gap)
      ..close();
    c.drawPath(lower, Hand.fill(_beak));
    c.drawPath(lower, Hand.outline(_beakDeep, s * 0.16));
    c.restore();
  }

  // A little three-toed foot; leg top tucks under the body.
  void _04foot(Canvas c, double x, double topY, double s) {
    final ink = Hand.outline(_beakDeep, s * 0.17);
    final base = Offset(x, topY + s * 0.95);
    c.drawPath(Hand.roughLine([Offset(x, topY), base], wobble: 0.5, seed: 21),
        ink);
    c.drawPath(
        Hand.roughLine([base, base + Offset(-s * 0.55, s * 0.34)],
            wobble: 0.4, seed: 22),
        ink);
    c.drawPath(
        Hand.roughLine([base, base + Offset(0, s * 0.52)], wobble: 0.4, seed: 23),
        ink);
    c.drawPath(
        Hand.roughLine([base, base + Offset(s * 0.55, s * 0.34)],
            wobble: 0.4, seed: 24),
        ink);
  }

  // The signature ONE head feather — a single springy strand that curls up and
  // sways. Kept deliberately singular (per the concept) for a clean crown.
  void _04tuft(Canvas c, double headTop, double rx, double ry, double sway) {
    final baseY = headTop + 3;
    final p0 = Offset(0, baseY);
    final p1 = Offset(sway * 0.5 - rx * 0.03, baseY - ry * 0.26);
    final p2 = Offset(sway * 1.1 - rx * 0.11, baseY - ry * 0.50);
    final p3 = Offset(sway * 1.3 + rx * 0.03, baseY - ry * 0.62);
    final path = Hand.roughLine([p0, p1, p2, p3], wobble: 0.8, seed: 41);
    c.drawPath(path, Hand.outline(_ink, 6.0)); // bolder so one strand still reads
    // soft rounded bud at the tip
    c.drawCircle(p3, 4.4, Hand.fill(_ink));
  }

  @override
  bool shouldRepaint(_P04 old) => old.f.t != f.t;
}
