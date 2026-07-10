// design_09_mixtape_reels — "Mixtape · Side B".
//
// A warm 70s cassette. Spinning reels, a felt-pen J-card, Dymo-embosser tape
// labels, VU needles and analog transport buttons. The take-up reel physically
// winds fuller as you REC shared memories onto Side B; drag a reel to scrub
// through days with a fast-forward whirr.
//
// Everything except `Design09` is private with a `_D09` / `_d09` prefix.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ------------------------------------------------------------------- palette
const Color _d09Cream = Color(0xFFEDE0C8);
const Color _d09Paper = Color(0xFFF4EAD6);
const Color _d09DeepCream = Color(0xFFE0CFAE);
const Color _d09Orange = Color(0xFFE07B39);
const Color _d09OrangeDeep = Color(0xFFC85E22);
const Color _d09Walnut = Color(0xFF5B3A21);
const Color _d09WalnutDark = Color(0xFF3E2716);
const Color _d09Plastic = Color(0xFFB7BCBB);
const Color _d09PlasticDark = Color(0xFF8A9190);
const Color _d09Felt = Color(0xFF211C18);
const Color _d09Rust = Color(0xFF9C3B1B);

Color _d09a(Color c, double o) => c.withValues(alpha: o);

// ============================================================== the variant
class Design09 extends DesignVariant {
  @override
  String get id => '09';
  @override
  String get name => 'Mixtape · Side B';
  @override
  String get concept =>
      '따뜻한 70년대 카세트 — 도는 릴, VU 미터, 펠트펜 J-카드. 테이프 히스와 함께 하루가 감긴다.';
  @override
  String get signature =>
      'REC & 되감기 — 릴을 드래그해 날짜를 스크럽하고, 낙서에 REC를 눌러 Side B에 녹음하면 감기 릴이 실제로 차오른다.';
  @override
  String get inspiration =>
      '70s TDK/Maxell 카세트, Dymo 엠보서 라벨 테이프, 아날로그 데크의 VU 미터와 트랜스포트 버튼.';
  @override
  Color get accent => _d09Orange;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return switch (screen) {
      HeroScreen.drawSend => _D09DrawSend(data: data),
      HeroScreen.petHome => _D09PetHome(data: data),
      HeroScreen.memoryAlbum => _D09Album(data: data),
    };
  }
}

// ============================================================ shared pieces

/// Deterministic tape-hiss speckle so the J-card feels like grainy paper.
class _D09HissPainter extends CustomPainter {
  final Color tint;
  const _D09HissPainter({required this.tint});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final count = (size.width * size.height / 520).clamp(40, 900).toInt();
    for (int i = 0; i < count; i++) {
      // hash-based pseudo-random — deterministic, no Random().
      final a = math.sin(i * 12.9898) * 43758.5453;
      final b = math.sin(i * 78.233) * 12543.1234;
      final x = (a - a.floorToDouble()) * size.width;
      final y = (b - b.floorToDouble()) * size.height;
      final r = (math.sin(i * 3.7) * 0.5 + 0.5) * 0.9 + 0.2;
      p.color = _d09a(tint, 0.03 + (math.sin(i) * 0.5 + 0.5) * 0.05);
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _D09HissPainter old) => false;
}

/// The wound-tape reel. Draws a plastic hub with 6 spokes over a brown coil
/// whose radius grows with [fill]. Parent rotates it via RotationTransition.
class _D09ReelPainter extends CustomPainter {
  final double fill; // 0..1 amount of tape wound on
  const _D09ReelPainter({required this.fill});
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final hubR = r * 0.34;
    final maxR = r * 0.94;
    final tapeR = hubR + (maxR - hubR) * fill.clamp(0.0, 1.0);

    // outer plastic window ring
    canvas.drawCircle(c, r, Paint()..color = _d09a(_d09PlasticDark, 0.55));
    canvas.drawCircle(c, r * 0.97, Paint()..color = _d09a(Colors.black, 0.25));

    // wound magnetic tape (walnut coil) + concentric layer rings
    canvas.drawCircle(c, tapeR, Paint()..color = _d09WalnutDark);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    double rr = hubR + 2;
    int k = 0;
    while (rr < tapeR) {
      ring.color = _d09a(k.isEven ? _d09Rust : Colors.black, 0.22);
      canvas.drawCircle(c, rr, ring);
      rr += 2.4;
      k++;
    }
    // glossy edge on the coil
    canvas.drawCircle(
        c, tapeR, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = _d09a(_d09Orange, 0.5));

    // plastic hub
    canvas.drawCircle(c, hubR, Paint()..color = _d09Plastic);
    canvas.drawCircle(
        c, hubR, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _d09a(Colors.white, 0.7));

    // 6 sprocket spokes
    final spoke = Paint()..color = _d09Walnut;
    for (int i = 0; i < 6; i++) {
      final ang = i * math.pi / 3;
      final path = Path();
      final w = hubR * 0.16;
      final dx = math.cos(ang);
      final dy = math.sin(ang);
      final nx = -dy * w;
      final ny = dx * w;
      final inner = hubR * 0.28;
      final outer = hubR * 1.12;
      path.moveTo(c.dx + dx * inner + nx, c.dy + dy * inner + ny);
      path.lineTo(c.dx + dx * outer + nx, c.dy + dy * outer + ny);
      path.lineTo(c.dx + dx * outer - nx, c.dy + dy * outer - ny);
      path.lineTo(c.dx + dx * inner - nx, c.dy + dy * inner - ny);
      path.close();
      canvas.drawPath(path, spoke);
    }
    // center hole
    canvas.drawCircle(c, hubR * 0.3, Paint()..color = _d09Felt);
  }

  @override
  bool shouldRepaint(covariant _D09ReelPainter old) => old.fill != fill;
}

/// A self-spinning reel with an animated [fill] level.
class _D09Reel extends StatefulWidget {
  final double fill;
  final double size;
  final Duration period;
  final bool clockwise;
  const _D09Reel({
    required this.fill,
    required this.size,
    this.period = const Duration(seconds: 4),
    this.clockwise = true,
  });
  @override
  State<_D09Reel> createState() => _D09ReelState();
}

class _D09ReelState extends State<_D09Reel> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: widget.fill),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (_, f, __) => RotationTransition(
        turns: widget.clockwise ? _c : ReverseAnimation(_c),
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _D09ReelPainter(fill: f),
        ),
      ),
    );
  }
}

/// Dymo-embosser tape label: dark tape strip, punched light uppercase letters.
class _D09Dymo extends StatelessWidget {
  final String text;
  final Color tape;
  final Color ink;
  final double size;
  final double tilt;
  const _D09Dymo(
    this.text, {
    this.tape = _d09WalnutDark,
    this.ink = _d09Cream,
    this.size = 12,
    this.tilt = 0,
  });
  @override
  Widget build(BuildContext context) {
    final label = Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.7, vertical: size * 0.34),
      decoration: BoxDecoration(
        color: tape,
        borderRadius: BorderRadius.circular(size * 0.4),
        boxShadow: [
          BoxShadow(color: _d09a(Colors.black, 0.28), blurRadius: 3, offset: const Offset(0, 2)),
        ],
        border: Border(top: BorderSide(color: _d09a(Colors.white, 0.14), width: 1)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: ink,
          fontSize: size,
          height: 1.0,
          fontWeight: FontWeight.w800,
          letterSpacing: size * 0.18,
        ),
      ),
    );
    return tilt == 0 ? label : Transform.rotate(angle: tilt, child: label);
  }
}

/// Felt-marker handwriting style.
TextStyle _d09Felt09({double size = 20, Color color = _d09Felt, FontWeight w = FontWeight.w800}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: w,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.3,
      height: 1.05,
    );

/// Small analog VU needle meter.
class _D09Vu extends StatelessWidget {
  final double value; // 0..1
  final String label;
  final double width;
  const _D09Vu({required this.value, required this.label, this.width = 150});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF7EFCF), Color(0xFFE9D7A6)],
        ),
        border: Border.all(color: _d09WalnutDark, width: 1.4),
        boxShadow: [
          BoxShadow(color: _d09a(Colors.black, 0.2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            width: double.infinity,
            child: CustomPaint(painter: _D09VuPainter(value: value.clamp(0.0, 1.0))),
          ),
          const SizedBox(height: 2),
          _D09Dymo(label, size: 8, tape: _d09Walnut),
        ],
      ),
    );
  }
}

class _D09VuPainter extends CustomPainter {
  final double value;
  const _D09VuPainter({required this.value});
  @override
  void paint(Canvas canvas, Size size) {
    final pivot = Offset(size.width / 2, size.height * 1.02);
    final radius = size.height * 0.94;
    // arc scale
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _d09a(_d09Walnut, 0.7);
    final rect = Rect.fromCircle(center: pivot, radius: radius);
    const start = math.pi * 1.18;
    const sweep = math.pi * 0.64;
    canvas.drawArc(rect, start, sweep, false, arc);
    // red overload zone
    final red = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _d09Rust;
    canvas.drawArc(rect, start + sweep * 0.72, sweep * 0.28, false, red);
    // ticks
    final tick = Paint()
      ..strokeWidth = 1.2
      ..color = _d09a(_d09Walnut, 0.6);
    for (int i = 0; i <= 6; i++) {
      final a = start + sweep * (i / 6);
      final o1 = pivot + Offset(math.cos(a) * radius, math.sin(a) * radius);
      final o2 = pivot + Offset(math.cos(a) * (radius - 5), math.sin(a) * (radius - 5));
      canvas.drawLine(o1, o2, tick);
    }
    // needle
    final a = start + sweep * value;
    final tip = pivot + Offset(math.cos(a) * (radius - 3), math.sin(a) * (radius - 3));
    canvas.drawLine(
        pivot, tip, Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = _d09Felt);
    canvas.drawCircle(pivot, 3, Paint()..color = _d09Felt);
  }

  @override
  bool shouldRepaint(covariant _D09VuPainter old) => old.value != value;
}

/// Chunky analog transport / deck button.
class _D09Transport extends StatelessWidget {
  final String glyph;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _D09Transport({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.color = _d09Plastic,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 54,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_d09a(Colors.white, 0.55), color],
              ),
              border: Border.all(color: _d09WalnutDark, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: _d09a(Colors.black, 0.3),
                  blurRadius: 3,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(glyph,
                style: const TextStyle(
                    fontSize: 16,
                    color: _d09Felt,
                    fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(height: 4),
        _D09Dymo(label, size: 8, tape: _d09Walnut),
      ],
    );
  }
}

class _D09Screw extends StatelessWidget {
  const _D09Screw();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _d09PlasticDark,
        border: Border.all(color: _d09WalnutDark, width: 1),
      ),
      child: const Center(
        child: Text('+', style: TextStyle(fontSize: 9, height: 1, color: _d09Felt, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

/// The signature cassette shell — reels + tape window + label band.
class _D09Cassette extends StatelessWidget {
  final double supplyFill;
  final double takeUpFill;
  final String sideLabel;
  final String feltTitle;
  final Widget? window; // optional overlay inside the tape window (e.g. the pet)
  const _D09Cassette({
    required this.supplyFill,
    required this.takeUpFill,
    required this.sideLabel,
    required this.feltTitle,
    this.window,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCED2D1), Color(0xFF9AA2A1)],
        ),
        border: Border.all(color: _d09WalnutDark, width: 2),
        boxShadow: [
          BoxShadow(color: _d09a(Colors.black, 0.32), blurRadius: 14, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // corner screws + side label
          Row(
            children: [
              const _D09Screw(),
              const Spacer(),
              _D09Dymo(sideLabel, size: 9, tape: _d09Orange, ink: Colors.white),
              const Spacer(),
              const _D09Screw(),
            ],
          ),
          const SizedBox(height: 8),
          // J-card felt title band
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _d09Paper,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _d09a(_d09Walnut, 0.4)),
            ),
            child: Row(
              children: [
                Container(width: 14, height: 14, color: _d09Orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(feltTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _d09Felt09(size: 15, color: _d09Rust)),
                ),
                Container(width: 26, height: 3, color: _d09Felt),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // the tape window with two reels + tape span
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _d09a(_d09Felt, 0.82),
              border: Border.all(color: _d09a(Colors.white, 0.14)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _D09Reel(fill: supplyFill, size: 78, period: const Duration(seconds: 5)),
                    _D09Reel(fill: takeUpFill, size: 78, period: const Duration(seconds: 3), clockwise: false),
                  ],
                ),
                // tape span between reels
                Positioned(
                  left: 60,
                  right: 60,
                  child: Container(height: 3, color: _d09a(_d09Rust, 0.9)),
                ),
                if (window != null) window!,
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const _D09Screw(),
              const Spacer(),
              // write-protect tabs
              Container(width: 16, height: 8, color: _d09WalnutDark),
              const SizedBox(width: 22),
              Container(width: 16, height: 8, color: _d09WalnutDark),
              const Spacer(),
              const _D09Screw(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom top bar shaped like a walnut deck faceplate.
class _D09Deck extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? trailing;
  const _D09Deck({required this.leading, required this.title, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B4527), _d09Walnut],
        ),
        boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 10),
          Expanded(child: title),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class _D09DeckIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _D09DeckIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFFD9DCDB), _d09PlasticDark]),
          border: Border.all(color: _d09WalnutDark, width: 1.5),
        ),
        child: Icon(icon, size: 20, color: _d09Felt),
      ),
    );
  }
}

/// Bottom transport nav (펫키우기 / 사진첩 / 소통).
class _D09Nav extends StatelessWidget {
  final int current;
  const _D09Nav({required this.current});
  @override
  Widget build(BuildContext context) {
    const items = [
      ('◼', '펫키우기'),
      ('▮▮', '사진첩'),
      ('▶', '소통'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_d09Walnut, _d09WalnutDark],
        ),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < items.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(
                      colors: i == current
                          ? [_d09Orange, _d09OrangeDeep]
                          : [_d09a(Colors.white, 0.5), _d09Plastic],
                    ),
                    border: Border.all(color: _d09WalnutDark, width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(items[i].$1,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: i == current ? Colors.white : _d09Felt)),
                ),
                const SizedBox(height: 4),
                _D09Dymo(items[i].$2, size: 8, tape: i == current ? _d09Orange : _d09WalnutDark),
              ],
            ),
        ],
      ),
    );
  }
}

// ================================================================= DRAW & SEND
class _D09DrawSend extends StatefulWidget {
  final AppData data;
  const _D09DrawSend({required this.data});
  @override
  State<_D09DrawSend> createState() => _D09DrawSendState();
}

class _D09DrawSendState extends State<_D09DrawSend> {
  int pen = 1;
  double thickness = 6;
  SendMode mode = SendMode.normal;
  double takeUp = 0.28;
  String? flash;

  void _rec() {
    setState(() {
      takeUp = (takeUp + 0.14).clamp(0.0, 1.0);
      flash = mode == SendMode.disappearing ? 'Side B ▸ 5초 뒤 지워짐 ●' : 'Side B에 녹음됨 ●';
    });
  }

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    return Scaffold(
      backgroundColor: _d09Cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _D09Deck(
              leading: _D09DeckIcon(icon: Icons.chevron_left_rounded, onTap: () {}),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _D09Dymo('TO ▸ ${couple.partnerNickname}', size: 11, tape: _d09Orange, ink: Colors.white),
                  const SizedBox(height: 3),
                  Text('스트릭 ${couple.streakDays}일 · REC READY',
                      style: TextStyle(fontSize: 10, color: _d09a(_d09Cream, 0.8), letterSpacing: 1)),
                ],
              ),
              trailing: GestureDetector(
                onTap: _rec,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(colors: [Color(0xFFF0483B), _d09Rust]),
                    border: Border.all(color: _d09WalnutDark, width: 1.5),
                    boxShadow: [BoxShadow(color: _d09a(_d09Rust, 0.6), blurRadius: 8)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.fiber_manual_record, size: 12, color: Colors.white),
                    SizedBox(width: 5),
                    Text('REC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ]),
                ),
              ),
            ),
            // reel deck strip showing the take-up filling as you REC
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _d09a(_d09Felt, 0.9),
                  border: Border.all(color: _d09WalnutDark, width: 2),
                ),
                child: Row(
                  children: [
                    _D09Reel(fill: 0.9 - takeUp * 0.5, size: 56, period: const Duration(seconds: 5)),
                    Expanded(
                      child: Column(
                        children: [
                          Container(height: 2, color: _d09a(_d09Rust, 0.8)),
                          const SizedBox(height: 8),
                          _D09Dymo('SIDE B · 00:${(takeUp * 60).round().toString().padLeft(2, '0')}',
                              size: 9, tape: _d09Orange, ink: Colors.white),
                        ],
                      ),
                    ),
                    _D09Reel(fill: takeUp, size: 56, period: const Duration(seconds: 3), clockwise: false),
                  ],
                ),
              ),
            ),
            // the J-card canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _d09Paper,
                    border: Border.all(color: _d09Walnut, width: 2),
                    boxShadow: [BoxShadow(color: _d09a(Colors.black, 0.15), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(painter: const _D09HissPainter(tint: _d09Walnut)),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 12,
                        child: _D09Dymo('J-CARD', size: 8, tape: _d09Walnut),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.rotate(
                              angle: -0.04,
                              child: Text('여기에 낙서하기',
                                  style: _d09Felt09(size: 26, color: _d09a(_d09Felt, 0.35))),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 30,
                              height: thickness.clamp(2.0, 20.0),
                              decoration: BoxDecoration(
                                color: demoPenColors[pen],
                                borderRadius: BorderRadius.circular(thickness),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (flash != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 14,
                          child: Center(
                            child: _D09Dymo(flash!, size: 10, tape: _d09Rust, ink: Colors.white, tilt: -0.02),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // controls
            _controls(),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_d09DeepCream, _d09Cream],
        ),
        border: Border(top: BorderSide(color: _d09Walnut, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          // felt pen tray
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _d09a(_d09Walnut, 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _d09a(_d09Walnut, 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < demoPenColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => pen = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      transform: Matrix4.translationValues(0, pen == i ? -6 : 0, 0),
                      width: 26,
                      child: Column(
                        children: [
                          Container(
                            width: 16,
                            height: 20,
                            decoration: BoxDecoration(
                              color: demoPenColors[i],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              boxShadow: pen == i
                                  ? [BoxShadow(color: _d09a(demoPenColors[i], 0.6), blurRadius: 6)]
                                  : null,
                            ),
                          ),
                          Container(width: 20, height: 22, color: _d09Walnut),
                          SizedBox(
                            width: 20,
                            height: 8,
                            child: CustomPaint(
                              painter: _D09NibPainter(color: _d09WalnutDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // thickness — styled as tape-head width dial
          Row(
            children: [
              _D09Dymo('WIDTH', size: 9, tape: _d09Walnut),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _d09Orange,
                    inactiveTrackColor: _d09a(_d09Walnut, 0.3),
                    thumbColor: _d09Rust,
                    trackHeight: 4,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: thickness,
                    min: 1,
                    max: 20,
                    onChanged: (v) => setState(() => thickness = v),
                  ),
                ),
              ),
              Text('${thickness.round()}px',
                  style: _d09Felt09(size: 13, color: _d09Rust)),
            ],
          ),
          const SizedBox(height: 6),
          // mode toggle A/B
          Row(
            children: [
              for (final m in SendMode.values)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => mode = m),
                    child: Container(
                      margin: EdgeInsets.only(right: m == SendMode.normal ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: mode == m
                              ? [_d09Orange, _d09OrangeDeep]
                              : [_d09a(Colors.white, 0.5), _d09Plastic],
                        ),
                        border: Border.all(color: _d09WalnutDark, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Text(m == SendMode.normal ? 'A' : 'B',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: mode == m ? Colors.white : _d09Felt)),
                          Text(m.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: mode == m ? Colors.white : _d09Felt)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(mode.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: _d09a(_d09Felt, 0.7), fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          // bottom transport actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _D09Transport(glyph: '⏏', label: '갤러리', onTap: () {}),
              _D09Transport(glyph: '◉', label: '사진', onTap: () {}),
              _D09Transport(glyph: '››', label: '찌르기', onTap: () {}, color: _d09Cream),
            ],
          ),
        ],
      ),
    );
  }
}

class _D09NibPainter extends CustomPainter {
  final Color color;
  const _D09NibPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _D09NibPainter old) => false;
}

// ==================================================================== PET HOME
class _D09PetHome extends StatefulWidget {
  final AppData data;
  const _D09PetHome({required this.data});
  @override
  State<_D09PetHome> createState() => _D09PetHomeState();
}

class _D09PetHomeState extends State<_D09PetHome> {
  bool patted = false;
  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    final hat = equipped.where((i) => i.category == '모자').toList();
    return Scaffold(
      backgroundColor: _d09Cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _D09Deck(
              leading: _D09DeckIcon(icon: Icons.chevron_left_rounded, onTap: () {}),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _D09Dymo('${pet.name} · LV.${pet.level}', size: 12, tape: _d09Orange, ink: Colors.white),
                  const SizedBox(height: 3),
                  Text('AI가 우리 그림체를 학습 중',
                      style: TextStyle(fontSize: 10, color: _d09a(_d09Cream, 0.8), letterSpacing: 0.5)),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _d09Paper,
                  border: Border.all(color: _d09WalnutDark, width: 1.4),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text('${pet.coins}', style: _d09Felt09(size: 15, color: _d09Rust)),
                ]),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    // the pet living inside the cassette window
                    GestureDetector(
                      onTap: () => setState(() => patted = !patted),
                      child: _D09Cassette(
                        supplyFill: 0.55,
                        takeUpFill: pet.growth,
                        sideLabel: 'MONG-TAPE',
                        feltTitle: '${pet.name}와 함께한 ${widget.data.couple.streakDays}일',
                        window: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hat.isNotEmpty)
                              Text(hat.first.emoji, style: const TextStyle(fontSize: 26)),
                            AnimatedScale(
                              scale: patted ? 1.12 : 1.0,
                              duration: const Duration(milliseconds: 180),
                              child: Text(pet.moodEmoji, style: const TextStyle(fontSize: 60)),
                            ),
                            // equipped props as stickers
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final e in equipped.where((i) => i.category != '모자'))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: Text(e.emoji, style: const TextStyle(fontSize: 18)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // speech from PAT
                    AnimatedOpacity(
                      opacity: patted ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _d09Paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _d09Rust, width: 1.5),
                        ),
                        child: Row(children: [
                          const Text('🔊', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('"${pet.speech}"', style: _d09Felt09(size: 15, color: _d09Rust)),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(patted ? '몽이가 대답했어요' : '카세트를 눌러 쓰다듬기',
                        style: TextStyle(fontSize: 11, color: _d09a(_d09Felt, 0.6), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    // growth gauges — VU meter + tape fill bar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _D09Vu(value: pet.growth, label: 'GROWTH', width: 128),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _D09Dymo('NEXT LV.${pet.level + 1}', size: 9, tape: _d09Walnut),
                              const SizedBox(height: 8),
                              _D09TapeBar(value: pet.growth),
                              const SizedBox(height: 6),
                              Text('다음 레벨까지 ${(pet.growth * 100).round()}%',
                                  style: _d09Felt09(size: 14, color: _d09Felt)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // store
                    Row(
                      children: [
                        _D09Dymo('STORE · 스토어', size: 10, tape: _d09Orange, ink: Colors.white),
                        const Spacer(),
                        Text('전체보기 ▸', style: TextStyle(fontSize: 11, color: _d09Rust, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 112,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pet.store.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _D09StoreTile(item: pet.store[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _D09Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

class _D09TapeBar extends StatelessWidget {
  final double value;
  const _D09TapeBar({required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: _d09a(_d09Felt, 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _d09WalnutDark, width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (_, c) => Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: c.maxWidth * value.clamp(0.0, 1.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_d09Orange, _d09OrangeDeep]),
                borderRadius: BorderRadius.all(Radius.circular(7)),
              ),
            ),
            Row(
              children: List.generate(
                14,
                (_) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                    color: _d09a(Colors.white, 0.12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _D09StoreTile extends StatelessWidget {
  final PetItem item;
  const _D09StoreTile({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_d09Paper, _d09DeepCream],
        ),
        border: Border.all(
          color: item.equipped ? _d09Orange : _d09a(_d09Walnut, 0.4),
          width: item.equipped ? 2.4 : 1.4,
        ),
        boxShadow: [BoxShadow(color: _d09a(Colors.black, 0.12), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: _D09Dymo(item.category, size: 7, tape: _d09Walnut),
          ),
          Text(item.emoji, style: const TextStyle(fontSize: 30)),
          if (item.owned)
            _D09Dymo(item.equipped ? '착용중' : '보유', size: 8, tape: item.equipped ? _d09Orange : _d09Walnut, ink: Colors.white)
          else
            Text('🪙${item.price}', style: _d09Felt09(size: 13, color: _d09Rust)),
        ],
      ),
    );
  }
}

// ==================================================================== ALBUM
class _D09Album extends StatefulWidget {
  final AppData data;
  const _D09Album({required this.data});
  @override
  State<_D09Album> createState() => _D09AlbumState();
}

class _D09AlbumState extends State<_D09Album> {
  bool byDate = true;
  DoodleType? filter;
  int scrub = 0;
  double _accum = 0;
  final Set<String> recorded = {};

  @override
  Widget build(BuildContext context) {
    final all = widget.data.album;
    final items = all.where((d) => filter == null || d.type == filter).toList();
    if (scrub >= items.length) scrub = items.isEmpty ? 0 : items.length - 1;
    final sideB = (all.length + recorded.length) / 12.0;
    final Doodle? scrubbed = items.isEmpty ? null : items[scrub];

    return Scaffold(
      backgroundColor: _d09Cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _D09Deck(
              leading: _D09DeckIcon(icon: Icons.chevron_left_rounded, onTap: () {}),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _D09Dymo('낙서 사진첩 · SIDE B', size: 11, tape: _d09Orange, ink: Colors.white),
                  const SizedBox(height: 3),
                  Text('${all.length}곡 녹음됨 · TAPE COLLECTION',
                      style: TextStyle(fontSize: 10, color: _d09a(_d09Cream, 0.8), letterSpacing: 0.5)),
                ],
              ),
              trailing: GestureDetector(
                onTap: () => setState(() => byDate = !byDate),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _d09Paper,
                    border: Border.all(color: _d09WalnutDark, width: 1.4),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(byDate ? Icons.calendar_today_rounded : Icons.category_rounded,
                        size: 13, color: _d09Rust),
                    const SizedBox(width: 5),
                    Text(byDate ? '날짜별' : '유형별',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _d09Rust)),
                  ]),
                ),
              ),
            ),
            // SCRUB reel — drag to fast-forward through days
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _d09a(_d09Felt, 0.9),
                  border: Border.all(color: _d09WalnutDark, width: 2),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onHorizontalDragUpdate: (d) {
                        _accum += d.delta.dx;
                        if (_accum.abs() > 26 && items.isNotEmpty) {
                          setState(() {
                            scrub = (scrub + (_accum > 0 ? 1 : -1)).clamp(0, items.length - 1);
                          });
                          _accum = 0;
                        }
                      },
                      child: _D09Reel(fill: 0.85, size: 60, period: const Duration(milliseconds: 1400)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            _D09Dymo('◀◀ 릴을 밀어 스크럽', size: 8, tape: _d09Orange, ink: Colors.white),
                          ]),
                          const SizedBox(height: 6),
                          if (scrubbed != null)
                            Text('▸ ${scrubbed.caption} · ${scrubbed.at.month}/${scrubbed.at.day}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _d09Felt09(size: 15, color: _d09Cream)),
                          const SizedBox(height: 6),
                          _D09Dymo('TAKE-UP ${(sideB * 100).round().clamp(0, 100)}%',
                              size: 8, tape: _d09Walnut),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _D09Reel(fill: sideB.clamp(0.15, 1.0), size: 60, period: const Duration(seconds: 3), clockwise: false),
                  ],
                ),
              ),
            ),
            // type filters as Dymo chips
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  _chip('전체', filter == null, () => setState(() { filter = null; scrub = 0; })),
                  for (final t in DoodleType.values)
                    _chip(t.label, filter == t, () => setState(() { filter = t; scrub = 0; })),
                ],
              ),
            ),
            // the tape grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _D09TapeCard(
                  doodle: items[i],
                  highlighted: i == scrub,
                  recorded: recorded.contains(items[i].id),
                  onRec: () => setState(() {
                    if (recorded.contains(items[i].id)) {
                      recorded.remove(items[i].id);
                    } else {
                      recorded.add(items[i].id);
                    }
                  }),
                ),
              ),
            ),
            const _D09Nav(current: 1),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: _D09Dymo(label, size: 10, tape: sel ? _d09Orange : _d09WalnutDark, ink: Colors.white),
        ),
      );
}

class _D09TapeCard extends StatelessWidget {
  final Doodle doodle;
  final bool highlighted;
  final bool recorded;
  final VoidCallback onRec;
  const _D09TapeCard({
    required this.doodle,
    required this.highlighted,
    required this.recorded,
    required this.onRec,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFCED2D1), Color(0xFF9AA2A1)],
        ),
        border: Border.all(
          color: highlighted ? _d09Orange : _d09WalnutDark,
          width: highlighted ? 3 : 1.6,
        ),
        boxShadow: [
          if (highlighted) BoxShadow(color: _d09a(_d09Orange, 0.5), blurRadius: 10),
          BoxShadow(color: _d09a(Colors.black, 0.22), blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // label band = the doodle swatch, with emoji + heart
          Expanded(
            child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: doodle.swatch,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _d09a(Colors.black, 0.2)),
            ),
            child: Stack(
              children: [
                Center(child: Text(doodle.emoji, style: const TextStyle(fontSize: 34))),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Icon(doodle.type.icon, size: 13, color: _d09a(Colors.white, 0.9)),
                ),
                if (doodle.liked)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Text('❤', style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                if (doodle.mode == SendMode.disappearing)
                  const Positioned(
                    bottom: 4,
                    right: 4,
                    child: Text('⏱', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            ),
          ),
          const SizedBox(height: 8),
          Text(doodle.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _d09Felt09(size: 15, color: _d09Felt)),
          const SizedBox(height: 4),
          Row(
            children: [
              _D09Dymo('${doodle.author} ${doodle.at.month}/${doodle.at.day}',
                  size: 7, tape: _d09Walnut),
              const Spacer(),
              GestureDetector(
                onTap: onRec,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: recorded ? const [_d09Orange, _d09OrangeDeep] : const [Color(0xFFF0483B), _d09Rust],
                    ),
                    border: Border.all(color: _d09WalnutDark, width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(recorded ? Icons.check : Icons.fiber_manual_record, size: 9, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(recorded ? 'SIDE B' : 'REC',
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
