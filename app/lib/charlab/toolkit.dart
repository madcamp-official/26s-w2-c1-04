// Charlab — a hand-drawn character rendering toolkit.
//
// Everything a cute vector pet needs to look *drawn by hand* and *breathe*:
//   · deterministic value noise (no Random) → wobbly, imperfect lines
//   · wobbly blobs / rough strokes / soft thick outlines (warm, not pure black)
//   · blush, dot eyes, arc mouths, faint paper grain
//   · IdleAnimator — a 4s loop giving each frame a breath / bob / blink / sway
//
// Characters extend [PetCharacter] and paint through these helpers so ten
// different authors still share one consistent "hand". No assets, no network,
// no DateTime.now(), no Random — screenshots are reproducible and it drops
// straight into the app's pet renderer.

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ===========================================================================
// Deterministic value noise — the source of every wobble.
// ===========================================================================

/// Smooth 1-D value noise in roughly [-1, 1], seeded and repeatable. Uses a
/// hash of the integer lattice with smoothstep interpolation — no Random, so
/// the same (x, seed) always wobbles the same way.
double handNoise(double x, {int seed = 0}) {
  final xi = x.floor();
  final xf = x - xi;
  final u = xf * xf * (3 - 2 * xf); // smoothstep
  final a = _hash(xi, seed);
  final b = _hash(xi + 1, seed);
  return (a + (b - a) * u) * 2 - 1;
}

double _hash(int i, int seed) {
  var h = (i * 374761393 + seed * 668265263) & 0x7fffffff;
  h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff;
  return (h & 0xffff) / 0xffff; // 0..1
}

// ===========================================================================
// Hand-drawn painting helpers.
// ===========================================================================

class Hand {
  /// A warm, soft, thick outline paint (never pure black).
  static Paint outline(Color color, double width) => Paint()
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

  static Paint fill(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  /// Build a closed wobbly blob path around [center]. [radius] is the base
  /// radius; [ry] lets you make eggs/ovals. [wobble] is the max radial jitter
  /// in px; higher [seed] varies the silhouette. [squash] (>0) flattens the
  /// bottom a touch, the way a soft body settles.
  static Path blob(
    Offset center,
    double radius, {
    double? ry,
    double wobble = 4,
    int seed = 1,
    double squash = 0.0,
    int samples = 48,
  }) {
    final rx = radius;
    final vy = ry ?? radius;
    final pts = <Offset>[];
    for (var i = 0; i < samples; i++) {
      final a = (i / samples) * math.pi * 2;
      final n = handNoise(i * 0.35, seed: seed) * wobble;
      var px = math.cos(a) * (rx + n);
      var py = math.sin(a) * (vy + n);
      if (squash > 0 && py > 0) py *= (1 - squash * (py / vy));
      pts.add(center + Offset(px, py));
    }
    return _smoothClosed(pts);
  }

  /// A rough open stroke through [points] — each point nudged by noise so the
  /// line reads as pen-on-paper, not a ruler.
  static Path roughLine(List<Offset> points,
      {double wobble = 1.6, int seed = 7}) {
    final jittered = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final nx = handNoise(i * 0.7, seed: seed) * wobble;
      final ny = handNoise(i * 0.7 + 100, seed: seed) * wobble;
      jittered.add(points[i] + Offset(nx, ny));
    }
    return _smoothOpen(jittered);
  }

  /// Soft cheek blush — a low-opacity radial dab.
  static void blush(Canvas c, Offset at, double r, Color color,
      {double opacity = 0.45}) {
    final shader = RadialGradient(
      colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
    ).createShader(Rect.fromCircle(center: at, radius: r));
    c.drawCircle(at, r, Paint()..shader = shader);
  }

  /// A round dot eye (with an optional tiny catch-light).
  static void dotEye(Canvas c, Offset at, double r, Color ink,
      {bool glossy = true}) {
    c.drawCircle(at, r, fill(ink));
    if (glossy) {
      c.drawCircle(
        at + Offset(-r * 0.32, -r * 0.34),
        r * 0.30,
        fill(Colors.white.withValues(alpha: 0.9)),
      );
    }
  }

  /// A closed / blinking eye — a small downward arc.
  static void blinkEye(Canvas c, Offset at, double r, Color ink,
      {double width = 3}) {
    final rect = Rect.fromCircle(center: at, radius: r);
    c.drawArc(rect, math.pi * 0.15, math.pi * 0.7, false, outline(ink, width));
  }

  /// A gentle smile arc centered at [at].
  static void smile(Canvas c, Offset at, double w, double depth, Color ink,
      {double width = 3}) {
    final path = Path()
      ..moveTo(at.dx - w / 2, at.dy)
      ..quadraticBezierTo(at.dx, at.dy + depth, at.dx + w / 2, at.dy);
    c.drawPath(path, outline(ink, width));
  }

  /// Faint paper grain over [rect] — a scatter of low-opacity flecks that reads
  /// as texture, deterministic per [seed].
  static void paperGrain(Canvas c, Rect rect, {int seed = 3, int dots = 90}) {
    final p = Paint()..color = const Color(0x08000000);
    for (var i = 0; i < dots; i++) {
      final x = rect.left + _hash(i, seed) * rect.width;
      final y = rect.top + _hash(i + 555, seed) * rect.height;
      c.drawCircle(Offset(x, y), 0.8, p);
    }
  }

  // -- path smoothing --------------------------------------------------------

  static Path _smoothClosed(List<Offset> p) {
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

  static Path _smoothOpen(List<Offset> p) {
    final path = Path();
    if (p.isEmpty) return path;
    path.moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final cur = p[i];
      final next = p[i + 1];
      final mid = (cur + next) / 2;
      path.quadraticBezierTo(cur.dx, cur.dy, mid.dx, mid.dy);
    }
    path.lineTo(p.last.dx, p.last.dy);
    return path;
  }
}

// ===========================================================================
// Idle animation — one loop → a breath, a bob, an occasional blink, a sway.
// ===========================================================================

// ===========================================================================
// Expression — how the pet's face reads, driven by what it's doing.
// ===========================================================================

/// The pet's current mood/pose. Characters read this to change eyes + mouth
/// (and small extras like zzz / sparkles). Kept independent of the app's
/// activity enum so the toolkit has no app dependency — the app maps its
/// PetActivityKind onto these.
enum PetExpression {
  /// Default calm face — open dot eyes, gentle smile.
  neutral,

  /// Happy / greeted — curved ^_^ eyes, bigger smile, brighter blush.
  happy,

  /// Sleeping — closed eyes, small mouth, a drifting "zzz".
  sleepy,

  /// Eating — an open little "o" mouth, cheeks a touch fuller.
  eating,

  /// Excited / playing — wide sparkly eyes, open smile.
  excited,

  /// Curious / walking — one raised brow feel, looking up a little.
  curious,

  /// Focused / drawing — narrowed calm eyes, a small set mouth.
  focused,
}

extension PetExpressionX on PetExpression {
  bool get eyesClosed => this == PetExpression.sleepy;
  bool get eyesHappy => this == PetExpression.happy || this == PetExpression.excited;
  bool get mouthOpen => this == PetExpression.eating || this == PetExpression.excited;
}

/// The state of an idle loop at one instant. Characters read these to move.
class IdleFrame {
  const IdleFrame({
    required this.t,
    required this.breath,
    required this.bob,
    required this.blink,
    required this.sway,
  });

  /// Raw loop phase 0..1.
  final double t;

  /// Breathing scale factor, ~0.985..1.02 (multiply body height).
  final double breath;

  /// Vertical bob offset in px (small, e.g. -3..3).
  final double bob;

  /// Eye-closed amount 0 (open) .. 1 (shut) — a short pulse each loop.
  final double blink;

  /// Slow side sway in px for accessories / ears.
  final double sway;
}

/// Drives a [builder] with a live [IdleFrame]. Pass [frozenT] to hold a fixed
/// phase — used for deterministic QA screenshots (e.g. `?t=0.42`).
class IdleAnimator extends StatefulWidget {
  const IdleAnimator({
    super.key,
    required this.builder,
    this.period = const Duration(milliseconds: 3800),
    this.frozenT,
  });

  final Widget Function(BuildContext, IdleFrame) builder;
  final Duration period;
  final double? frozenT;

  @override
  State<IdleAnimator> createState() => _IdleAnimatorState();
}

class _IdleAnimatorState extends State<IdleAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    if (widget.frozenT == null) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  IdleFrame _frameFor(double t) {
    final tau = t * math.pi * 2;
    final breath = 1 + math.sin(tau) * 0.018;
    final bob = math.sin(tau) * 2.4;
    // A blink is a brief closed pulse near the end of the loop.
    final blink = t > 0.86 ? math.sin((t - 0.86) / 0.14 * math.pi) : 0.0;
    final sway = math.sin(tau * 0.5) * 3.0;
    return IdleFrame(t: t, breath: breath, bob: bob, blink: blink, sway: sway);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frozenT != null) {
      return widget.builder(context, _frameFor(widget.frozenT!));
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => widget.builder(context, _frameFor(_c.value)),
    );
  }
}

// ===========================================================================
// The contract every character implements.
// ===========================================================================

abstract class PetCharacter {
  /// Two-digit id, e.g. "03".
  String get id;

  /// Display name, e.g. "모찌".
  String get name;

  /// One-line concept.
  String get concept;

  /// The one signature move / detail of its idle animation.
  String get signature;

  /// Where the look was learned from (searched references), for the report.
  List<String> get inspiration => const [];

  /// A representative accent colour (for the gallery chip).
  Color get accent;

  /// Paint the character to fit [size], animated. Pass [frozenT] to freeze the
  /// idle loop for a deterministic still, and [expression] to set the face/pose.
  Widget build(BuildContext context,
      {double? frozenT, PetExpression expression = PetExpression.neutral});
}
