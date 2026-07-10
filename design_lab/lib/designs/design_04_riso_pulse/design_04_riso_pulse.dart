// design_04_riso_pulse — a two-ink risograph zine.
//
// Fluoro pink (#FF48B0) overprinted on electric blue (#0B4CFF) on newsprint
// cream, with deliberate misregistration, heavy grain, knockout-white gaps and
// oversized condensed grotesk that shouts. Ink layers slide from an offset into
// alignment on load. Shake-to-shuffle re-lays the album into a fresh zine
// spread every time — the ink misregister re-settling so no two spreads match.
//
// Everything except `Design04` is private with a `_D04` prefix.

import 'package:flutter/material.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

class Design04 extends DesignVariant {
  @override
  String get id => '04';
  @override
  String get name => 'Riso Pulse';
  @override
  String get concept =>
      'Two-ink 리소그래프 zine — 형광 핑크 위에 일렉트릭 블루 오버프린트, 어긋난 판 정합과 거친 그레인, 소리치는 컨덴스드 그로테스크.';
  @override
  String get signature =>
      '흔들면 앨범이 매번 새로운 zine 스프레드로 재조판되고 어긋난 잉크 판이 다시 정합을 맞춘다.';
  @override
  String get inspiration =>
      'Risograph zine 인쇄 · 형광 스팟컬러 오버프린트 · 미스레지스트레이션 · indie print grotesk';
  @override
  Color get accent => _D04C.pink;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return switch (screen) {
      HeroScreen.drawSend => _D04Draw(data: data),
      HeroScreen.petHome => _D04Pet(data: data),
      HeroScreen.memoryAlbum => _D04Album(data: data),
    };
  }
}

// ============================================================ palette & math ==

class _D04C {
  static const pink = Color(0xFFFF48B0); // fluoro pink spot ink
  static const blue = Color(0xFF0B4CFF); // electric blue overprint
  static const cream = Color(0xFFF3EEE0); // newsprint paper
  static const paper = Color(0xFFFDFBF4); // knockout white gap
  static const ink = Color(0xFF10122E); // near-black deep overprint
  static const overlap = Color(0xFF2C1B6B); // pink*blue overprint darken
}

const double _pi = 3.1415926535897932;
double _rad(double deg) => deg * _pi / 180.0;

/// Deterministic Park–Miller MINSTD generator — no dart:math Random(), and
/// exact on Flutter web (products stay < 2^53).
class _D04Rng {
  int _s;
  _D04Rng(int seed) : _s = (seed % 2147483646).abs() + 1;
  double next() {
    _s = (_s * 48271) % 2147483647;
    return _s / 2147483647.0;
  }

  double range(double a, double b) => a + (b - a) * next();
  int pick(int n) => (next() * n).floor().clamp(0, n - 1);
  bool flip() => next() > 0.5;
}

// ============================================================ ink primitives ==

/// The signature look: a shape printed in two inks, slightly out of register.
/// [amt] is animated so the pink plate slides in from an offset and settles.
class _D04Ink extends StatelessWidget {
  const _D04Ink(
    this.text, {
    required this.size,
    this.amt = 2.6,
    this.weight = FontWeight.w900,
    this.scaleX = 0.82,
    this.spacing = -1.4,
    this.front = _D04C.ink,
    this.back = _D04C.pink,
    this.align = TextAlign.left,
    this.height = 0.92,
  });

  final String text;
  final double size;
  final double amt;
  final FontWeight weight;
  final double scaleX;
  final double spacing;
  final Color front;
  final Color back;
  final TextAlign align;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      color: front,
    );
    return Transform.scale(
      scaleX: scaleX,
      alignment: align == TextAlign.center
          ? Alignment.center
          : Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(amt, amt * 1.15),
            child: Text(text,
                textAlign: align, style: style.copyWith(color: back)),
          ),
          Transform.translate(
            offset: Offset(-amt * 0.35, -amt * 0.2),
            child: Text(text,
                textAlign: align,
                style: style.copyWith(color: _D04C.blue.withOpacity(0.9))),
          ),
          Text(text, textAlign: align, style: style),
        ],
      ),
    );
  }
}

/// A blocky print button with a hard offset "second-ink" shadow.
class _D04Hard extends StatelessWidget {
  const _D04Hard({
    required this.child,
    this.fill = _D04C.paper,
    this.shadow = _D04C.blue,
    this.border = _D04C.ink,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.drop = 5,
    this.radius = 3,
    this.borderWidth = 2.6,
  });

  final Widget child;
  final Color fill;
  final Color shadow;
  final Color border;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double drop;
  final double radius;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(drop, drop),
              child: DecoratedBox(
                decoration: BoxDecoration(color: shadow, borderRadius: r),
              ),
            ),
          ),
          Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: r,
              border: Border.all(color: border, width: borderWidth),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A tiny print tag / caption chip.
class _D04Tag extends StatelessWidget {
  const _D04Tag(this.label,
      {this.fill = _D04C.ink, this.fg = _D04C.cream, this.size = 10.5});
  final String label;
  final Color fill;
  final Color fg;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      color: fill,
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ============================================================= paper backdrop =

/// Static printed-paper background: cream fill, offset ink stripes, grain, crop
/// marks and a CMYK-style calibration strip. Painted once (does not animate).
class _D04Paper extends CustomPainter {
  const _D04Paper(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = _D04C.cream);

    // --- big offset ink shapes (overprint via multiply) ---
    final pink = Paint()
      ..color = _D04C.pink.withOpacity(0.42)
      ..blendMode = BlendMode.multiply;
    final blue = Paint()
      ..color = _D04C.blue.withOpacity(0.34)
      ..blendMode = BlendMode.multiply;

    // diagonal stripe band near the top
    Path band(double y, double h, double dx) {
      final p = Path();
      p.moveTo(-40 + dx, y);
      p.lineTo(size.width + 40 + dx, y - 60);
      p.lineTo(size.width + 40 + dx, y - 60 + h);
      p.lineTo(-40 + dx, y + h);
      p.close();
      return p;
    }

    canvas.drawPath(band(120, 26, 6), pink);
    canvas.drawPath(band(120, 26, -4), blue);
    canvas.drawPath(band(size.height - 150, 20, 5), blue);
    canvas.drawPath(band(size.height - 150, 20, -5), pink);

    // faint registration target ring (misprinted)
    void ring(Offset c, double r, Paint p) {
      canvas.drawCircle(c, r, p..style = PaintingStyle.stroke..strokeWidth = 6);
    }

    ring(Offset(size.width - 42, 80), 20, Paint()..color = _D04C.pink.withOpacity(0.5)..blendMode = BlendMode.multiply);
    ring(Offset(size.width - 46, 82), 20, Paint()..color = _D04C.blue.withOpacity(0.45)..blendMode = BlendMode.multiply);

    // --- grain: black + spot specks ---
    final rng = _D04Rng(seed);
    for (int i = 0; i < 950; i++) {
      final x = rng.next() * size.width;
      final y = rng.next() * size.height;
      final roll = rng.next();
      final Color c;
      if (roll < 0.72) {
        c = _D04C.ink.withOpacity(0.05 + rng.next() * 0.05);
      } else if (roll < 0.87) {
        c = _D04C.pink.withOpacity(0.10);
      } else {
        c = _D04C.blue.withOpacity(0.09);
      }
      final s = rng.range(0.8, 1.9);
      canvas.drawRect(
        Rect.fromLTWH(x, y, s, s),
        Paint()..color = c..blendMode = BlendMode.multiply,
      );
    }

    // --- corner crop marks ---
    final crop = Paint()
      ..color = _D04C.ink.withOpacity(0.55)
      ..strokeWidth = 1.4;
    const m = 12.0, len = 14.0;
    void marks(Offset o, int sx, int sy) {
      canvas.drawLine(o, o.translate(len * sx, 0), crop);
      canvas.drawLine(o, o.translate(0, len * sy), crop);
    }

    marks(Offset(m, m), 1, 1);
    marks(Offset(size.width - m, m), -1, 1);
    marks(Offset(m, size.height - m), 1, -1);
    marks(Offset(size.width - m, size.height - m), -1, -1);

    // --- calibration strip bottom-left ---
    const colors = [_D04C.pink, _D04C.blue, _D04C.overlap, _D04C.ink];
    for (int i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(m + i * 15.0, size.height - m - 12, 14, 12),
        Paint()..color = colors[i].withOpacity(0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _D04Paper old) => old.seed != seed;
}

/// Wraps a screen: paints the static paper backdrop behind [child].
class _D04Scaffold extends StatelessWidget {
  const _D04Scaffold({required this.child, this.bottom, this.seed = 7});
  final Widget child;
  final Widget? bottom;
  final int seed;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D04C.cream,
      bottomNavigationBar: bottom,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _D04Paper(seed)),
          ),
          SafeArea(bottom: bottom == null, child: child),
        ],
      ),
    );
  }
}

// ================================================================= bottom nav =

class _D04Nav extends StatelessWidget {
  const _D04Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const items = [
      ['펫키우기', '🐣', 'PET'],
      ['사진첩', '📓', 'ZINE'],
      ['소통', '✍️', 'SEND'],
    ];
    return Container(
      decoration: const BoxDecoration(
        color: _D04C.paper,
        border: Border(top: BorderSide(color: _D04C.ink, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _D04Hard(
                    onTap: () {},
                    fill: i == current ? _D04C.blue : _D04C.paper,
                    shadow: i == current ? _D04C.pink : _D04C.cream,
                    drop: i == current ? 4 : 2,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(items[i][1],
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(
                          items[i][2],
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: i == current ? _D04C.cream : _D04C.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ]
                .expand((w) => [w, const SizedBox(width: 8)])
                .toList()
              ..removeLast(),
          ),
        ),
      ),
    );
  }
}

// ================================================================= DRAW & SEND

class _D04Draw extends StatefulWidget {
  const _D04Draw({required this.data});
  final AppData data;
  @override
  State<_D04Draw> createState() => _D04DrawState();
}

class _D04DrawState extends State<_D04Draw>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  int pen = 1;
  double thickness = 8;
  SendMode mode = SendMode.normal;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    return _D04Scaffold(
      seed: 21,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_c.value);
          final mis = 13.5 * (1 - t) + 2.6;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- compose bar ----
                Row(
                  children: [
                    _D04Hard(
                      onTap: () {},
                      fill: _D04C.paper,
                      shadow: _D04C.blue,
                      padding: const EdgeInsets.all(9),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: _D04C.ink, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _D04Tag('TO. 받는이', fill: _D04C.pink, fg: _D04C.ink),
                          const SizedBox(height: 3),
                          _D04Ink(couple.partnerNickname,
                              size: 34, amt: mis, back: _D04C.pink),
                        ],
                      ),
                    ),
                    _D04Hard(
                      onTap: () {},
                      fill: _D04C.pink,
                      shadow: _D04C.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('SEND',
                              style: TextStyle(
                                  color: _D04C.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 0.5)),
                          SizedBox(width: 5),
                          Icon(Icons.send_rounded, size: 16, color: _D04C.ink),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // ---- canvas ----
                Expanded(child: _canvas(mis)),
                const SizedBox(height: 14),
                // ---- pens ----
                Row(
                  children: [
                    const _D04Tag('INK'),
                    const SizedBox(width: 8),
                    for (int i = 0; i < demoPenColors.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => pen = i),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: demoPenColors[i],
                              border: Border.all(
                                color: pen == i ? _D04C.ink : _D04C.ink.withOpacity(0.25),
                                width: pen == i ? 3.4 : 1.4,
                              ),
                            ),
                            child: pen == i
                                ? const Icon(Icons.circle,
                                    size: 8, color: Colors.white70)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // ---- thickness ----
                Row(
                  children: [
                    const _D04Tag('WEIGHT', fill: _D04C.blue, fg: _D04C.cream),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 6,
                          activeTrackColor: _D04C.pink,
                          inactiveTrackColor: _D04C.ink.withOpacity(0.18),
                          thumbColor: _D04C.ink,
                          overlayColor: _D04C.pink.withOpacity(0.15),
                          trackShape: const RectangularSliderTrackShape(),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9),
                        ),
                        child: Slider(
                          value: thickness,
                          min: 2,
                          max: 22,
                          onChanged: (v) => setState(() => thickness = v),
                        ),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          border: Border.all(color: _D04C.ink, width: 2)),
                      child: Container(
                        width: thickness,
                        height: thickness,
                        decoration: BoxDecoration(
                          color: demoPenColors[pen],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ---- mode toggle ----
                Row(
                  children: [
                    Expanded(
                      child: _modeBtn(SendMode.normal, '일반', Icons.push_pin_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _modeBtn(
                          SendMode.disappearing, '사라지기', Icons.timer_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: _D04C.ink,
                  child: Text(
                    '▸ ${mode.description}',
                    style: const TextStyle(
                        color: _D04C.cream,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                // ---- bottom actions ----
                Row(
                  children: [
                    Expanded(child: _action(Icons.photo_library_rounded, '갤러리', _D04C.blue)),
                    const SizedBox(width: 10),
                    Expanded(child: _action(Icons.photo_camera_rounded, '사진', _D04C.pink)),
                    const SizedBox(width: 10),
                    Expanded(child: _action(Icons.notifications_active_rounded, '찌르기', _D04C.overlap)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _canvas(double mis) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(6, 6),
            child: const DecoratedBox(
                decoration: BoxDecoration(color: _D04C.pink)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _D04C.paper,
            border: Border.all(color: _D04C.ink, width: 3),
          ),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -10,
                  child: Text('✏︎',
                      style: TextStyle(
                          fontSize: 150,
                          color: _D04C.blue.withOpacity(0.10))),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _D04Ink('DRAW\nHERE',
                          size: 46,
                          amt: mis,
                          align: TextAlign.center,
                          back: _D04C.pink,
                          front: _D04C.ink.withOpacity(0.85)),
                      const SizedBox(height: 12),
                      const _D04Tag('한 획으로 마음을 그려 보내기',
                          fill: _D04C.blue, fg: _D04C.cream),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 12,
                  child: Text('no.${widget.data.couple.streakDays}',
                      style: TextStyle(
                          color: _D04C.ink.withOpacity(0.4),
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _modeBtn(SendMode m, String label, IconData icon) {
    final on = mode == m;
    return _D04Hard(
      onTap: () => setState(() => mode = m),
      fill: on ? _D04C.blue : _D04C.paper,
      shadow: on ? _D04C.pink : _D04C.cream,
      drop: on ? 5 : 2,
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: on ? _D04C.cream : _D04C.ink),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: on ? _D04C.cream : _D04C.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, Color shadow) {
    return _D04Hard(
      onTap: () {},
      fill: _D04C.paper,
      shadow: shadow,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _D04C.ink, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: _D04C.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

// ==================================================================== PET HOME

class _D04Pet extends StatefulWidget {
  const _D04Pet({required this.data});
  final AppData data;
  @override
  State<_D04Pet> createState() => _D04PetState();
}

class _D04PetState extends State<_D04Pet> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool patted = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((e) => e.equipped).toList();
    final filled = (pet.growth * 14).round();

    return _D04Scaffold(
      seed: 43,
      bottom: const _D04Nav(current: 0),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_c.value);
          final mis = 13.5 * (1 - t) + 2.6;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- masthead ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _D04Tag('OUR PET · Lv.', fill: _D04C.blue, fg: _D04C.cream),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _D04Ink(pet.name, size: 40, amt: mis),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: _D04Tag('Lv.${pet.level}',
                                    fill: _D04C.pink, fg: _D04C.ink, size: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _D04Hard(
                      fill: _D04C.paper,
                      shadow: _D04C.pink,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 5),
                          Text('${pet.coins}',
                              style: const TextStyle(
                                  color: _D04C.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ---- pet stage ----
              Expanded(child: _stage(pet, equipped, mis)),
              // ---- growth ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _D04Tag('GROWTH'),
                        const Spacer(),
                        Text('다음 레벨까지 ${(pet.growth * 100).round()}%',
                            style: const TextStyle(
                                color: _D04C.ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (int i = 0; i < 14; i++)
                          Expanded(
                            child: Container(
                              height: 16,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: i < filled ? _D04C.blue : _D04C.paper,
                                border:
                                    Border.all(color: _D04C.ink, width: 1.6),
                              ),
                              child: i < filled && i == filled - 1
                                  ? Transform.translate(
                                      offset: const Offset(1.5, 1.5),
                                      child: Container(color: _D04C.pink))
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // ---- store ----
              _store(pet),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _stage(Pet pet, List<PetItem> equipped, double mis) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // speech bubble
          AnimatedOpacity(
            opacity: patted ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: _D04Hard(
              fill: _D04C.paper,
              shadow: _D04C.pink,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text('“${pet.speech}”',
                  style: const TextStyle(
                      color: _D04C.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(height: 14),
          // pet + equipped hat overlay
          GestureDetector(
            onTap: () => setState(() => patted = !patted),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // ink halo behind pet
                Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _D04C.pink.withOpacity(0.25),
                    border: Border.all(color: _D04C.ink, width: 3),
                  ),
                ),
                Transform.translate(
                  offset: Offset(mis * 0.4, mis * 0.4),
                  child: Text(pet.moodEmoji,
                      style: TextStyle(
                          fontSize: 96,
                          color: _D04C.blue.withOpacity(0.25))),
                ),
                Text(pet.moodEmoji, style: const TextStyle(fontSize: 96)),
                if (equipped.any((e) => e.category == '모자'))
                  Positioned(
                    top: -6,
                    child: Text(
                      equipped.firstWhere((e) => e.category == '모자').emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                if (equipped.any((e) => e.category == '소품'))
                  Positioned(
                    right: -8,
                    bottom: -4,
                    child: Text(
                      equipped.firstWhere((e) => e.category == '소품').emoji,
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _D04Tag(patted ? 'PAT · 몽이가 말했어요' : 'TAP · 쓰다듬어 보세요',
              fill: patted ? _D04C.pink : _D04C.ink,
              fg: patted ? _D04C.ink : _D04C.cream),
          if (equipped.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('착용중  ${equipped.map((e) => e.emoji).join('  ')}',
                style: const TextStyle(
                    color: _D04C.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _store(Pet pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const _D04Tag('STORE', fill: _D04C.pink, fg: _D04C.ink),
              const SizedBox(width: 8),
              Text('꾸미기 · ${pet.store.length}종',
                  style: const TextStyle(
                      color: _D04C.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: pet.store.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final it = pet.store[i];
              final on = it.equipped;
              return _D04Hard(
                onTap: () {},
                fill: on ? _D04C.blue : _D04C.paper,
                shadow: on ? _D04C.pink : (it.owned ? _D04C.blue : _D04C.pink),
                drop: on ? 5 : 3,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: SizedBox(
                  width: 74,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(it.emoji, style: const TextStyle(fontSize: 30)),
                      const SizedBox(height: 4),
                      Text(it.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: on ? _D04C.cream : _D04C.ink)),
                      const SizedBox(height: 4),
                      _D04Tag(
                        it.owned ? (on ? '착용중' : '보유') : '🪙${it.price}',
                        fill: on
                            ? _D04C.pink
                            : (it.owned ? _D04C.ink : _D04C.blue),
                        fg: on ? _D04C.ink : _D04C.cream,
                        size: 10,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ================================================================ MEMORY ALBUM

class _D04Album extends StatefulWidget {
  const _D04Album({required this.data});
  final AppData data;
  @override
  State<_D04Album> createState() => _D04AlbumState();
}

class _D04AlbumState extends State<_D04Album>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool byDate = true;
  DoodleType? filter;
  int shuffleSeed = 0; // 0 = sorted; >0 = shuffled zine spread

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _shuffle() {
    setState(() => shuffleSeed += 1);
    _c.forward(from: 0); // ink re-settles into register
  }

  List<Doodle> get _items {
    var list = widget.data.album
        .where((d) => filter == null || d.type == filter)
        .toList();
    if (shuffleSeed > 0) {
      final rng = _D04Rng(shuffleSeed * 911 + 7);
      for (int i = list.length - 1; i > 0; i--) {
        final j = rng.pick(i + 1);
        final tmp = list[i];
        list[i] = list[j];
        list[j] = tmp;
      }
    } else if (byDate) {
      list.sort((a, b) => b.at.compareTo(a.at));
    } else {
      list.sort((a, b) => a.type.index.compareTo(b.type.index));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return _D04Scaffold(
      seed: 71,
      bottom: const _D04Nav(current: 1),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_c.value);
          final mis = 13.5 * (1 - t) + 2.6;
          final items = _items;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- masthead ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _D04Tag('MEMORY ZINE',
                              fill: _D04C.pink, fg: _D04C.ink),
                          const SizedBox(height: 4),
                          _D04Ink('낙서\n사진첩',
                              size: 38, amt: mis, back: _D04C.pink),
                        ],
                      ),
                    ),
                    // sort toggle
                    _D04Hard(
                      onTap: () => setState(() {
                        byDate = !byDate;
                        shuffleSeed = 0;
                      }),
                      fill: _D04C.paper,
                      shadow: _D04C.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(byDate ? Icons.event_rounded : Icons.category_rounded,
                              size: 16, color: _D04C.ink),
                          const SizedBox(height: 3),
                          Text(byDate ? '날짜별' : '유형별',
                              style: const TextStyle(
                                  color: _D04C.ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ---- shake to shuffle (signature) ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _D04Hard(
                  onTap: _shuffle,
                  fill: _D04C.blue,
                  shadow: _D04C.pink,
                  drop: 5,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Transform.rotate(
                        angle: _rad(shuffleSeed.isEven ? -12 : 12),
                        child: const Icon(Icons.vibration_rounded,
                            color: _D04C.cream, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('흔들어 셔플 — 새 zine 스프레드로 재조판',
                            style: TextStyle(
                                color: _D04C.cream,
                                fontWeight: FontWeight.w900,
                                fontSize: 14)),
                      ),
                      _D04Tag(
                          shuffleSeed == 0 ? 'SHAKE' : 'v.${shuffleSeed + 1}',
                          fill: _D04C.pink,
                          fg: _D04C.ink,
                          size: 11),
                    ],
                  ),
                ),
              ),
              // ---- type filters ----
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filter('전체', null),
                    for (final ty in DoodleType.values) _filter(ty.label, ty),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // ---- zine spread ----
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: _D04Tag('이 유형의 낙서가 없어요',
                            fill: _D04C.ink, fg: _D04C.cream, size: 13),
                      )
                    : LayoutBuilder(
                        builder: (context, cons) {
                          final cardW = (cons.maxWidth - 32 - 12) / 2;
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                for (int i = 0; i < items.length; i++)
                                  _card(items[i], i, cardW, mis),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filter(String label, DoodleType? ty) {
    final on = filter == ty;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _D04Hard(
        onTap: () => setState(() {
          filter = ty;
          shuffleSeed = 0;
        }),
        fill: on ? _D04C.ink : _D04C.paper,
        shadow: on ? _D04C.pink : _D04C.cream,
        drop: on ? 4 : 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ty != null)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(ty.icon,
                    size: 14, color: on ? _D04C.cream : _D04C.ink),
              ),
            Text(label,
                style: TextStyle(
                    color: on ? _D04C.cream : _D04C.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _card(Doodle d, int i, double w, double mis) {
    // per-card jitter, re-rolled on each shuffle
    final jr = _D04Rng((shuffleSeed + 1) * 131 + i * 17);
    final rot = jr.range(-3.2, 3.2);
    final tall = [148.0, 186.0, 166.0, 204.0][jr.pick(4)];
    final shadowColor = jr.flip() ? _D04C.blue : _D04C.pink;

    return Transform.rotate(
      angle: _rad(rot),
      child: SizedBox(
        width: w,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // second-ink offset plate
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(shuffleSeed > 0 ? mis * 0.5 + 3 : 5,
                    shuffleSeed > 0 ? mis * 0.5 + 3 : 5),
                child: DecoratedBox(
                    decoration: BoxDecoration(color: shadowColor)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: _D04C.paper,
                border: Border.all(color: _D04C.ink, width: 2.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // image swatch
                  Container(
                    height: tall,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: d.swatch,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: const Border(
                          bottom: BorderSide(color: _D04C.ink, width: 2.4)),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(d.emoji,
                              style: const TextStyle(fontSize: 56)),
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            color: _D04C.ink,
                            child: Icon(d.type.icon,
                                size: 13, color: _D04C.cream),
                          ),
                        ),
                        if (d.liked)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(Icons.favorite,
                                size: 18, color: _D04C.pink),
                          ),
                        if (d.mode == SendMode.disappearing)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: _D04Tag('사라짐',
                                fill: _D04C.blue, fg: _D04C.cream, size: 9),
                          ),
                      ],
                    ),
                  ),
                  // info bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _D04C.ink,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _D04Tag(d.author,
                                fill: d.author == '나'
                                    ? _D04C.blue
                                    : _D04C.pink,
                                fg: d.author == '나'
                                    ? _D04C.cream
                                    : _D04C.ink,
                                size: 9.5),
                            const Spacer(),
                            Text('${d.at.month}/${d.at.day}',
                                style: TextStyle(
                                    color: _D04C.ink.withOpacity(0.6),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
