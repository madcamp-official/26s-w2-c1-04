// char_05_hamster — "햄찌" (Haemjji), the pouch-cheeked hamster.
//
// A crayon hamster built for tiny sizes: a round golden-cream body, small
// rounded ears with pink insides, low wide-set glossy dot eyes, a cream belly
// patch, strong rosy blush, and — the signature — two puffed cheek pouches
// (볼주머니 빵빵) that oomph as it nibbles. The look is carried by ONE clean
// thick-outlined silhouette + a few confident shapes so it still reads at 56px
// (roster thumbnail) as well as ~170px (pet home). No thin scattered marks.
//
// The face reacts to PetExpression (neutral / happy / sleepy / eating /
// excited / curious / focused): eyes + mouth change, with a drifting "zzz" when
// sleepy and a sparkle glint when excited. The idle loop still breathes / bobs
// / blinks / sways.
//
// Cuteness cues distilled from 10+ references (see [inspiration]):
//   · body barely bigger than the head, tiny short limbs (Hamtaro / Oxnard)
//   · full cheek pouches widening the lower face — the signature silhouette
//   · small rounded ears with pink inner ear (kawaii chibi hamster vectors)
//   · strong rosy blush (홍조 진하게), low wide dot eyes, tiny ω mouth
//   · golden-tan fur + cream white belly patch, warm crayon outline
//   · a sunflower seed clutched in both paws (Hamtaro seed motif)
//
// Built only on the shared charlab toolkit — no assets, no Random, no clock.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../toolkit.dart';

class Char05 extends PetCharacter {
  @override
  String get id => '05';
  @override
  String get name => '햄찌';
  @override
  String get concept => '볼주머니 빵빵한 크레용 햄스터 — 해바라기씨를 오물오물, 진한 홍조와 아기 앞니.';
  @override
  String get signature => '두 볼주머니가 오물오물 부풀었다 줄고, 손에 쥔 씨앗을 야금야금 갉으며 귀가 살랑인다.';
  @override
  List<String> get inspiration => const [
        'Hamtaro / Oxnard — body smaller than head, small ears, loves sunflower seeds',
        'Freepik "cute hamster kawaii chibi vector drawing style" — beige fur, rosy cheeks, pink inner ears',
        'Vecteezy hamster cub kawaii chibi Japanese sticker/emoji',
        'Dreamstime chibi hamster illustrations',
        'Kawaii Pen Shop 38pcs Japanese hamster stickers — chubby, shy/happy',
        'Adobe Stock cute cartoon hamster sticker mascot set',
        'iStock "hamster cheek" — full cheek pouches',
        'Kakao 햄모지 (Hammoji the hamster) emoticons',
        'Kakao 똥꼬발랄 햄스터 옴뇸 / 씰룩씰룩 햄스터 emoticon packs',
        'LINE Kibi 햄스터 이모티콘',
        'Notefolio 박은영 햄스터 캐릭터 이모티콘',
        'Kakao 햄꼬미는 미대생 hamster character',
      ];
  @override
  Color get accent => const Color(0xFFEEBE7C);

  @override
  Widget build(BuildContext context,
      {double? frozenT, PetExpression expression = PetExpression.neutral}) {
    return IdleAnimator(
      frozenT: frozenT,
      builder: (context, f) => CustomPaint(
        painter: _P05(f, expression),
        size: Size.infinite,
      ),
    );
  }
}

class _P05 extends CustomPainter {
  _P05(this.f, this.expr);
  final IdleFrame f;
  final PetExpression expr;

  static const _fur = Color(0xFFF3D9A6); // golden-cream body
  static const _furLip = Color(0xFFEFCE8E); // faint underbelly of pouches
  static const _belly = Color(0xFFFDF6E6); // cream belly patch
  static const _ink = Color(0xFF9E7C50); // warm crayon outline
  static const _inkSoft = Color(0xFF7C5F3C); // darker for face features
  static const _earPink = Color(0xFFF3B4A6); // warmed toward the coral blush
  static const _blush = Color(0xFFF0958A); // warm coral 홍조, harmonizes w/ golden fur
  static const _nose = Color(0xFFC98A7A);
  static const _mouthIn = Color(0xFFCE8575); // soft warm open-mouth interior
  static const _seed = Color(0xFF5E4326); // sunflower seed shell
  static const _glint = Color(0xFFF0A431); // warm sparkle glint (reads on cream + bg)

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Hand.paperGrain(canvas, Offset.zero & size, seed: 6, dots: 80);

    final cx = w / 2;
    final baseCy = h * 0.56 + f.bob;
    final rx = w * 0.29; // body core ~58% of stage; cheeks push it a touch wider
    final ry = w * 0.315 * f.breath; // breathe on the height

    // A gentle nibble oscillation — deterministic from f.t, kept subtle so the
    // idle feels alive without getting busy.
    final munch = math.sin(f.t * math.pi * 2 * 3);
    final sleepy = expr == PetExpression.sleepy;
    final eating = expr == PetExpression.eating;
    // Cheeks puff on the nibble; eating fills them a touch fuller still.
    final cheekPuff = 1 + munch * 0.06 + (eating ? 0.10 : 0.0);
    final seedNibble = munch * (rx * 0.045);

    // Soft ground shadow — anchors the little body.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, baseCy + ry * 1.04),
        width: rx * 1.7,
        height: ry * 0.24,
      ),
      Hand.fill(const Color(0x16000000)),
    );

    canvas.save();
    canvas.translate(cx, baseCy);

    // -- Ears (behind body) — small rounded ears with pink inner, gentle sway.
    _05ear(canvas, side: -1, rx: rx, ry: ry, sway: f.sway, twitch: munch);
    _05ear(canvas, side: 1, rx: rx, ry: ry, sway: f.sway, twitch: munch);

    // -- Cheek pouches (behind body) — soft bulges at the lower sides. Drawing
    //    them first lets the body fill+outline hide their inner edge, so the
    //    body and both cheeks merge into ONE clean, thick-outlined silhouette.
    _05cheekPouch(canvas, side: -1, rx: rx, ry: ry, puff: cheekPuff);
    _05cheekPouch(canvas, side: 1, rx: rx, ry: ry, puff: cheekPuff);

    // -- Body — a round, softly-settled golden ball.
    final body = Hand.blob(Offset.zero, rx, ry: ry, wobble: 3.0, seed: 5, squash: 0.10);
    canvas.drawPath(body, Hand.fill(_fur));
    // Soft upper sheen so the golden ball reads round and lit, not a flat disk.
    Hand.blush(canvas, Offset(-rx * 0.24, -ry * 0.42), rx * 0.60, _belly, opacity: 0.28);
    canvas.drawPath(body, Hand.outline(_ink, 5.0));

    // -- Cream belly / muzzle patch (the white tummy cue the face sits on).
    final belly = Hand.blob(
      Offset(0, ry * 0.30),
      rx * 0.50,
      ry: ry * 0.46,
      wobble: 2.0,
      seed: 12,
    );
    canvas.drawPath(belly, Hand.fill(_belly));
    canvas.drawPath(belly, Hand.outline(_furLip, 2.2));

    // -- Face --------------------------------------------------------------
    // Head-nibble — the whole face dips a hair as it chews.
    canvas.save();
    canvas.translate(0, munch * ry * 0.02);

    final eyeY = -ry * 0.08;
    final eyeDx = rx * 0.34;
    final eyeR = rx * 0.15;
    final blinking = f.blink > 0.5;
    final curious = expr == PetExpression.curious;
    final excited = expr == PetExpression.excited;
    // Curious peeks slightly up — a tiny "head tilt" feel.
    final ey = eyeY + (curious ? -ry * 0.06 : 0.0);

    // -- Eyes — the blink pulse always wins over any open-eyed expression.
    if (blinking || expr.eyesClosed) {
      // Sleeping / mid-blink → soft closed ‿ arcs.
      _05arcEye(canvas, Offset(-eyeDx, eyeY), eyeR, up: false);
      _05arcEye(canvas, Offset(eyeDx, eyeY), eyeR, up: false);
    } else if (expr == PetExpression.happy) {
      // ^_^ — happy upward arcs.
      _05arcEye(canvas, Offset(-eyeDx, eyeY), eyeR, up: true);
      _05arcEye(canvas, Offset(eyeDx, eyeY), eyeR, up: true);
    } else if (expr == PetExpression.focused) {
      // Narrowed calm eyes — short set lines.
      _05lineEye(canvas, Offset(-eyeDx, eyeY), eyeR);
      _05lineEye(canvas, Offset(eyeDx, eyeY), eyeR);
    } else {
      // neutral / curious / eating / excited → glossy dot eyes.
      final r = excited ? eyeR * 1.18 : eyeR;
      Hand.dotEye(canvas, Offset(-eyeDx, ey), r, _inkSoft);
      Hand.dotEye(canvas, Offset(eyeDx, ey), r, _inkSoft);
      if (excited) _05sparkle(canvas, Offset(rx * 0.60, -ry * 0.50), rx * 0.11);
    }

    // -- Blush on the cheeks, just under the eyes — pulses w/ nibble, brighter
    //    when happy / eating.
    var blushMul = 1.0, blushOp = 0.50;
    if (expr == PetExpression.happy) {
      blushMul = 1.25;
      blushOp = 0.60;
    } else if (eating) {
      blushMul = 1.35;
      blushOp = 0.55;
    } else if (excited) {
      blushMul = 1.15;
      blushOp = 0.55;
    }
    final blushR = rx * 0.20 * cheekPuff * blushMul;
    Hand.blush(canvas, Offset(-rx * 0.50, ry * 0.12), blushR, _blush, opacity: blushOp);
    Hand.blush(canvas, Offset(rx * 0.50, ry * 0.12), blushR, _blush, opacity: blushOp);

    // -- Little nose.
    final noseY = ry * 0.14;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, noseY), width: rx * 0.13, height: rx * 0.10),
      Hand.fill(_nose),
    );

    // -- Mouth — set by the expression.
    final mouthY = noseY + rx * 0.11;
    if (eating) {
      // Open round "o" — mid-nibble.
      final mr = rx * 0.10;
      final oc = Offset(0, mouthY + mr * 0.3);
      final rect = Rect.fromCenter(center: oc, width: mr * 1.7, height: mr * 2.1);
      canvas.drawOval(rect, Hand.fill(_mouthIn));
      canvas.drawOval(rect, Hand.outline(_inkSoft, 2.8));
    } else if (excited) {
      // Open happy grin.
      _05openSmile(canvas, Offset(0, mouthY), rx * 0.34, rx * 0.14);
    } else if (expr == PetExpression.happy) {
      // A bigger, brighter smile.
      Hand.smile(canvas, Offset(0, mouthY - rx * 0.02), rx * 0.40, rx * 0.20, _inkSoft, width: 3.4);
    } else if (sleepy) {
      // A tiny sleeping ω.
      _05mouth(canvas, at: Offset(0, mouthY), w: rx * 0.14, d: rx * 0.05);
    } else if (expr == PetExpression.focused) {
      // A small set mouth.
      canvas.drawLine(
        Offset(-rx * 0.08, mouthY),
        Offset(rx * 0.08, mouthY),
        Hand.outline(_inkSoft, 3.2),
      );
    } else {
      // neutral / curious → the gentle ω hamster mouth.
      _05mouth(canvas, at: Offset(0, mouthY), w: rx * 0.26, d: rx * (0.10 + munch * 0.02));
    }

    // Drifting "zzz" when sleeping.
    if (sleepy) _05zzz(canvas, Offset(rx * 0.42, -ry * 0.60), rx, f);

    canvas.restore(); // end head-nibble
    canvas.restore(); // end body translate

    // -- Paws + sunflower seed (in front of the belly), nibbled up and down.
    //    Hands are tucked away while sleeping.
    if (!sleepy) {
      final pawY = baseCy + ry * 0.56;
      _05paw(canvas, Offset(cx - rx * 0.22, pawY - seedNibble), rx * 0.15);
      _05paw(canvas, Offset(cx + rx * 0.22, pawY - seedNibble), rx * 0.15);
      _05seed(canvas, Offset(cx, pawY - rx * 0.12 - seedNibble), rx);
    }
  }

  // -- Parts -----------------------------------------------------------------

  void _05ear(Canvas c, {required int side, required double rx, required double ry, required double sway, double twitch = 0}) {
    c.save();
    c.translate(side * rx * 0.56, -ry * 0.84);
    c.rotate(side * 0.10 + sway * 0.02 * side + twitch * 0.04 * side);
    final outer = Hand.blob(Offset.zero, rx * 0.30, ry: rx * 0.32, wobble: 1.6, seed: 20 + side);
    c.drawPath(outer, Hand.fill(_fur));
    c.drawPath(outer, Hand.outline(_ink, 4.2));
    final inner = Hand.blob(Offset(0, rx * 0.02), rx * 0.16, ry: rx * 0.17, wobble: 0.9, seed: 30 + side);
    c.drawPath(inner, Hand.fill(_earPink));
    c.restore();
  }

  void _05cheekPouch(Canvas c, {required int side, required double rx, required double ry, required double puff}) {
    final center = Offset(side * rx * 0.80, ry * 0.16);
    final pouch = Hand.blob(
      center,
      rx * 0.36 * puff,
      ry: rx * 0.33 * puff,
      wobble: 2.0,
      seed: 40 + side,
      squash: 0.05,
    );
    c.drawPath(pouch, Hand.fill(_fur));
    c.drawPath(pouch, Hand.outline(_ink, 5.0));
  }

  // ω mouth — two soft downward humps meeting under the nose.
  void _05mouth(Canvas c, {required Offset at, required double w, required double d}) {
    final path = Path()
      ..moveTo(at.dx - w / 2, at.dy)
      ..quadraticBezierTo(at.dx - w / 4, at.dy + d, at.dx, at.dy)
      ..quadraticBezierTo(at.dx + w / 4, at.dy + d, at.dx + w / 2, at.dy);
    c.drawPath(path, Hand.outline(_inkSoft, 3.0));
  }

  // A curved eye — up:true → happy ^ arc, up:false → closed ‿ arc.
  void _05arcEye(Canvas c, Offset at, double r, {required bool up}) {
    final rect = Rect.fromCircle(center: at, radius: r);
    final start = up ? math.pi * 1.15 : math.pi * 0.15;
    c.drawArc(rect, start, math.pi * 0.7, false, Hand.outline(_inkSoft, 3.8));
  }

  // A narrowed, calm eye — a short set line (focused).
  void _05lineEye(Canvas c, Offset at, double r) {
    c.drawLine(
      at + Offset(-r * 0.8, 0),
      at + Offset(r * 0.8, 0),
      Hand.outline(_inkSoft, 3.6),
    );
  }

  // A filled open happy grin (excited).
  void _05openSmile(Canvas c, Offset at, double w, double d) {
    final path = Path()
      ..moveTo(at.dx - w / 2, at.dy)
      ..quadraticBezierTo(at.dx, at.dy + d * 1.7, at.dx + w / 2, at.dy)
      ..quadraticBezierTo(at.dx, at.dy + d * 0.35, at.dx - w / 2, at.dy)
      ..close();
    c.drawPath(path, Hand.fill(_mouthIn));
    c.drawPath(path, Hand.outline(_inkSoft, 3.0));
  }

  // A tiny sparkle glint (excited) — a 4-point star + white center.
  void _05sparkle(Canvas c, Offset at, double s) {
    final p = Hand.outline(_glint, 2.6);
    c.drawLine(at + Offset(-s, 0), at + Offset(s, 0), p);
    c.drawLine(at + Offset(0, -s), at + Offset(0, s), p);
    final q = Hand.outline(_glint, 1.8);
    c.drawLine(at + Offset(-s * 0.55, -s * 0.55), at + Offset(s * 0.55, s * 0.55), q);
    c.drawLine(at + Offset(-s * 0.55, s * 0.55), at + Offset(s * 0.55, -s * 0.55), q);
    c.drawCircle(at, s * 0.16, Hand.fill(Colors.white));
  }

  // Drifting "zzz" near the head — three z's rising up-right, bobbing with f.
  void _05zzz(Canvas c, Offset at, double s, IdleFrame f) {
    final drift = math.sin(f.t * math.pi * 2);
    for (var i = 0; i < 3; i++) {
      final t = i / 2.0;
      final fs = s * (0.14 + t * 0.07);
      final pos = at +
          Offset(s * (t * 0.16), -s * (t * 0.22)) +
          Offset(0, drift * s * 0.03);
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            color: _inkSoft,
            fontSize: fs,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, pos);
    }
  }

  void _05paw(Canvas c, Offset at, double r) {
    final paw = Hand.blob(at, r, ry: r * 0.9, wobble: 1.4, seed: 60 + at.dx.round());
    c.drawPath(paw, Hand.fill(_fur));
    c.drawPath(paw, Hand.outline(_ink, 4.4));
  }

  void _05seed(Canvas c, Offset at, double s) {
    c.save();
    c.translate(at.dx, at.dy);
    final hw = s * 0.15, hh = s * 0.22;
    final seed = Path()
      ..moveTo(0, -hh)
      ..quadraticBezierTo(hw, -hh * 0.25, hw * 0.72, hh * 0.55)
      ..quadraticBezierTo(0, hh, -hw * 0.72, hh * 0.55)
      ..quadraticBezierTo(-hw, -hh * 0.25, 0, -hh)
      ..close();
    c.drawPath(seed, Hand.fill(_seed));
    c.drawPath(seed, Hand.outline(_inkSoft, 2.8));
    c.restore();
  }

  @override
  bool shouldRepaint(_P05 old) => old.f.t != f.t || old.expr != expr;
}
