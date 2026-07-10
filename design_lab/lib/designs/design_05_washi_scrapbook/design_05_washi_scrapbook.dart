// design_05_washi_scrapbook — "Washi Scrapbook"
//
// A maximalist cut-paper collage album. Torn kraft pages, striped washi tape,
// taped-down polaroids, crayon pens and ugly-cute stickers, all layered with
// real drop-shadow depth. Signature: "Tape it down" — drag a scrap toward the
// page edge and a washi strip peels off and presses over it. Both partners
// co-arrange the same live page (partner shown as a little paper cursor).
//
// Everything except `Design05` is private with a _D05 prefix to avoid clashes.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

class Design05 extends DesignVariant {
  @override
  String get id => '05';
  @override
  String get name => 'Washi Scrapbook';
  @override
  String get concept =>
      '손으로 오려 붙인 콜라주 앨범 — 찢긴 종이, 마스킹 테이프, 붙여둔 폴라로이드와 못난이 스티커가 진짜 그림자와 함께 층층이 쌓인다.';
  @override
  String get signature =>
      '"테이프로 붙이기" — 사진을 페이지 가장자리로 끌면 와시 테이프가 벗겨졌다가 눌러 붙는다. 두 사람이 같은 페이지를 함께 꾸미고, 상대는 종이 커서로 나타난다.';
  @override
  String get inspiration =>
      'Maximalist paper-collage journaling / washi-tape scrapbooking, ugly-cute sticker aesthetics';
  @override
  Color get accent => _D05.rose;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return _D05Board(
      child: switch (screen) {
        HeroScreen.drawSend => _D05DrawSend(data: data),
        HeroScreen.petHome => _D05PetHome(data: data),
        HeroScreen.memoryAlbum => _D05Album(data: data),
      },
    );
  }
}

// ============================================================ palette + helpers
class _D05 {
  static const rose = Color(0xFFE7B7B0);
  static const sage = Color(0xFFBFD1A8);
  static const butter = Color(0xFFF6E3A0);
  static const kraft = Color(0xFFC9A77C);
  static const kraftDark = Color(0xFFB08E64);
  static const ink = Color(0xFF352E27);
  static const paper = Color(0xFFFBF4E6);
  static const paperShade = Color(0xFFF0E6D2);
}

double _d05noise(double seed) {
  final v = math.sin(seed * 12.9898 + 3.14) * 43758.5453;
  return v - v.floorToDouble();
}

double _lp(double a, double b, double t) => a + (b - a) * t;

TextStyle _hand(
  double size, {
  Color color = _D05.ink,
  FontWeight weight = FontWeight.w800,
  double spacing = 0.2,
  FontStyle style = FontStyle.normal,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      fontStyle: style,
      height: 1.15,
    );

// ============================================================ board background
class _D05Board extends StatelessWidget {
  const _D05Board({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D05.kraft,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDBBE95), _D05.kraft, Color(0xFFBB965F)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _D05BoardPainter()),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _D05BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // paper speckles / fibers
    final dot = Paint();
    for (int i = 0; i < 150; i++) {
      final x = _d05noise(i * 1.7) * size.width;
      final y = _d05noise(i * 3.3 + 11) * size.height;
      final r = 0.6 + _d05noise(i * 5.1) * 1.6;
      final dark = _d05noise(i * 2.2) > 0.5;
      dot.color = (dark ? _D05.ink : Colors.white)
          .withValues(alpha: 0.04 + _d05noise(i * 0.9) * 0.06);
      canvas.drawCircle(Offset(x, y), r, dot);
    }
    // short fibers
    final fib = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 40; i++) {
      final x = _d05noise(i * 7.1 + 4) * size.width;
      final y = _d05noise(i * 4.6 + 9) * size.height;
      final a = _d05noise(i * 2.4) * math.pi;
      fib.color = _D05.kraftDark.withValues(alpha: 0.12);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(a) * 9, y + math.sin(a) * 9),
        fib,
      );
    }
    // two faint coffee-ring stains for charm
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _D05.kraftDark.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.18), 34, ring);
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.86), 26, ring);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================ washi tape widget
class _D05TapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path();
    const tooth = 4.0;
    p.moveTo(0, 0);
    p.lineTo(s.width, 0); // straight top
    // ragged right edge
    for (double y = 0; y < s.height; y += 7) {
      final inX = (y ~/ 7).isEven ? s.width - tooth : s.width;
      p.lineTo(inX, math.min(y + 3.5, s.height));
    }
    p.lineTo(s.width, s.height);
    p.lineTo(0, s.height); // straight bottom
    // ragged left edge going up
    for (double y = s.height; y > 0; y -= 7) {
      final inX = (y ~/ 7).isEven ? tooth : 0.0;
      p.lineTo(inX, math.max(y - 3.5, 0));
    }
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _D05TapePainter extends CustomPainter {
  _D05TapePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.80));
    // translucent top highlight
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.42),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    // diagonal stripes
    final st = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..strokeWidth = 6;
    for (double x = -size.height; x < size.width; x += 15) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), st);
    }
    // bottom edge shade
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 2, size.width, 2),
      Paint()..color = Colors.black.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant _D05TapePainter old) => old.color != color;
}

class _D05Tape extends StatelessWidget {
  const _D05Tape({
    required this.child,
    this.color = _D05.butter,
    this.angle = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });
  final Widget child;
  final Color color;
  final double angle;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 5,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: ClipPath(
          clipper: _D05TapeClipper(),
          child: CustomPaint(
            painter: _D05TapePainter(color),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

// ============================================================ torn paper card
class _D05TornPainter extends CustomPainter {
  _D05TornPainter(this.color, this.seed);
  final Color color;
  final double seed;

  Path _path(Size size) {
    final w = size.width, h = size.height;
    final p = Path();
    const d = 6.0;
    final teeth = (w / 15).floor().clamp(4, 42);
    p.moveTo(0, d + _d05noise(seed) * d);
    for (int i = 1; i <= teeth; i++) {
      p.lineTo(w * i / teeth, d * _d05noise(seed + i * 1.3));
    }
    p.lineTo(w, h - d * _d05noise(seed + 7));
    for (int i = 1; i <= teeth; i++) {
      p.lineTo(w * (1 - i / teeth), h - d * _d05noise(seed + i * 2.1 + 50));
    }
    p.lineTo(0, d + _d05noise(seed + 3) * d);
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    canvas.drawShadow(path, Colors.black, 5, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _D05TornPainter old) =>
      old.color != color || old.seed != seed;
}

class _D05Torn extends StatelessWidget {
  const _D05Torn({
    required this.child,
    this.color = _D05.paper,
    this.seed = 1,
    this.angle = 0,
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final Color color;
  final double seed;
  final double angle;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        painter: _D05TornPainter(color, seed),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ============================================================ rubber stamp
class _D05StampPainter extends CustomPainter {
  _D05StampPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    final inner = RRect.fromRectAndRadius(
      const Offset(3, 3) & Size(size.width - 6, size.height - 6),
      const Radius.circular(4),
    );
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2.6;
    canvas.drawRRect(outer, p);
    canvas.drawRRect(inner, p..strokeWidth = 1.3);
  }

  @override
  bool shouldRepaint(covariant _D05StampPainter old) => old.color != color;
}

class _D05Stamp extends StatelessWidget {
  const _D05Stamp(
    this.text, {
    this.color = _D05.rose,
    this.angle = -0.05,
    this.size = 13,
  });
  final String text;
  final Color color;
  final double angle;
  final double size;
  @override
  Widget build(BuildContext context) {
    final ink = Color.lerp(color, _D05.ink, 0.45)!;
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        painter: _D05StampPainter(color),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            text,
            style: _hand(size, color: ink, weight: FontWeight.w900, spacing: 1),
          ),
        ),
      ),
    );
  }
}

// ============================================================ sticker (die-cut)
class _D05Sticker extends StatelessWidget {
  const _D05Sticker(this.emoji, {this.size = 44, this.angle = 0});
  final String emoji;
  final double size;
  final double angle;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Text(emoji, style: TextStyle(fontSize: size * 0.56)),
      ),
    );
  }
}

// ============================================================ paper co-cursor
class _D05PaperCursor extends StatelessWidget {
  const _D05PaperCursor(this.name, {this.angle = 0.14});
  final String name;
  final double angle;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👆', style: TextStyle(fontSize: 26)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _D05.sage,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text('$name 함께 꾸미는 중',
                style: _hand(10, color: _D05.ink, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ============================================================ crayon pen
class _D05CrayonPainter extends CustomPainter {
  _D05CrayonPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final tip = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.18, h * 0.24)
      ..lineTo(w * 0.82, h * 0.24)
      ..close();
    canvas.drawPath(tip, Paint()..color = Color.lerp(color, Colors.black, 0.4)!);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.22, w * 0.72, h * 0.78),
      const Radius.circular(5),
    );
    canvas.drawRRect(body, Paint()..color = color);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.10),
    );
    // paper band
    canvas.drawRect(
      Rect.fromLTWH(w * 0.14, h * 0.5, w * 0.72, h * 0.16),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _D05CrayonPainter old) => old.color != color;
}

// ============================================================ 1) DRAW & SEND
class _D05DrawSend extends StatefulWidget {
  const _D05DrawSend({required this.data});
  final AppData data;
  @override
  State<_D05DrawSend> createState() => _D05DrawSendState();
}

class _D05DrawSendState extends State<_D05DrawSend>
    with SingleTickerProviderStateMixin {
  int pen = 1;
  double thickness = 7;
  SendMode mode = SendMode.normal;
  late final AnimationController _press =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 720));

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _tapeAndSend() => _press.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    final c = widget.data.couple;
    final penColor = demoPenColors[pen];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        children: [
          // ---- top bar
          Row(
            children: [
              _tapButton(const Icon(Icons.arrow_back_rounded,
                  color: _D05.ink, size: 22)),
              Expanded(
                child: Center(
                  child: _D05Tape(
                    color: _D05.rose,
                    angle: -0.03,
                    child: Text('${c.partnerNickname}에게',
                        style: _hand(16, weight: FontWeight.w900)),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _tapeAndSend,
                child: _D05Stamp('보내기 ✉', color: _D05.sage, angle: 0.04),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ---- canvas page
          Expanded(
            child: _canvas(penColor),
          ),
          const SizedBox(height: 12),
          // ---- crayon palette
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < demoPenColors.length; i++)
                GestureDetector(
                  onTap: () => setState(() => pen = i),
                  child: Transform.translate(
                    offset: Offset(0, pen == i ? -12 : 0),
                    child: Transform.rotate(
                      angle: _lp(-0.14, 0.14, _d05noise(i * 4.0)),
                      child: SizedBox(
                        width: 26,
                        height: 58,
                        child: CustomPaint(
                          painter: _D05CrayonPainter(demoPenColors[i]),
                          child: pen == i
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: _D05.ink,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // ---- thickness
          _thickness(penColor),
          const SizedBox(height: 8),
          // ---- mode toggle
          Row(
            children: [
              for (final m in SendMode.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => mode = m),
                    child: Transform.translate(
                      offset: Offset(0, mode == m ? -3 : 0),
                      child: _D05Tape(
                        color: mode == m ? _D05.butter : _D05.paperShade,
                        angle: mode == m ? -0.02 : 0.03,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        child: Text(
                          m == SendMode.normal ? '📌 일반' : '⏳ 사라지기',
                          style: _hand(13,
                              color: mode == m
                                  ? _D05.ink
                                  : _D05.ink.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _D05Torn(
                  seed: 9,
                  angle: 0.01,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(mode.description,
                      style: _hand(11,
                          weight: FontWeight.w700,
                          style: FontStyle.italic)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ---- bottom actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _D05ActionSticker(emoji: '🖼️', label: '갤러리'),
              _D05ActionSticker(emoji: '📷', label: '사진'),
              _D05ActionSticker(emoji: '👉', label: '찌르기'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tapButton(Widget icon) => Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: icon,
      );

  Widget _canvas(Color penColor) {
    return AnimatedBuilder(
      animation: _press,
      builder: (context, _) {
        final t = Curves.easeOutBack.transform(_press.value);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // page
            Positioned.fill(
              child: Transform.rotate(
                angle: -0.012,
                child: CustomPaint(
                  painter: _D05TornPainter(_D05.paper, 21),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: CustomPaint(
                      painter: _D05CanvasPainter(penColor, thickness),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Transform.rotate(
                          angle: -0.05,
                          child: Text('여기에 낙서 ✏️',
                              style: _hand(15,
                                  color: _D05.ink.withValues(alpha: 0.35))),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // corner tapes holding the page down
            Positioned(
              top: -10,
              left: 26,
              child: _D05Tape(
                  color: _D05.rose,
                  angle: -0.5,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 9),
                  child: const SizedBox()),
            ),
            Positioned(
              top: -8,
              right: 22,
              child: _D05Tape(
                  color: _D05.sage,
                  angle: 0.55,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 26, vertical: 9),
                  child: const SizedBox()),
            ),
            // partner paper cursor co-arranging
            const Positioned(
              right: 18,
              bottom: 26,
              child: _D05PaperCursor('토리'),
            ),
            // "tape it down" press animation over a dropped scrap
            Positioned(
              left: 24,
              bottom: 34,
              child: Opacity(
                opacity: (0.35 + t * 0.65).clamp(0.0, 1.0),
                child: _D05Sticker('💘',
                    size: 52, angle: _lp(-0.2, 0.02, t)),
              ),
            ),
            if (_press.value > 0.01)
              Positioned(
                left: 8,
                bottom: 30 + _lp(46, 0, t),
                child: Opacity(
                  opacity: (t * 1.4).clamp(0.0, 1.0),
                  child: _D05Tape(
                    color: _D05.butter,
                    angle: _lp(-0.6, 0.12, t),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 34, vertical: 10),
                    child: const SizedBox(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _thickness(Color penColor) {
    return Row(
      children: [
        Text('굵기', style: _hand(13, weight: FontWeight.w900)),
        const SizedBox(width: 10),
        Expanded(
          child: LayoutBuilder(builder: (context, con) {
            final w = con.maxWidth;
            void setFrom(double dx) {
              final tt = (dx / w).clamp(0.0, 1.0);
              setState(() => thickness = _lp(1, 20, tt));
            }

            final knobX = ((thickness - 1) / 19) * (w - 24);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) => setFrom(d.localPosition.dx),
              onPanUpdate: (d) => setFrom(d.localPosition.dx),
              child: SizedBox(
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _D05TrackPainter(
                            (thickness - 1) / 19, penColor),
                      ),
                    ),
                    Positioned(
                      left: knobX,
                      top: 4,
                      child: Container(
                        width: 24,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 3,
                              offset: const Offset(1, 2),
                            ),
                          ],
                        ),
                        child: const Text('✏️',
                            style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(width: 12),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Container(
            width: (6 + thickness).clamp(6, 30).toDouble(),
            height: (6 + thickness).clamp(6, 30).toDouble(),
            decoration: BoxDecoration(color: penColor, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

class _D05ActionSticker extends StatelessWidget {
  const _D05ActionSticker({required this.emoji, required this.label});
  final String emoji;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _D05Sticker(emoji, size: 50, angle: 0.05),
        const SizedBox(height: 4),
        _D05Stamp(label, color: _D05.kraft, angle: -0.03, size: 11),
      ],
    );
  }
}

class _D05TrackPainter extends CustomPainter {
  _D05TrackPainter(this.fill, this.color);
  final double fill; // 0..1
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final base = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = _D05.kraftDark.withValues(alpha: 0.5);
    final path = Path()..moveTo(0, y);
    for (double x = 0; x <= size.width; x += 6) {
      path.lineTo(x, y + math.sin(x * 0.25) * 2);
    }
    canvas.drawPath(path, base);
    // filled portion
    final fx = size.width * fill;
    final fp = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    final f = Path()..moveTo(0, y);
    for (double x = 0; x <= fx; x += 6) {
      f.lineTo(x, y + math.sin(x * 0.25) * 2);
    }
    canvas.drawPath(f, fp);
  }

  @override
  bool shouldRepaint(covariant _D05TrackPainter old) =>
      old.fill != fill || old.color != color;
}

class _D05CanvasPainter extends CustomPainter {
  _D05CanvasPainter(this.color, this.thickness);
  final Color color;
  final double thickness;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color
      ..strokeWidth = thickness.clamp(2, 18);
    // wavy stroke 1
    final s1 = Path()..moveTo(size.width * 0.12, size.height * 0.5);
    for (int i = 0; i <= 20; i++) {
      final x = size.width * (0.12 + 0.5 * i / 20);
      final y = size.height * (0.5 + math.sin(i * 0.7) * 0.09);
      s1.lineTo(x, y);
    }
    canvas.drawPath(s1, p);
    // little heart
    final hx = size.width * 0.72, hy = size.height * 0.36, r = thickness + 12;
    final heart = Path()
      ..moveTo(hx, hy + r * 0.5)
      ..cubicTo(hx - r, hy - r * 0.4, hx - r * 0.2, hy - r, hx, hy - r * 0.3)
      ..cubicTo(hx + r * 0.2, hy - r, hx + r, hy - r * 0.4, hx, hy + r * 0.5)
      ..close();
    canvas.drawPath(heart, p);
    // scribble underline
    final s2 = Path()..moveTo(size.width * 0.2, size.height * 0.78);
    for (int i = 0; i <= 14; i++) {
      final x = size.width * (0.2 + 0.4 * i / 14);
      final y = size.height * (0.78 + (i.isEven ? -0.02 : 0.02));
      s2.lineTo(x, y);
    }
    canvas.drawPath(s2, p..strokeWidth = (thickness * 0.6).clamp(2, 10));
  }

  @override
  bool shouldRepaint(covariant _D05CanvasPainter old) =>
      old.color != color || old.thickness != thickness;
}

// ============================================================ 2) PET HOME
class _D05PetHome extends StatefulWidget {
  const _D05PetHome({required this.data});
  final AppData data;
  @override
  State<_D05PetHome> createState() => _D05PetHomeState();
}

class _D05PetHomeState extends State<_D05PetHome> {
  bool patted = false;
  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((e) => e.equipped).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        children: [
          // top bar
          Row(
            children: [
              _D05Tape(
                color: _D05.sage,
                angle: -0.03,
                child: Text('${pet.name} · Lv.${pet.level}',
                    style: _hand(16, weight: FontWeight.w900)),
              ),
              const Spacer(),
              _D05Stamp('🪙 ${pet.coins}', color: _D05.butter, angle: 0.05),
            ],
          ),
          const SizedBox(height: 10),
          // pet stage
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => patted = !patted),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // taped-down page behind pet
                  Positioned.fill(
                    child: _D05Torn(
                      color: _D05.paper,
                      seed: 31,
                      angle: 0.008,
                      padding: EdgeInsets.zero,
                      child: const SizedBox(),
                    ),
                  ),
                  const Positioned(
                    top: -10,
                    child: _D05Tape(
                      color: _D05.rose,
                      angle: 0.04,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 9),
                      child: SizedBox(),
                    ),
                  ),
                  // speech paper bubble
                  if (patted)
                    Positioned(
                      top: 24,
                      child: _D05Torn(
                        color: _D05.butter,
                        seed: 5,
                        angle: -0.02,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Text('“${pet.speech}”',
                            style: _hand(14,
                                weight: FontWeight.w800,
                                style: FontStyle.italic)),
                      ),
                    ),
                  // the pet + equipped stickers
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Text(pet.moodEmoji,
                              style: const TextStyle(fontSize: 108)),
                          // equipped hat above
                          if (equipped.isNotEmpty)
                            Positioned(
                              top: -18,
                              child: Text(equipped.first.emoji,
                                  style: const TextStyle(fontSize: 42)),
                            ),
                          // additional equipped props as stickers
                          for (int i = 1; i < equipped.length; i++)
                            Positioned(
                              right: -6.0 - i * 8,
                              bottom: 0,
                              child: _D05Sticker(equipped[i].emoji,
                                  size: 34, angle: 0.1 * i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _D05Stamp('쓰다듬어 주세요 🫳',
                          color: _D05.kraft, angle: -0.02, size: 11),
                    ],
                  ),
                  // growth gauge at bottom
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: _growthGauge(pet.growth),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // store
          Align(
            alignment: Alignment.centerLeft,
            child: _D05Tape(
              color: _D05.butter,
              angle: -0.02,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('🛍️ 몽이 스토어',
                  style: _hand(14, weight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pet.store.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) => _storeCard(pet.store[i], i),
            ),
          ),
          const SizedBox(height: 8),
          const _D05Nav(current: 0),
        ],
      ),
    );
  }

  Widget _growthGauge(double v) {
    return LayoutBuilder(builder: (context, con) {
      final w = con.maxWidth;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 22,
            decoration: BoxDecoration(
              color: _D05.paperShade,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _D05.kraftDark.withValues(alpha: 0.4)),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: (w * v).clamp(0, w),
              height: 22,
              child: CustomPaint(painter: _D05TapePainter(_D05.sage)),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Text('성장 ${(v * 100).round()}% · 다음 레벨까지',
                  style: _hand(11, weight: FontWeight.w900)),
            ),
          ),
        ],
      );
    });
  }

  Widget _storeCard(PetItem it, int i) {
    final String tag = it.owned
        ? (it.equipped ? '착용중 ✓' : '보유')
        : '🪙 ${it.price}';
    final Color tagColor =
        it.equipped ? _D05.sage : (it.owned ? _D05.butter : _D05.rose);
    return Transform.rotate(
      angle: _lp(-0.05, 0.05, _d05noise(i * 6.0)),
      child: SizedBox(
        width: 96,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _D05Torn(
              color: it.equipped ? const Color(0xFFEAF1DD) : _D05.paper,
              seed: 40.0 + i,
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(it.emoji, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 4),
                  Text(it.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _hand(11, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag,
                        style: _hand(10, weight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            // little category tag string
            Positioned(
              top: -6,
              left: 34,
              child: _D05Stamp(it.category,
                  color: _D05.kraft, angle: -0.1, size: 9),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================ 3) MEMORY ALBUM
class _D05Album extends StatefulWidget {
  const _D05Album({required this.data});
  final AppData data;
  @override
  State<_D05Album> createState() => _D05AlbumState();
}

class _D05AlbumState extends State<_D05Album> {
  bool byDate = true;
  DoodleType? filter;

  List<Doodle> get _items {
    var list = widget.data.album
        .where((d) => filter == null || d.type == filter)
        .toList();
    if (byDate) {
      list.sort((a, b) => b.at.compareTo(a.at));
    } else {
      list.sort((a, b) {
        final t = a.type.index.compareTo(b.type.index);
        return t != 0 ? t : b.at.compareTo(a.at);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.data.couple;
    final items = _items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        children: [
          // top bar
          Row(
            children: [
              _D05Tape(
                color: _D05.rose,
                angle: -0.03,
                child: Text('우리 낙서장',
                    style: _hand(17, weight: FontWeight.w900)),
              ),
              const SizedBox(width: 6),
              _D05Stamp('${c.streakDays}일째',
                  color: _D05.kraft, angle: 0.06, size: 10),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => byDate = !byDate),
                child: _D05Stamp(byDate ? '날짜별' : '유형별',
                    color: _D05.sage, angle: -0.04),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ---- signature: TAPE IT DOWN
          _D05TapeItDown(partner: c.partnerNickname),
          const SizedBox(height: 10),
          // ---- type filters
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('전체', filter == null, () {
                  setState(() => filter = null);
                }),
                for (final t in DoodleType.values)
                  _filterChip(t.label, filter == t, () {
                    setState(() => filter = t);
                  }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ---- grid of scraps
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 16,
                childAspectRatio: 0.70,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _scrap(items[i], i),
            ),
          ),
          const SizedBox(height: 6),
          const _D05Nav(current: 1),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Transform.translate(
          offset: Offset(0, sel ? -2 : 0),
          child: _D05Tape(
            color: sel ? _D05.butter : _D05.paperShade,
            angle: sel ? -0.03 : 0.02,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(label,
                style: _hand(12,
                    color: sel ? _D05.ink : _D05.ink.withValues(alpha: 0.5),
                    weight: FontWeight.w900)),
          ),
        ),
      ),
    );
  }

  Widget _scrap(Doodle d, int i) {
    final tapeColors = [_D05.rose, _D05.sage, _D05.butter];
    return Transform.rotate(
      angle: _lp(-0.055, 0.055, _d05noise(i * 3.0 + 1)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // polaroid
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(7, 7, 7, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: d.swatch,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(d.emoji,
                          style: const TextStyle(fontSize: 48)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _hand(13, weight: FontWeight.w900)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(d.author,
                        style: _hand(10,
                            color: _D05.ink.withValues(alpha: 0.6),
                            weight: FontWeight.w700,
                            style: FontStyle.italic)),
                    const Spacer(),
                    _D05Stamp('${d.at.month}.${d.at.day}',
                        color: _D05.kraft, angle: -0.08, size: 9),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          // washi tape holding it down
          Positioned(
            top: -9,
            left: 24,
            child: _D05Tape(
              color: tapeColors[i % tapeColors.length],
              angle: _lp(-0.35, 0.35, _d05noise(i * 2.0)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: const SizedBox(),
            ),
          ),
          // disappearing-mode marker
          if (d.mode == SendMode.disappearing)
            const Positioned(
              top: 12,
              left: 10,
              child: Text('⏳', style: TextStyle(fontSize: 16)),
            ),
          // liked heart sticker
          if (d.liked)
            const Positioned(
              bottom: 34,
              right: -6,
              child: _D05Sticker('❤️', size: 30, angle: 0.2),
            ),
        ],
      ),
    );
  }
}

// ---- signature interaction: drag scrap → washi tape peels & presses down
class _D05TapeItDown extends StatefulWidget {
  const _D05TapeItDown({required this.partner});
  final String partner;
  @override
  State<_D05TapeItDown> createState() => _D05TapeItDownState();
}

class _D05TapeItDownState extends State<_D05TapeItDown>
    with TickerProviderStateMixin {
  late final AnimationController _press =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final AnimationController _ret =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Offset _drag = Offset.zero;
  Offset _retFrom = Offset.zero;
  bool _taped = false;

  @override
  void initState() {
    super.initState();
    _ret.addListener(() {
      final f = Curves.easeOutBack.transform(_ret.value);
      setState(() => _drag = Offset.lerp(_retFrom, Offset.zero, f)!);
    });
  }

  @override
  void dispose() {
    _press.dispose();
    _ret.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _taped = false;
      _drag = Offset.zero;
    });
    _press.reset();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: LayoutBuilder(builder: (context, con) {
        final w = con.maxWidth;
        const homeX = 20.0, cy = 40.0;
        final slotX = w - 150.0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // backing note page
            Positioned.fill(
              child: _D05Torn(
                color: _D05.paperShade,
                seed: 77,
                angle: 0.006,
                padding: EdgeInsets.zero,
                child: const SizedBox(),
              ),
            ),
            Positioned(
              left: 14,
              top: 8,
              child: _D05Stamp(
                _taped ? '붙였어요! 🎉' : '사진을 끌어 페이지에 붙이기',
                color: _taped ? _D05.sage : _D05.rose,
                angle: -0.03,
                size: 11,
              ),
            ),
            // target slot outline
            Positioned(
              left: slotX,
              top: cy - 20,
              child: _D05DottedTargetBox(active: !_taped),
            ),
            // partner co-cursor near the slot
            Positioned(
              right: 6,
              bottom: 4,
              child: _D05PaperCursor(widget.partner, angle: 0.12),
            ),
            // the draggable scrap
            AnimatedBuilder(
              animation: Listenable.merge([_press, _ret]),
              builder: (context, _) {
                final baseX = _taped ? slotX : homeX;
                final press = Curves.elasticOut.transform(_press.value);
                final scale = _taped ? _lp(1.18, 1.0, press) : 1.0;
                return Positioned(
                  left: baseX + _drag.dx,
                  top: cy - 20 + _drag.dy,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Transform.scale(
                        scale: scale,
                        child: GestureDetector(
                          onPanUpdate: (d) {
                            if (_taped) return;
                            setState(() => _drag += d.delta);
                          },
                          onPanEnd: (_) {
                            final x = homeX + _drag.dx;
                            if (x > w * 0.42) {
                              setState(() {
                                _taped = true;
                                _drag = Offset.zero;
                              });
                              _press.forward(from: 0);
                            } else {
                              _retFrom = _drag;
                              _ret.forward(from: 0);
                            }
                          },
                          child: Container(
                            width: 128,
                            padding:
                                const EdgeInsets.fromLTRB(6, 6, 6, 0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.30),
                                  blurRadius: 8,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 52,
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFA18CD1),
                                        Color(0xFFFBC2EB)
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text('🖍️',
                                        style: TextStyle(fontSize: 26)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Text('새 낙서',
                                      style: _hand(11,
                                          weight: FontWeight.w900)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // the peeling / pressing washi strip
                      if (_taped)
                        Positioned(
                          top: -10 + _lp(-40, 0, press),
                          left: 18,
                          child: Opacity(
                            opacity: (_press.value * 1.6).clamp(0.0, 1.0),
                            child: _D05Tape(
                              color: _D05.butter,
                              angle: _lp(-0.7, 0.1, press),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 9),
                              child: const SizedBox(),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            if (_taped)
              Positioned(
                right: 10,
                top: 6,
                child: GestureDetector(
                  onTap: _reset,
                  child: _D05Stamp('떼기', color: _D05.kraft, size: 10),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _D05DottedTargetBox extends StatelessWidget {
  const _D05DottedTargetBox({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _D05DashPainter(
          active ? _D05.ink.withValues(alpha: 0.5) : _D05.sage),
      child: SizedBox(
        width: 128,
        height: 84,
        child: Center(
          child: Text(active ? '여기에\n붙여요' : '✓',
              textAlign: TextAlign.center,
              style: _hand(12,
                  color: _D05.ink.withValues(alpha: 0.45),
                  weight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _D05DashPainter extends CustomPainter {
  _D05DashPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color;
    final rect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(6));
    final path = Path()..addRRect(rect);
    // manual dashing
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final seg = metric.extractPath(dist, dist + 6);
        canvas.drawPath(seg, p);
        dist += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _D05DashPainter old) => old.color != color;
}

// ============================================================ bottom nav
class _D05Nav extends StatelessWidget {
  const _D05Nav({required this.current});
  final int current;
  @override
  Widget build(BuildContext context) {
    const tabs = [
      ['🐣', '펫키우기'],
      ['📔', '사진첩'],
      ['✉️', '소통'],
    ];
    final colors = [_D05.sage, _D05.rose, _D05.butter];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: _D05.kraftDark.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < tabs.length; i++)
            Transform.translate(
              offset: Offset(0, current == i ? -4 : 0),
              child: _D05Tape(
                color: current == i
                    ? colors[i]
                    : _D05.paperShade.withValues(alpha: 0.85),
                angle: _lp(-0.03, 0.03, _d05noise(i * 9.0)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tabs[i][0], style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 5),
                    Text(tabs[i][1],
                        style: _hand(12,
                            color: current == i
                                ? _D05.ink
                                : _D05.ink.withValues(alpha: 0.5),
                            weight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
