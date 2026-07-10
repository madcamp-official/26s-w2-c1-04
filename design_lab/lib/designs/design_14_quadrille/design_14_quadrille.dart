// design_14_quadrille — "Quadrille".
//
// Pale engineer's plotting paper. The coolest, most technical of the calm
// siblings: doodles feel plotted, the pet sits on a coordinate, labels are
// cold monospace coordinates over a light grotesque body. Calm through
// precision — content snaps to a faint 5mm lattice and everything breathes at
// very low contrast.
//
// The ONE quiet signature: a faint 5mm graph lattice that fades in ONLY under
// active content and breathes at very low contrast. The grid is the ornament —
// it stands in for Quiet Signal's single ruled baseline.
//
// Self-contained: no external packages, no assets, no network, no Random,
// no DateTime.now(). Imagery is gradient + emoji from shared demo data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ---------------------------------------------------------------- palette
const Color _d14Ground = Color(0xFFF0F0EC); // Chalk
const Color _d14Panel = Color(0xFFF4F4F0); // slightly lighter plate under content
const Color _d14Grid = Color(0xFFDFE1DB); // grid-line
const Color _d14Ink = Color(0xFF2C2E2C); // Graphite
const Color _d14Prussian = Color(0xFF6E7F8A); // Dusty Prussian (only accent)

Color _d14InkA(double a) => _d14Ink.withOpacity(a);
Color _d14PruA(double a) => _d14Prussian.withOpacity(a);

// cold monospace — labels & coordinates.
TextStyle _d14Mono({
  double size = 11,
  Color color = _d14Ink,
  FontWeight weight = FontWeight.w500,
  double spacing = 1.6,
}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.3,
    );

// light grotesque — body / captions.
TextStyle _d14Sans({
  double size = 14,
  Color color = _d14Ink,
  FontWeight weight = FontWeight.w300,
  double spacing = 0.2,
  double height = 1.45,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

class Design14 extends DesignVariant {
  @override
  String get id => '14';
  @override
  String get name => 'Quadrille';
  @override
  String get concept =>
      '창백한 엔지니어 방안지 — 낙서는 plot 되고, 펫은 좌표 위에 앉는다. 가장 차갑고 기술적인 정적: 정밀함으로 얻는 고요.';
  @override
  String get signature =>
      '희미한 5mm 격자 격판이 활성 콘텐츠 아래에서만 페이드인되어 아주 낮은 대비로 호흡한다 — 격자가 유일한 장식이며, 단 한 줄의 괘선을 대신한다.';
  @override
  String get inspiration =>
      'Engineer\'s quadrille / plotting paper · coordinate grids · monospace CAD labels';
  @override
  Color get accent => _d14Prussian;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d14Sans(),
      child: switch (screen) {
        HeroScreen.drawSend => _D14DrawSend(data: data),
        HeroScreen.petHome => _D14PetHome(data: data),
        HeroScreen.memoryAlbum => _D14Album(data: data),
      },
    );
  }
}

// ======================================================= signature: breathing lattice
// The lone ornament. A faint 5mm grid that fades in under active content and
// breathes at very low contrast. Fine lines every cell, a slightly firmer line
// every 5 cells (1cm), all clipped inside the host container.
class _D14Lattice extends StatefulWidget {
  const _D14Lattice({this.cell = 22, this.axis = false});
  final double cell;
  final bool axis; // draw a faint prussian origin cross (bottom-left)
  @override
  State<_D14Lattice> createState() => _D14LatticeState();
}

class _D14LatticeState extends State<_D14Lattice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        // very low contrast breath: 0.40 .. 0.85 multiplier
        final breath = 0.40 + 0.45 * _c.value;
        return CustomPaint(
          painter: _D14LatticePainter(
            cell: widget.cell,
            breath: breath,
            axis: widget.axis,
          ),
        );
      },
    );
  }
}

class _D14LatticePainter extends CustomPainter {
  _D14LatticePainter({
    required this.cell,
    required this.breath,
    required this.axis,
  });
  final double cell;
  final double breath;
  final bool axis;

  @override
  void paint(Canvas canvas, Size size) {
    final fine = Paint()
      ..color = _d14Grid.withOpacity(0.55 * breath)
      ..strokeWidth = 1;
    final firm = Paint()
      ..color = _d14Grid.withOpacity(0.95 * breath)
      ..strokeWidth = 1;

    int i = 0;
    for (double x = 0; x <= size.width + 0.5; x += cell, i++) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % 5 == 0 ? firm : fine);
    }
    int j = 0;
    for (double y = 0; y <= size.height + 0.5; y += cell, j++) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), j % 5 == 0 ? firm : fine);
    }

    if (axis) {
      final ap = Paint()
        ..color = _d14PruA(0.20 * breath + 0.05)
        ..strokeWidth = 1;
      // origin cross near bottom-left
      final ox = cell;
      final oy = size.height - cell;
      canvas.drawLine(Offset(ox, cell * 0.5), Offset(ox, size.height - cell * 0.5), ap);
      canvas.drawLine(Offset(cell * 0.5, oy), Offset(size.width - cell * 0.5, oy), ap);
    }
  }

  @override
  bool shouldRepaint(covariant _D14LatticePainter old) =>
      old.breath != breath || old.cell != cell || old.axis != axis;
}

// A plotted plate: rounded container whose active field carries the breathing
// lattice, clipped to the corner radius.
class _D14Plate extends StatelessWidget {
  const _D14Plate({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.cell = 22,
    this.axis = false,
    this.tick = false,
  });
  final Widget child;
  final EdgeInsets padding;
  final double cell;
  final bool axis;
  final bool tick; // corner registration ticks

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _d14Panel,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _d14InkA(0.14)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            Positioned.fill(child: _D14Lattice(cell: cell, axis: axis)),
            if (tick) ...const [
              Positioned(top: 8, left: 8, child: _D14Tick()),
              Positioned(top: 8, right: 8, child: _D14Tick()),
              Positioned(bottom: 8, left: 8, child: _D14Tick()),
              Positioned(bottom: 8, right: 8, child: _D14Tick()),
            ],
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

// small registration crosshair (plotting print feel)
class _D14Tick extends StatelessWidget {
  const _D14Tick();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 9,
      height: 9,
      child: CustomPaint(painter: _D14TickPainter()),
    );
  }
}

class _D14TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _d14PruA(0.45)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), p);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------- small parts
class _D14Hair extends StatelessWidget {
  const _D14Hair({this.opacity = 0.10});
  final double opacity;
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _d14InkA(opacity));
}

// spaced mono eyebrow, e.g. "· INK"
class _D14Eyebrow extends StatelessWidget {
  const _D14Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: _d14Mono(size: 9.5, color: _d14InkA(0.55), spacing: 2.4));
  }
}

// a mono coordinate tag, e.g. "x03·y07"
class _D14Coord extends StatelessWidget {
  const _D14Coord(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: _d14PruA(0.08),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d14PruA(0.30)),
      ),
      child: Text(text,
          style: _d14Mono(size: 9.5, color: _d14PruA(0.95), spacing: 1)),
    );
  }
}

class _D14IconTap extends StatelessWidget {
  const _D14IconTap({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: _d14InkA(0.7)),
      ),
    );
  }
}

// ================================================================== Draw & Send
class _D14DrawSend extends StatefulWidget {
  const _D14DrawSend({required this.data});
  final AppData data;
  @override
  State<_D14DrawSend> createState() => _D14DrawSendState();
}

class _D14DrawSendState extends State<_D14DrawSend> {
  int pen = 0;
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    return Scaffold(
      backgroundColor: _d14Ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- top bar: back / recipient / send
              Row(
                children: [
                  _D14IconTap(
                    icon: Icons.arrow_back,
                    onTap: () => HapticFeedback.selectionClick(),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _D14Eyebrow('· TO'),
                      const SizedBox(height: 3),
                      Text(couple.partnerNickname,
                          style: _d14Sans(
                              size: 17, weight: FontWeight.w400, spacing: 1.2)),
                    ],
                  ),
                  const Spacer(),
                  _D14SendButton(onTap: () => HapticFeedback.mediumImpact()),
                ],
              ),
              const SizedBox(height: 16),
              // ---- the plotting canvas (active content → lattice + axis)
              Expanded(child: _canvas()),
              const SizedBox(height: 18),
              // ---- pen colors
              const _D14Eyebrow('· INK'),
              const SizedBox(height: 12),
              _penRow(),
              const SizedBox(height: 20),
              // ---- thickness
              Row(
                children: [
                  const _D14Eyebrow('· WEIGHT'),
                  const Spacer(),
                  Text('${thickness.round().toString().padLeft(2, '0')} px',
                      style: _d14Mono(size: 10, color: _d14Prussian, spacing: 1)),
                ],
              ),
              const SizedBox(height: 10),
              _D14Thickness(
                value: thickness,
                color: demoPenColors[pen],
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => thickness = v);
                },
              ),
              const SizedBox(height: 18),
              const _D14Hair(),
              const SizedBox(height: 14),
              // ---- mode toggle + description
              _modeToggle(),
              const SizedBox(height: 10),
              Text(mode.description,
                  style: _d14Sans(size: 12, color: _d14InkA(0.55))),
              const SizedBox(height: 16),
              // ---- bottom actions
              _bottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvas() {
    final ink = demoPenColors[pen];
    return _D14Plate(
      padding: const EdgeInsets.all(14),
      cell: 22,
      axis: true,
      tick: true,
      child: Stack(
        children: [
          // origin coordinate label (bottom-left)
          Positioned(
            left: 2,
            bottom: 2,
            child: Text('0,0',
                style: _d14Mono(size: 9, color: _d14PruA(0.7), spacing: 0.5)),
          ),
          // top-right field id
          Positioned(
            right: 2,
            top: 2,
            child: Text('PLOT · 5mm',
                style: _d14Mono(size: 9, color: _d14InkA(0.35), spacing: 1)),
          ),
          // one plotted mark on an intersection
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('여기에 plot',
                        style: _d14Sans(size: 15, color: _d14InkA(0.42))),
                    const SizedBox(width: 8),
                    _D14Crosshair(color: ink),
                  ],
                ),
                const SizedBox(height: 18),
                // stroke preview — a single plotted line of chosen ink
                Container(
                  width: 110,
                  height: thickness.clamp(2, 20),
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _penRow() {
    return Row(
      children: [
        for (int i = 0; i < demoPenColors.length; i++) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => pen = i);
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: demoPenColors[i],
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: pen == i ? _d14Ink : _d14InkA(0.15),
                      width: pen == i ? 1.5 : 1,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(i.toString().padLeft(2, '0'),
                    style: _d14Mono(
                        size: 8.5,
                        color: pen == i ? _d14Prussian : _d14InkA(0.35),
                        spacing: 0.5)),
              ],
            ),
          ),
          if (i != demoPenColors.length - 1) const Spacer(),
        ],
      ],
    );
  }

  Widget _modeToggle() {
    return Row(
      children: [
        for (final m in SendMode.values) ...[
          _D14ModeTab(
            label: m.label,
            selected: mode == m,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => mode = m);
            },
          ),
          if (m != SendMode.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _bottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _D14Action(
            glyph: '🖼', label: '갤러리', onTap: () => HapticFeedback.selectionClick()),
        _D14Action(
            glyph: '📷', label: '사진', onTap: () => HapticFeedback.selectionClick()),
        _D14Action(
            glyph: '✦',
            label: '찌르기',
            accent: true,
            onTap: () => HapticFeedback.heavyImpact()),
      ],
    );
  }
}

// a plotted point crosshair
class _D14Crosshair extends StatelessWidget {
  const _D14Crosshair({required this.color, this.size = 20});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _D14CrosshairPainter(color)),
    );
  }
}

class _D14CrosshairPainter extends CustomPainter {
  _D14CrosshairPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, size.height), p);
    canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), p);
    canvas.drawCircle(c, size.width * 0.24, p);
  }

  @override
  bool shouldRepaint(covariant _D14CrosshairPainter old) => old.color != color;
}

class _D14SendButton extends StatelessWidget {
  const _D14SendButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: _d14Ink,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('보내기',
                style: _d14Mono(
                    size: 11, color: _d14Ground, spacing: 2, weight: FontWeight.w600)),
            const SizedBox(width: 8),
            _D14Crosshair(color: _d14Prussian, size: 12),
          ],
        ),
      ),
    );
  }
}

class _D14ModeTab extends StatelessWidget {
  const _D14ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                _D14Crosshair(color: _d14Prussian, size: 11),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: _d14Sans(
                    size: 14,
                    color: selected ? _d14Ink : _d14InkA(0.4),
                    weight: selected ? FontWeight.w400 : FontWeight.w300,
                    spacing: 0.8,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 48,
            color: selected ? _d14Prussian : _d14InkA(0.08),
          ),
        ],
      ),
    );
  }
}

// custom minimal thickness slider — the thumb is a plotted tick on the grid
class _D14Thickness extends StatelessWidget {
  const _D14Thickness({
    required this.value,
    required this.color,
    required this.onChanged,
  });
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        void update(double dx) {
          final t = (dx / w).clamp(0.0, 1.0);
          onChanged(1 + t * 19);
        }

        final t = ((value - 1) / 19).clamp(0.0, 1.0);
        return GestureDetector(
          onTapDown: (d) => update(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 30,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(width: w, height: 1, color: _d14InkA(0.14)),
                Container(width: t * w, height: 2, color: _d14PruA(0.7)),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 3,
                    height: 24,
                    color: _d14Ink,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: value.clamp(3, 20),
                    height: value.clamp(3, 20),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _D14Action extends StatelessWidget {
  const _D14Action({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.accent = false,
  });
  final String glyph;
  final String label;
  final VoidCallback onTap;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ? _d14PruA(0.12) : _d14Panel,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                  color: accent ? _d14PruA(0.45) : _d14InkA(0.10)),
            ),
            child: Text(glyph,
                style: TextStyle(
                    fontSize: accent ? 18 : 22,
                    color: accent ? _d14Prussian : null)),
          ),
          const SizedBox(height: 7),
          Text(label,
              style: _d14Mono(
                  size: 9.5,
                  color: accent ? _d14Prussian : _d14InkA(0.65),
                  spacing: 1.4)),
        ],
      ),
    );
  }
}

// ==================================================================== Pet Home
class _D14PetHome extends StatefulWidget {
  const _D14PetHome({required this.data});
  final AppData data;
  @override
  State<_D14PetHome> createState() => _D14PetHomeState();
}

class _D14PetHomeState extends State<_D14PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    // deterministic plotted coordinate from data (no Random)
    final px = pet.name.length + 2; // 몽이 -> 4
    final py = pet.level; // 7
    return Scaffold(
      backgroundColor: _d14Ground,
      body: SafeArea(
        child: Column(
          children: [
            // ---- top bar: name / Lv / coins
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _D14Eyebrow('· SPECIMEN'),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(pet.name,
                              style: _d14Sans(
                                  size: 20, weight: FontWeight.w400, spacing: 0.8)),
                          const SizedBox(width: 8),
                          Text('LV.${pet.level}',
                              style: _d14Mono(
                                  size: 11, color: _d14Prussian, spacing: 1.4)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  _D14Coins(coins: pet.coins),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ---- the plotting stage: the pet sits on a coordinate
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _D14Plate(
                  padding: const EdgeInsets.fromLTRB(30, 16, 14, 26),
                  cell: 24,
                  axis: true,
                  child: Stack(
                    children: [
                      // left axis ticks
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: _D14AxisColumn(),
                      ),
                      // bottom axis ticks
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _D14AxisRow(),
                      ),
                      // coordinate readout, top-right
                      Positioned(
                        right: 2,
                        top: 2,
                        child: _D14Coord(
                            'P(${px.toString().padLeft(2, '0')},${py.toString().padLeft(2, '0')})'),
                      ),
                      // the pet, plotted at an intersection
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(opacity: anim, child: child),
                              child: patted
                                  ? _D14SpeechSlip(text: pet.speech)
                                  : const SizedBox(height: 46, key: ValueKey('empty')),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => patted = !patted);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // plotted crosshair the pet sits on
                                  _D14Crosshair(color: _d14PruA(0.5), size: 132),
                                  Text(pet.moodEmoji,
                                      style: const TextStyle(fontSize: 72)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (equipped.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('EQUIP',
                                      style: _d14Mono(
                                          size: 8.5,
                                          color: _d14InkA(0.45),
                                          spacing: 1.8)),
                                  const SizedBox(width: 10),
                                  for (final e in equipped) ...[
                                    Text(e.emoji,
                                        style: const TextStyle(fontSize: 17)),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            const SizedBox(height: 6),
                            Text('쓰다듬어 좌표에 신호 남기기',
                                style: _d14Sans(
                                    size: 12, color: _d14InkA(0.45))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // ---- growth gauge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _D14Growth(growth: pet.growth),
            ),
            const SizedBox(height: 16),
            // ---- store row
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Row(
                children: [
                  const _D14Eyebrow('· STORE'),
                  const Spacer(),
                  Text('전체보기',
                      style: _d14Mono(
                          size: 9, color: _d14InkA(0.45), spacing: 1.4)),
                ],
              ),
            ),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                itemCount: pet.store.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _D14StoreCard(
                  item: pet.store[i],
                  onTap: () => HapticFeedback.selectionClick(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _D14Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

// faint mono numerals up the left edge
class _D14AxisColumn extends StatelessWidget {
  const _D14AxisColumn();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final n in const [8, 6, 4, 2, 0])
          Text(n.toString(),
              style: _d14Mono(size: 8, color: _d14PruA(0.45), spacing: 0)),
      ],
    );
  }
}

// faint mono numerals along the bottom edge
class _D14AxisRow extends StatelessWidget {
  const _D14AxisRow();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final n in const [0, 2, 4, 6, 8])
            Text(n.toString(),
                style: _d14Mono(size: 8, color: _d14PruA(0.45), spacing: 0)),
        ],
      ),
    );
  }
}

class _D14Coins extends StatelessWidget {
  const _D14Coins({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _d14Panel,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d14InkA(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Text('$coins',
              style: _d14Mono(size: 12, weight: FontWeight.w600, spacing: 0.5)),
        ],
      ),
    );
  }
}

class _D14SpeechSlip extends StatelessWidget {
  const _D14SpeechSlip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('speech'),
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _d14Ground,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d14PruA(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _D14Crosshair(color: _d14Prussian, size: 11),
          const SizedBox(width: 10),
          Flexible(
            child: Text(text,
                textAlign: TextAlign.center,
                style: _d14Sans(size: 13, weight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }
}

class _D14Growth extends StatelessWidget {
  const _D14Growth({required this.growth});
  final double growth;
  @override
  Widget build(BuildContext context) {
    final pct = (growth * 100).round();
    return Column(
      children: [
        Row(
          children: [
            Text('NEXT LV',
                style: _d14Mono(size: 8.5, color: _d14InkA(0.5), spacing: 1.6)),
            const Spacer(),
            Text('$pct%',
                style: _d14Mono(size: 10, color: _d14Prussian, spacing: 0.5)),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return Stack(
              children: [
                Container(width: w, height: 3, color: _d14InkA(0.10)),
                Container(
                    width: w * growth.clamp(0.0, 1.0),
                    height: 3,
                    color: _d14Prussian),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _D14StoreCard extends StatelessWidget {
  const _D14StoreCard({required this.item, required this.onTap});
  final PetItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: item.equipped ? _d14PruA(0.10) : _d14Panel,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: item.equipped ? _d14PruA(0.5) : _d14InkA(0.10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _d14Sans(size: 11, spacing: 0.2)),
            const SizedBox(height: 6),
            _statusLine(item),
          ],
        ),
      ),
    );
  }

  Widget _statusLine(PetItem it) {
    if (it.equipped) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _D14Crosshair(color: _d14Prussian, size: 9),
          const SizedBox(width: 5),
          Text('착용중',
              style: _d14Mono(size: 8.5, color: _d14Prussian, spacing: 0.8)),
        ],
      );
    }
    if (it.owned) {
      return Text('보유',
          style: _d14Mono(size: 8.5, color: _d14InkA(0.45), spacing: 1.4));
    }
    return Text('🪙 ${it.price}',
        style: _d14Mono(size: 8.5, color: _d14InkA(0.6), spacing: 0.5));
  }
}

// ================================================================ Memory Album
class _D14Album extends StatefulWidget {
  const _D14Album({required this.data});
  final AppData data;
  @override
  State<_D14Album> createState() => _D14AlbumState();
}

class _D14AlbumState extends State<_D14Album> {
  bool byDate = true;
  DoodleType? filter;

  @override
  Widget build(BuildContext context) {
    final all = widget.data.album;
    final items =
        all.where((d) => filter == null || d.type == filter).toList();
    return Scaffold(
      backgroundColor: _d14Ground,
      body: SafeArea(
        child: Column(
          children: [
            // ---- header: title + sort toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _D14Eyebrow('· LOG'),
                      const SizedBox(height: 4),
                      Text('낙서 사진첩',
                          style: _d14Sans(
                              size: 20, weight: FontWeight.w400, spacing: 0.8)),
                    ],
                  ),
                  const Spacer(),
                  _D14SortToggle(
                    byDate: byDate,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => byDate = !byDate);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ---- type filters
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                children: [
                  _D14FilterChip(
                    label: '전체',
                    selected: filter == null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => filter = null);
                    },
                  ),
                  for (final t in DoodleType.values)
                    _D14FilterChip(
                      label: t.label,
                      selected: filter == t,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => filter = t);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ---- the plotted log (active content → lattice underlay)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                child: _D14Plate(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  cell: 22,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 3),
                      child: _D14Hair(opacity: 0.07),
                    ),
                    itemBuilder: (_, i) =>
                        _D14MemoryRow(doodle: items[i], index: i),
                  ),
                ),
              ),
            ),
            const _D14Nav(current: 1),
          ],
        ),
      ),
    );
  }
}

class _D14SortToggle extends StatelessWidget {
  const _D14SortToggle({required this.byDate, required this.onTap});
  final bool byDate;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? _d14Ink : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
          ),
          child: Text(label,
              style: _d14Mono(
                size: 9,
                color: on ? _d14Ground : _d14InkA(0.45),
                spacing: 1.2,
              )),
        );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: _d14InkA(0.12)),
        ),
        child: Row(
          children: [
            seg('날짜별', byDate),
            const SizedBox(width: 2),
            seg('유형별', !byDate),
          ],
        ),
      ),
    );
  }
}

class _D14FilterChip extends StatelessWidget {
  const _D14FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _d14PruA(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
            border: Border.all(
              color: selected ? _d14PruA(0.5) : _d14InkA(0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                _D14Crosshair(color: _d14Prussian, size: 9),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: _d14Mono(
                    size: 10,
                    color: selected ? _d14Ink : _d14InkA(0.55),
                    weight: selected ? FontWeight.w600 : FontWeight.w500,
                    spacing: 1,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// a single plotted memory line
class _D14MemoryRow extends StatelessWidget {
  const _D14MemoryRow({required this.doodle, required this.index});
  final Doodle doodle;
  final int index;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // plotted index coordinate
          SizedBox(
            width: 26,
            child: Text('#${index.toString().padLeft(2, '0')}',
                style: _d14Mono(size: 8.5, color: _d14PruA(0.7), spacing: 0.2)),
          ),
          // subtle swatch + emoji
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  d.swatch.first.withOpacity(0.55),
                  d.swatch.last.withOpacity(0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _d14InkA(0.08)),
            ),
            child: Text(d.emoji, style: const TextStyle(fontSize: 23)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d14Sans(
                        size: 15, weight: FontWeight.w400, spacing: 0.2)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(d.type.label,
                        style: _d14Mono(
                            size: 8.5, color: _d14PruA(0.85), spacing: 0.6)),
                    const SizedBox(width: 8),
                    Text('·', style: _d14Mono(size: 8.5, color: _d14InkA(0.3))),
                    const SizedBox(width: 8),
                    Text(
                        '${d.author} · ${d.at.month.toString().padLeft(2, '0')}/${d.at.day.toString().padLeft(2, '0')}',
                        style: _d14Mono(
                            size: 8.5, color: _d14InkA(0.5), spacing: 0.6)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 18,
            child: d.liked
                ? Text('♥',
                    style: TextStyle(fontSize: 14, color: _d14PruA(0.9)))
                : Text('♡',
                    style: TextStyle(fontSize: 14, color: _d14InkA(0.22))),
          ),
        ],
      ),
    );
  }
}

// ==================================================================== bottom nav
class _D14Nav extends StatelessWidget {
  const _D14Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      decoration: BoxDecoration(
        color: _d14Ground,
        border: Border(top: BorderSide(color: _d14InkA(0.10))),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < labels.length; i++)
            _navItem(labels[i], i == current),
        ],
      ),
    );
  }

  Widget _navItem(String label, bool active) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 11,
            child: active
                ? _D14Crosshair(color: _d14Prussian, size: 10)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: _d14Mono(
                size: 11,
                color: active ? _d14Ink : _d14InkA(0.4),
                weight: active ? FontWeight.w700 : FontWeight.w400,
                spacing: 1.4,
              )),
        ],
      ),
    );
  }
}
