// design_20_segment — "Segment".
//
// A quiet sibling of Quiet Signal, cooler and more clinical: each screen is ONE
// framed hardware unit on a porcelain panel — a labeled top strip, hairline
// seams, and content read like a calm device readout. Warmest white ground,
// coolest attitude. The single signature is a lone amber status LED that arms
// and pulses ONCE when a memory arrives, while tabular monospace counters tick
// over like a segment display. No other motion lives on the panel.
//
// Self-contained: Flutter Material only, no packages, no assets, no network,
// no Random, no DateTime.now(). Imagery is soft gradient + emoji from demo data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ---------------------------------------------------------------- palette
const Color _d20Ground = Color(0xFFF3F2EE); // porcelain
const Color _d20Dim = Color(0xFFEAE8E1); // dim strip tone
const Color _d20Field = Color(0xFFF8F7F3); // warmest-white readout surface
const Color _d20Ink = Color(0xFF232320); // graphite
const Color _d20Amber = Color(0xFFB26A3E); // muted signal-amber (only accent)

Color _d20InkA(double a) => _d20Ink.withOpacity(a);
Color _d20AmberA(double a) => _d20Amber.withOpacity(a);
// display-only softening — same hue, quieter presence (keeps swatches muted).
Color _d20Soft(Color c) => Color.lerp(c, _d20Ground, 0.24)!;

// tight neo-grotesque caps micro-label — the device-face voice.
TextStyle _d20Label({
  double size = 10,
  Color? color,
  double spacing = 1.6,
  FontWeight weight = FontWeight.w700,
}) =>
    TextStyle(
      fontSize: size,
      color: color ?? _d20Ink,
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.2,
    );

// tabular monospace numerals — segment-display readouts.
TextStyle _d20Num({
  double size = 12,
  Color? color,
  FontWeight weight = FontWeight.w500,
  double spacing = 0.5,
}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      color: color ?? _d20Ink,
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.2,
    );

// restrained sans for captions / body.
TextStyle _d20Body({
  double size = 14,
  Color? color,
  FontWeight weight = FontWeight.w400,
  double spacing = 0.2,
  double height = 1.4,
}) =>
    TextStyle(
      fontSize: size,
      color: color ?? _d20Ink,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

class Design20 extends DesignVariant {
  @override
  String get id => '20';
  @override
  String get name => 'Segment';
  @override
  String get concept =>
      '포슬린 패널 위 하나의 프레임 유닛 — 라벨 상단 스트립, 헤어라인 이음선, 조용한 하드웨어 계기판처럼 읽히는 화면. 가장 따뜻한 화이트, 가장 차가운 태도.';
  @override
  String get signature =>
      '기억이 도착하면 단 하나의 앰버 상태 LED가 무장하고 한 번만 맥동한다. 카운터는 세그먼트 디스플레이처럼 또각 넘어간다. 패널 위 다른 움직임은 없다.';
  @override
  String get inspiration =>
      'Lab instrument face · porcelain minimalism · single status LED + segment-display counters';
  @override
  Color get accent => _d20Amber;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d20Body(),
      child: switch (screen) {
        HeroScreen.drawSend => _D20DrawSend(data: data),
        HeroScreen.petHome => _D20PetHome(data: data),
        HeroScreen.memoryAlbum => _D20Album(data: data),
      },
    );
  }
}

// ================================================================= shared parts

// The framed hardware unit: a hairline-bordered panel with rounded corners.
class _D20Panel extends StatelessWidget {
  const _D20Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _d20Ground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _d20InkA(0.14)),
      ),
      child: child,
    );
  }
}

// A single 1px seam between fields.
class _D20Seam extends StatelessWidget {
  const _D20Seam({this.opacity = 0.11});
  final double opacity;
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _d20InkA(opacity));
}

// Tight caps micro-label.
class _D20Eyebrow extends StatelessWidget {
  const _D20Eyebrow(this.text, {this.color, this.spacing = 2, this.size = 9});
  final String text;
  final Color? color;
  final double spacing;
  final double size;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: _d20Label(
            size: size, color: color ?? _d20InkA(0.5), spacing: spacing),
      );
}

// THE signature — a lone amber status LED. Armed dim at rest; when [pulse] is
// true (a memory has arrived) it fires exactly ONE glow on mount, then settles
// back to its armed level. No repeating motion.
class _D20StatusLED extends StatefulWidget {
  const _D20StatusLED({this.pulse = true, this.size = 8});
  final bool pulse;
  final double size;
  @override
  State<_D20StatusLED> createState() => _D20StatusLEDState();
}

class _D20StatusLEDState extends State<_D20StatusLED>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    if (widget.pulse) {
      // one-shot: arm, glow once, settle — never repeats.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _glow(double v) {
    const rest = 0.35;
    if (!widget.pulse) return rest;
    if (v <= 0.30) return rest + (1 - rest) * Curves.easeOut.transform(v / 0.30);
    if (v <= 0.72) {
      return 1 - (1 - rest) * Curves.easeIn.transform((v - 0.30) / 0.42);
    }
    return rest;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final g = _glow(_c.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _d20AmberA(0.28 + 0.72 * g),
            boxShadow: [
              BoxShadow(
                color: _d20AmberA(0.55 * g),
                blurRadius: 7 * g,
                spreadRadius: 0.4,
              ),
            ],
          ),
        );
      },
    );
  }
}

// Tabular counter that ticks over ONCE (segment display powering on).
class _D20Odometer extends StatelessWidget {
  const _D20Odometer({
    required this.value,
    required this.style,
    this.suffix = '',
  });
  final int value;
  final TextStyle style;
  final String suffix;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
    );
  }
}

// Static segment / VU-style bar readout (no motion).
class _D20SegmentBar extends StatelessWidget {
  const _D20SegmentBar({required this.value, this.segments = 22, this.height = 8});
  final double value;
  final int segments;
  final double height;
  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0.0, 1.0) * segments).round();
    return Row(
      children: [
        for (int i = 0; i < segments; i++) ...[
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: i < filled ? _d20Amber : _d20InkA(0.10),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          if (i != segments - 1) const SizedBox(width: 2),
        ],
      ],
    );
  }
}

// Small square hardware icon button (device-face, not circular).
class _D20IconBtn extends StatelessWidget {
  const _D20IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _d20Field,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _d20InkA(0.14)),
        ),
        child: Icon(icon, size: 18, color: _d20InkA(0.7)),
      ),
    );
  }
}

// Two/N-option hardware segmented switch.
class _D20Segmented extends StatelessWidget {
  const _D20Segmented({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.expand = false,
  });
  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _d20Field,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _d20InkA(0.14)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++)
            _cell(i, options[i]),
        ],
      ),
    );
  }

  Widget _cell(int i, String label) {
    final active = i == selected;
    final child = GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelect(i);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        decoration: active
            ? BoxDecoration(
                color: _d20AmberA(0.13),
                borderRadius: BorderRadius.circular(3),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                    color: _d20Amber, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: _d20Label(
                size: 11,
                color: active ? _d20Ink : _d20InkA(0.42),
                spacing: 1,
                weight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
    return expand ? Expanded(child: child) : child;
  }
}

// ================================================================== Draw & Send
class _D20DrawSend extends StatefulWidget {
  const _D20DrawSend({required this.data});
  final AppData data;
  @override
  State<_D20DrawSend> createState() => _D20DrawSendState();
}

class _D20DrawSendState extends State<_D20DrawSend> {
  int pen = 0;
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    return Scaffold(
      backgroundColor: _d20Ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _D20Panel(
            child: Column(
              children: [
                _topStrip(couple.partnerNickname),
                const _D20Seam(),
                Expanded(child: _canvas()),
                const _D20Seam(),
                _controls(),
                const _D20Seam(),
                _actions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topStrip(String recipient) {
    return Container(
      color: _d20Dim,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          _D20IconBtn(
            icon: Icons.chevron_left,
            onTap: () => HapticFeedback.selectionClick(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _D20Eyebrow('TRANSMIT · SEG-01'),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('TO',
                        style: _d20Label(
                            size: 10, color: _d20Amber, spacing: 2)),
                    const SizedBox(width: 8),
                    Text(recipient,
                        style: _d20Body(size: 16, weight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _D20StatusLED(pulse: false, size: 7),
                  const SizedBox(width: 6),
                  const _D20Eyebrow('READY', spacing: 1.6),
                ],
              ),
              const SizedBox(height: 9),
              _sendBtn(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sendBtn() {
    return GestureDetector(
      onTap: () => HapticFeedback.mediumImpact(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _d20Ink,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('보내기',
                style: _d20Label(
                    size: 11, color: _d20Ground, spacing: 1.6)),
            const SizedBox(width: 8),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: _d20Amber, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _canvas() {
    final ink = _d20Soft(demoPenColors[pen]);
    return Container(
      width: double.infinity,
      color: _d20Field,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _D20GridPainter())),
          Positioned(
            top: 12,
            left: 14,
            child: const _D20Eyebrow('CANVAS'),
          ),
          Positioned(
            top: 12,
            right: 14,
            child: _D20Eyebrow('FIELD · A0',
                color: _d20InkA(0.32), spacing: 1.6),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('여기에 낙서',
                    style: _d20Body(size: 15, color: _d20InkA(0.34))),
                const SizedBox(height: 20),
                // a single mark of the chosen (softened) ink at chosen weight.
                Container(
                  width: 116,
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

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _D20Eyebrow('INK'),
          const SizedBox(height: 11),
          _penRow(),
          const SizedBox(height: 17),
          Row(
            children: [
              const _D20Eyebrow('WEIGHT'),
              const Spacer(),
              Text(thickness.round().toString().padLeft(2, '0'),
                  style: _d20Num(size: 12, color: _d20Amber)),
              Text('PT',
                  style: _d20Label(
                      size: 8, color: _d20InkA(0.4), spacing: 1.5)),
            ],
          ),
          const SizedBox(height: 9),
          _D20Weight(
            value: thickness,
            color: _d20Soft(demoPenColors[pen]),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => thickness = v);
            },
          ),
          const SizedBox(height: 17),
          const _D20Eyebrow('MODE'),
          const SizedBox(height: 9),
          _D20Segmented(
            options: [for (final m in SendMode.values) m.label],
            selected: SendMode.values.indexOf(mode),
            expand: true,
            onSelect: (i) => setState(() => mode = SendMode.values[i]),
          ),
          const SizedBox(height: 9),
          Text(mode.description,
              style: _d20Body(size: 12, color: _d20InkA(0.5))),
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
                    color: _d20Soft(demoPenColors[i]),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _d20InkA(0.16)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 3,
                  width: 16,
                  child: pen == i
                      ? Container(
                          decoration: BoxDecoration(
                            color: _d20Amber,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (i != demoPenColors.length - 1) const Spacer(),
        ],
      ],
    );
  }

  Widget _actions() {
    return Container(
      color: _d20Dim,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _D20ActionBtn(
            glyph: '🖼',
            label: '갤러리',
            onTap: () => HapticFeedback.selectionClick(),
          ),
          _D20ActionBtn(
            glyph: '📷',
            label: '사진',
            onTap: () => HapticFeedback.selectionClick(),
          ),
          _D20ActionBtn(
            glyph: '⚡',
            label: '찌르기',
            accent: true,
            onTap: () => HapticFeedback.heavyImpact(),
          ),
        ],
      ),
    );
  }
}

class _D20GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _d20InkA(0.04)
      ..strokeWidth = 1;
    const gap = 26.0;
    for (double x = gap; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = gap; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Minimal hardware weight slider — a track with a segment fill + block thumb.
class _D20Weight extends StatelessWidget {
  const _D20Weight({
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
                Container(width: w, height: 1, color: _d20InkA(0.14)),
                Container(width: t * w, height: 2, color: _d20AmberA(0.75)),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _d20Ink,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: value.clamp(3, 20),
                    height: value.clamp(3, 20),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
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

class _D20ActionBtn extends StatelessWidget {
  const _D20ActionBtn({
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
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ? _d20AmberA(0.12) : _d20Field,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: accent ? _d20AmberA(0.5) : _d20InkA(0.12)),
            ),
            child: Text(glyph, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: _d20Label(
                size: 10,
                color: accent ? _d20Amber : _d20InkA(0.62),
                spacing: 1.4,
              )),
        ],
      ),
    );
  }
}

// ==================================================================== Pet Home
class _D20PetHome extends StatefulWidget {
  const _D20PetHome({required this.data});
  final AppData data;
  @override
  State<_D20PetHome> createState() => _D20PetHomeState();
}

class _D20PetHomeState extends State<_D20PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    return Scaffold(
      backgroundColor: _d20Ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _D20Panel(
            child: Column(
              children: [
                _topStrip(pet),
                const _D20Seam(),
                Expanded(child: _body(pet, equipped)),
                const _D20Seam(),
                _store(pet),
                const _D20Seam(),
                const _D20Nav(current: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topStrip(Pet pet) {
    return Container(
      color: _d20Dim,
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _D20Eyebrow('COMPANION · SEG-02'),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(pet.name,
                        style: _d20Body(size: 20, weight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Text('LV.',
                        style: _d20Label(
                            size: 10, color: _d20Amber, spacing: 1)),
                    _D20Odometer(
                      value: pet.level,
                      style: _d20Num(size: 13, color: _d20Amber),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _D20StatusLED(pulse: true, size: 8),
                  const SizedBox(width: 6),
                  _D20Eyebrow('LIVE', color: _d20AmberA(0.9), spacing: 1.6),
                ],
              ),
              const SizedBox(height: 9),
              _coins(pet.coins),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coins(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _d20Field,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _d20InkA(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          _D20Odometer(
            value: coins,
            style: _d20Num(size: 12, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _body(Pet pet, List<PetItem> equipped) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: patted
                ? _D20SpeechSlip(text: pet.speech)
                : const SizedBox(height: 46, key: ValueKey('empty')),
          ),
          const SizedBox(height: 12),
          // device-face square viewport (not a circle).
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => patted = !patted);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 168,
              height: 168,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _d20Field,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _d20InkA(0.12)),
              ),
              child: Text(pet.moodEmoji,
                  style: const TextStyle(fontSize: 82)),
            ),
          ),
          const SizedBox(height: 14),
          if (equipped.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _D20Eyebrow('착용', color: _d20InkA(0.45), spacing: 2),
                const SizedBox(width: 10),
                for (final e in equipped) ...[
                  Text(e.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          const SizedBox(height: 10),
          Text('쓰다듬어 반응을 확인하기',
              style: _d20Body(size: 12, color: _d20InkA(0.45))),
          const SizedBox(height: 24),
          SizedBox(
            width: 244,
            child: Column(
              children: [
                Row(
                  children: [
                    const _D20Eyebrow('GROWTH'),
                    const Spacer(),
                    _D20Odometer(
                      value: (pet.growth * 100).round(),
                      suffix: '%',
                      style: _d20Num(size: 11, color: _d20Amber),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                _D20SegmentBar(value: pet.growth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _store(Pet pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const _D20Eyebrow('STORE'),
              const Spacer(),
              _D20Eyebrow('전체보기', color: _d20InkA(0.42), spacing: 1.5),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            itemCount: pet.store.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _D20StoreCard(
              item: pet.store[i],
              onTap: () => HapticFeedback.selectionClick(),
            ),
          ),
        ),
      ],
    );
  }
}

class _D20SpeechSlip extends StatelessWidget {
  const _D20SpeechSlip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('speech'),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _d20Field,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _d20AmberA(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: _d20Amber, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(text,
                textAlign: TextAlign.center,
                style: _d20Body(size: 13, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _D20StoreCard extends StatelessWidget {
  const _D20StoreCard({required this.item, required this.onTap});
  final PetItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: item.equipped ? _d20AmberA(0.10) : _d20Field,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: item.equipped ? _d20AmberA(0.5) : _d20InkA(0.10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _d20Body(size: 11)),
            const SizedBox(height: 6),
            _status(item),
          ],
        ),
      ),
    );
  }

  Widget _status(PetItem it) {
    if (it.equipped) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: _d20Amber, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          _D20Eyebrow('착용중', color: _d20Amber, spacing: 1),
        ],
      );
    }
    if (it.owned) {
      return _D20Eyebrow('보유', color: _d20InkA(0.42), spacing: 1.5);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🪙', style: TextStyle(fontSize: 11)),
        const SizedBox(width: 5),
        Text('${it.price}', style: _d20Num(size: 10, color: _d20InkA(0.62))),
      ],
    );
  }
}

// ================================================================ Memory Album
class _D20Album extends StatefulWidget {
  const _D20Album({required this.data});
  final AppData data;
  @override
  State<_D20Album> createState() => _D20AlbumState();
}

class _D20AlbumState extends State<_D20Album> {
  bool byDate = true;
  DoodleType? filter;

  @override
  Widget build(BuildContext context) {
    final all = widget.data.album;
    final items =
        all.where((d) => filter == null || d.type == filter).toList();
    return Scaffold(
      backgroundColor: _d20Ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: _D20Panel(
            child: Column(
              children: [
                _topStrip(),
                const _D20Seam(),
                _filters(items.length),
                const _D20Seam(),
                Expanded(child: _list(items)),
                const _D20Seam(),
                const _D20Nav(current: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topStrip() {
    return Container(
      color: _d20Dim,
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _D20StatusLED(pulse: true, size: 8),
                    const SizedBox(width: 8),
                    const _D20Eyebrow('ARCHIVE · SEG-03'),
                  ],
                ),
                const SizedBox(height: 6),
                Text('낙서 사진첩',
                    style: _d20Body(size: 19, weight: FontWeight.w600)),
              ],
            ),
          ),
          _D20Segmented(
            options: const ['날짜별', '유형별'],
            selected: byDate ? 0 : 1,
            onSelect: (i) => setState(() => byDate = i == 0),
          ),
        ],
      ),
    );
  }

  Widget _filters(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const _D20Eyebrow('FILTER'),
          const SizedBox(width: 10),
          _D20Odometer(
            value: count,
            style: _d20Num(size: 11, color: _d20Amber),
          ),
          _D20Eyebrow('REC', color: _d20InkA(0.4), spacing: 1.4),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _D20Chip(
                    label: '전체',
                    selected: filter == null,
                    onTap: () => setState(() => filter = null),
                  ),
                  for (final t in DoodleType.values)
                    _D20Chip(
                      label: t.label,
                      selected: filter == t,
                      onTap: () => setState(() => filter = t),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<Doodle> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 3),
        child: _D20Seam(),
      ),
      itemBuilder: (_, i) => _D20MemoryRow(doodle: items[i]),
    );
  }
}

class _D20Chip extends StatelessWidget {
  const _D20Chip({
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
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? _d20AmberA(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? _d20AmberA(0.5) : _d20InkA(0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                      color: _d20Amber, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: _d20Label(
                    size: 10,
                    color: selected ? _d20Ink : _d20InkA(0.55),
                    spacing: 1,
                    weight: selected ? FontWeight.w700 : FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _D20MemoryRow extends StatelessWidget {
  const _D20MemoryRow({required this.doodle});
  final Doodle doodle;

  String _stamp(DateTime t) =>
      '${t.month.toString().padLeft(2, '0')}·${t.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                colors: [
                  for (final c in d.swatch) _d20Soft(c),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _d20InkA(0.08)),
            ),
            child: Text(d.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d20Body(size: 15, weight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _D20Eyebrow(d.type.label,
                        color: _d20AmberA(0.9), spacing: 1.2, size: 8),
                    const SizedBox(width: 8),
                    Text('·',
                        style: _d20Num(size: 9, color: _d20InkA(0.3))),
                    const SizedBox(width: 8),
                    Text(d.author,
                        style: _d20Body(size: 11, color: _d20InkA(0.5))),
                    const SizedBox(width: 8),
                    Text(_stamp(d.at),
                        style: _d20Num(size: 10, color: _d20InkA(0.5))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 18,
            child: d.liked
                ? Text('♥',
                    style: TextStyle(fontSize: 15, color: _d20AmberA(0.9)))
                : Text('♡',
                    style:
                        TextStyle(fontSize: 15, color: _d20InkA(0.22))),
          ),
        ],
      ),
    );
  }
}

// ==================================================================== bottom nav
class _D20Nav extends StatelessWidget {
  const _D20Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      color: _d20Dim,
      padding: const EdgeInsets.fromLTRB(22, 11, 22, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < labels.length; i++)
            _item(labels[i], i == current),
        ],
      ),
    );
  }

  Widget _item(String label, bool active) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 3,
            width: 16,
            child: active
                ? Container(
                    decoration: BoxDecoration(
                      color: _d20Amber,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 7),
          Text(label,
              style: _d20Label(
                size: 11,
                color: active ? _d20Ink : _d20InkA(0.4),
                spacing: 1.4,
                weight: active ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
