// design_02_frosted_locket — "Frosted Locket".
//
// Layered translucent glass panels float over a living dawn-to-dusk gradient;
// the pager becomes a light-refracting locket you peer down into.
//
// Signature: Tilt-to-peek — dragging slides the frosted top layer so the pet's
// glow and today's memory bleed through the glass beneath, refracting across
// the whole stack. Delicate high-contrast serif headers sit over airy,
// light-weight sans body. A glass memory card settles into the album with a
// slow liquid ripple.
//
// Self-contained: Flutter Material/widgets only. Imagery is gradients + emoji.
// Everything except Design02 is private and _D02-prefixed.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ─────────────────────────────────────────────────────────── palette + type
class _D02 {
  static const Color peach = Color(0xFFFFD8C2);
  static const Color lavender = Color(0xFFC9BEEF);
  static const Color teal = Color(0xFF9AE6D8);
  static const Color ink = Color(0xFF3A2E4A); // high-contrast plum ink
  static const Color mist = Color(0xFF6B6180); // muted body

  static const List<Color> dawnToDusk = [peach, lavender, teal];

  // Delicate high-contrast serif for headers.
  static TextStyle serif(
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w600,
    double spacing = 0.2,
    double height = 1.1,
    FontStyle style = FontStyle.normal,
  }) =>
      TextStyle(
        fontFamily: 'Georgia',
        fontFamilyFallback: const ['Times New Roman', 'Iowan Old Style', 'serif'],
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
        height: height,
        fontStyle: style,
      );

  // Airy light-weight sans for body.
  static TextStyle sans(
    double size, {
    Color color = mist,
    FontWeight weight = FontWeight.w300,
    double spacing = 0.3,
    double height = 1.3,
  }) =>
      TextStyle(
        fontFamily: 'Helvetica Neue',
        fontFamilyFallback: const ['SF Pro Text', 'Segoe UI', 'Roboto', 'sans-serif'],
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: spacing,
        height: height,
      );
}

Offset _d02clamp(Offset o, double m) =>
    Offset(o.dx.clamp(-m, m), o.dy.clamp(-m, m));

// ────────────────────────────────────────────────────────────── the variant
class Design02 extends DesignVariant {
  @override
  String get id => '02';
  @override
  String get name => 'Frosted Locket';
  @override
  String get concept =>
      '살아 있는 새벽→노을 그라디언트 위로 반투명 유리 패널이 겹겹이 떠 있는, 빛을 굴절시키는 로켓 펜던트.';
  @override
  String get signature =>
      '틸트-투-픽 — 위 서리층을 밀면 아래 유리로 오늘의 기억과 펫의 빛이 번져 굴절된다.';
  @override
  String get inspiration =>
      'Glassmorphism / frosted locket pendant, iOS depth blur, aurora gradients';
  @override
  Color get accent => _D02.lavender;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _D02.sans(14),
      child: switch (screen) {
        HeroScreen.drawSend => _D02DrawSend(data: data),
        HeroScreen.petHome => _D02PetHome(data: data),
        HeroScreen.memoryAlbum => _D02Album(data: data),
      },
    );
  }
}

// ─────────────────────────────────────────────── living dawn-to-dusk backdrop
class _D02Background extends StatefulWidget {
  const _D02Background({required this.child});
  final Widget child;
  @override
  State<_D02Background> createState() => _D02BackgroundState();
}

class _D02BackgroundState extends State<_D02Background>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _orb(double t, double phase, Color color, double size, double amp) {
    final a = (t + phase) * 2 * math.pi;
    return Positioned(
      left: 214 + math.sin(a) * amp - size / 2,
      top: 463 + math.cos(a * 0.8) * amp * 1.4 - size / 2,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(0.55), color.withOpacity(0.0)],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final shift = math.sin(t * 2 * math.pi) * 0.35;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + shift, -1),
                  end: Alignment(1, 1 - shift),
                  colors: _D02.dawnToDusk,
                  stops: const [0.0, 0.52, 1.0],
                ),
              ),
            ),
            _orb(t, 0.0, const Color(0xFFFFF1E6), 360, 90),
            _orb(t, 0.35, _D02.teal, 300, 120),
            _orb(t, 0.68, _D02.lavender, 340, 100),
            widget.child,
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────── frosted panel
class _D02Glass extends StatelessWidget {
  const _D02Glass({
    required this.child,
    this.blur = 14,
    this.opacity = 0.14,
    this.radius = 26,
    this.padding = const EdgeInsets.all(16),
    this.strokeOpacity = 0.55,
    this.glow,
  });
  final Widget child;
  final double blur;
  final double opacity;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double strokeOpacity;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          if (glow != null)
            BoxShadow(color: glow!.withOpacity(0.5), blurRadius: 34, spreadRadius: 2),
          BoxShadow(
            color: _D02.ink.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(opacity + 0.10),
                  Colors.white.withOpacity(opacity),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(strokeOpacity),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// A tiny frosted circle button.
class _D02GlassCircle extends StatelessWidget {
  const _D02GlassCircle({
    required this.icon,
    required this.onTap,
    this.size = 46,
    this.selected = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _D02Glass(
        radius: size,
        blur: 12,
        opacity: selected ? 0.30 : 0.12,
        padding: EdgeInsets.zero,
        glow: selected ? _D02.teal : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: _D02.ink.withOpacity(0.85), size: size * 0.44),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────── shared bottom nav
class _D02Nav extends StatelessWidget {
  const _D02Nav({required this.current});
  final int current; // 0 pet · 1 album · 2 talk

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.pets_rounded, '펫키우기'),
      (Icons.auto_stories_rounded, '사진첩'),
      (Icons.brush_rounded, '소통'),
    ];
    return _D02Glass(
      radius: 30,
      blur: 18,
      opacity: 0.18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int i = 0; i < items.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == current
                        ? Colors.white.withOpacity(0.55)
                        : Colors.transparent,
                    boxShadow: i == current
                        ? [BoxShadow(color: _D02.teal.withOpacity(0.55), blurRadius: 18)]
                        : null,
                  ),
                  child: Icon(
                    items[i].$1,
                    size: 22,
                    color: i == current ? _D02.ink : _D02.ink.withOpacity(0.45),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  items[i].$2,
                  style: _D02.sans(
                    10.5,
                    color: i == current ? _D02.ink : _D02.mist.withOpacity(0.7),
                    weight: i == current ? FontWeight.w500 : FontWeight.w300,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════ 1 · DRAW & SEND
class _D02DrawSend extends StatefulWidget {
  const _D02DrawSend({required this.data});
  final AppData data;
  @override
  State<_D02DrawSend> createState() => _D02DrawSendState();
}

class _D02DrawSendState extends State<_D02DrawSend> {
  int pen = 4;
  double thickness = 7;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    final penColor = demoPenColors[pen];
    final today = widget.data.album.first; // "bleeds through the glass beneath"

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _D02Background(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Column(
              children: [
                // top bar --------------------------------------------------
                _D02Glass(
                  radius: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      _D02GlassCircle(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {},
                        size: 40,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text('보내는 곳', style: _D02.sans(10.5, spacing: 2)),
                            Text('${couple.partnerNickname}에게',
                                style: _D02.serif(19, weight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: _D02Glass(
                          radius: 22,
                          opacity: 0.30,
                          glow: _D02.teal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('보내기',
                                  style: _D02.serif(14,
                                      weight: FontWeight.w700, spacing: 0.5)),
                              const SizedBox(width: 6),
                              Icon(Icons.send_rounded,
                                  size: 15, color: _D02.ink.withOpacity(0.85)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // locket canvas -------------------------------------------
                Expanded(
                  child: _D02Glass(
                    radius: 34,
                    blur: 10,
                    opacity: 0.10,
                    padding: const EdgeInsets.all(18),
                    glow: penColor,
                    child: Stack(
                      children: [
                        // today's memory bleeding through the frosted glass
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.55,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: RadialGradient(
                                  center: const Alignment(0.2, -0.3),
                                  radius: 1.1,
                                  colors: [
                                    today.swatch.first.withOpacity(0.5),
                                    today.swatch.last.withOpacity(0.15),
                                  ],
                                ),
                              ),
                              alignment: const Alignment(0.55, -0.55),
                              child: Text(today.emoji,
                                  style: const TextStyle(fontSize: 46)),
                            ),
                          ),
                        ),
                        // live pen stroke preview
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _D02Squiggle(penColor, thickness),
                          ),
                        ),
                        // lens rings — peering down into the locket
                        Center(
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.35)),
                              gradient: RadialGradient(colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.18),
                              ]),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const Alignment(-0.95, -0.95),
                          child: Text('오늘의 유리 낙서',
                              style: _D02.serif(15,
                                  style: FontStyle.italic,
                                  color: _D02.ink.withOpacity(0.7))),
                        ),
                        Align(
                          alignment: const Alignment(0.95, 0.95),
                          child: Text('손끝으로 그려보세요',
                              style: _D02.sans(11.5, color: _D02.ink.withOpacity(0.55))),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // pen palette + thickness ---------------------------------
                _D02Glass(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (int i = 0; i < demoPenColors.length; i++)
                            GestureDetector(
                              onTap: () => setState(() => pen = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: pen == i ? 34 : 28,
                                height: pen == i ? 34 : 28,
                                decoration: BoxDecoration(
                                  color: demoPenColors[i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(pen == i ? 0.95 : 0.4),
                                    width: pen == i ? 3 : 1.5,
                                  ),
                                  boxShadow: pen == i
                                      ? [
                                          BoxShadow(
                                            color: demoPenColors[i].withOpacity(0.7),
                                            blurRadius: 16,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.line_weight_rounded,
                              size: 18, color: _D02.mist),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                activeTrackColor: penColor.withOpacity(0.85),
                                inactiveTrackColor: Colors.white.withOpacity(0.4),
                                thumbColor: Colors.white,
                                overlayShape:
                                    const RoundSliderOverlayShape(overlayRadius: 16),
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 9),
                              ),
                              child: Slider(
                                value: thickness,
                                min: 1,
                                max: 20,
                                onChanged: (v) => setState(() => thickness = v),
                              ),
                            ),
                          ),
                          Container(
                            width: thickness + 6,
                            height: thickness + 6,
                            decoration: BoxDecoration(
                              color: penColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // mode toggle ---------------------------------------------
                _D02Glass(
                  radius: 24,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final m in SendMode.values)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => mode = m),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 240),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    color: mode == m
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.transparent,
                                    boxShadow: mode == m
                                        ? [
                                            BoxShadow(
                                                color:
                                                    _D02.lavender.withOpacity(0.6),
                                                blurRadius: 16)
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        m == SendMode.normal
                                            ? Icons.push_pin_rounded
                                            : Icons.hourglass_bottom_rounded,
                                        size: 16,
                                        color: mode == m
                                            ? _D02.ink
                                            : _D02.mist.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        m.label,
                                        style: _D02.serif(
                                          14,
                                          weight: FontWeight.w700,
                                          color: mode == m
                                              ? _D02.ink
                                              : _D02.mist.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          mode.description,
                          key: ValueKey(mode),
                          style: _D02.sans(11.5, color: _D02.ink.withOpacity(0.6)),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // bottom actions ------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _action(Icons.photo_library_rounded, '갤러리'),
                    _action(Icons.photo_camera_rounded, '사진'),
                    _action(Icons.notifications_active_rounded, '찌르기'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _D02GlassCircle(icon: icon, onTap: () {}, size: 52),
          const SizedBox(height: 6),
          Text(label, style: _D02.sans(11.5, color: _D02.ink.withOpacity(0.7))),
        ],
      );
}

class _D02Squiggle extends CustomPainter {
  _D02Squiggle(this.color, this.stroke);
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 0.6);
    final path = Path();
    final h = size.height, w = size.width;
    path.moveTo(w * 0.18, h * 0.62);
    path.cubicTo(w * 0.30, h * 0.40, w * 0.42, h * 0.78, w * 0.55, h * 0.55);
    path.cubicTo(w * 0.66, h * 0.36, w * 0.78, h * 0.70, w * 0.86, h * 0.48);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_D02Squiggle old) =>
      old.color != color || old.stroke != stroke;
}

// ══════════════════════════════════════════════════════════════ 2 · PET HOME
class _D02PetHome extends StatefulWidget {
  const _D02PetHome({required this.data});
  final AppData data;
  @override
  State<_D02PetHome> createState() => _D02PetHomeState();
}

class _D02PetHomeState extends State<_D02PetHome>
    with TickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  bool _patted = false;

  late final AnimationController _return = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..addListener(() => setState(() => _tilt = _returnTween.value));
  Animation<Offset> _returnTween = const AlwaysStoppedAnimation(Offset.zero);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _return.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onDrag(DragUpdateDetails d) {
    _return.stop();
    setState(() => _tilt = _d02clamp(_tilt + d.delta, 44));
  }

  void _snapBack() {
    _returnTween = Tween<Offset>(begin: _tilt, end: Offset.zero).animate(
      CurvedAnimation(parent: _return, curve: Curves.elasticOut),
    );
    _return.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _D02Background(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Column(
              children: [
                // header --------------------------------------------------
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(pet.name,
                                style: _D02.serif(28, weight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            Text('Lv.${pet.level}',
                                style: _D02.serif(15,
                                    style: FontStyle.italic,
                                    color: _D02.mist)),
                          ],
                        ),
                        Text('기울여서 로켓 속을 들여다보세요',
                            style: _D02.sans(11, color: _D02.ink.withOpacity(0.55))),
                      ],
                    ),
                    const Spacer(),
                    _D02Glass(
                      radius: 22,
                      opacity: 0.24,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text('${pet.coins}',
                              style: _D02.serif(15, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // TILT-TO-PEEK LOCKET -------------------------------------
                Expanded(
                  child: GestureDetector(
                    onPanUpdate: _onDrag,
                    onPanEnd: (_) => _snapBack(),
                    onTap: () => setState(() => _patted = !_patted),
                    child: _D02Glass(
                      radius: 40,
                      blur: 8,
                      opacity: 0.08,
                      padding: EdgeInsets.zero,
                      glow: _D02.teal,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final refract = _tilt.dx / 44; // -1..1
                          final glowColor = Color.lerp(
                              _D02.teal, _D02.lavender, (refract + 1) / 2)!;
                          final breathe = 1 + _pulse.value * 0.05;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // deepest layer — refracting glow (parallax)
                                Transform.translate(
                                  offset: _tilt * 1.4,
                                  child: Container(
                                    width: 320,
                                    height: 320,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(colors: [
                                        glowColor.withOpacity(0.7),
                                        glowColor.withOpacity(0.0),
                                      ]),
                                    ),
                                  ),
                                ),
                                // growth "aura" ring behind pet
                                Transform.translate(
                                  offset: _tilt * 0.9,
                                  child: Transform.scale(
                                    scale: breathe,
                                    child: Container(
                                      width: 210,
                                      height: 210,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white.withOpacity(0.5),
                                            width: 1.5),
                                        gradient: RadialGradient(colors: [
                                          Colors.white.withOpacity(0.10),
                                          Colors.white.withOpacity(0.28),
                                        ]),
                                      ),
                                    ),
                                  ),
                                ),
                                // the pet (mid layer, follows tilt slightly)
                                Transform.translate(
                                  offset: _tilt * 0.6,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(pet.moodEmoji,
                                          style: const TextStyle(fontSize: 108)),
                                    ],
                                  ),
                                ),
                                // equipped items float around, parallax fast
                                ..._equippedHalo(equipped, _tilt),
                                // TOP FROSTED LAYER — slides opposite to reveal
                                Transform.translate(
                                  offset: -_tilt * 0.7,
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0.18),
                                            Colors.white.withOpacity(0.02),
                                            Colors.white.withOpacity(0.14),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // speech bubble on PAT
                                if (_patted)
                                  Positioned(
                                    top: 26,
                                    child: _D02Glass(
                                      radius: 20,
                                      opacity: 0.42,
                                      glow: _D02.peach,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      child: Text(pet.speech,
                                          style: _D02.serif(13.5,
                                              weight: FontWeight.w600)),
                                    ),
                                  ),
                                // PAT hint / button
                                Positioned(
                                  bottom: 18,
                                  child: _D02Glass(
                                    radius: 22,
                                    opacity: _patted ? 0.30 : 0.16,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.back_hand_rounded,
                                            size: 16,
                                            color: _D02.ink.withOpacity(0.8)),
                                        const SizedBox(width: 7),
                                        Text(_patted ? '몽이가 좋아해요' : '쓰다듬기',
                                            style: _D02.serif(13,
                                                weight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // growth gauge --------------------------------------------
                _D02Glass(
                  radius: 22,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('성장 게이지', style: _D02.sans(11.5, spacing: 1)),
                          const Spacer(),
                          Text('다음 레벨까지 ${(pet.growth * 100).round()}%',
                              style: _D02.serif(12.5, weight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.35),
                            ),
                            FractionallySizedBox(
                              widthFactor: pet.growth,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_D02.teal, _D02.lavender, _D02.peach],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _D02.teal.withOpacity(0.7),
                                        blurRadius: 10),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // store ----------------------------------------------------
                _D02Glass(
                  radius: 26,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('로켓 스토어',
                              style: _D02.serif(15, weight: FontWeight.w700)),
                          const Spacer(),
                          Text('전체보기 →', style: _D02.sans(11.5)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 104,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: pet.store.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => _storeCard(pet.store[i]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _D02Nav(current: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _equippedHalo(List<PetItem> items, Offset tilt) {
    final out = <Widget>[];
    const positions = [
      Alignment(-0.72, -0.55),
      Alignment(0.75, -0.4),
      Alignment(0.6, 0.5),
      Alignment(-0.68, 0.45),
    ];
    for (int i = 0; i < items.length && i < positions.length; i++) {
      out.add(
        Align(
          alignment: positions[i],
          child: Transform.translate(
            offset: tilt * (1.6 + i * 0.2),
            child: _D02Glass(
              radius: 18,
              opacity: 0.28,
              blur: 8,
              glow: _D02.peach,
              padding: const EdgeInsets.all(8),
              child: Text(items[i].emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
        ),
      );
    }
    return out;
  }

  Widget _storeCard(PetItem it) {
    final owned = it.owned;
    final equipped = it.equipped;
    return _D02Glass(
      radius: 20,
      opacity: equipped ? 0.30 : 0.14,
      blur: 10,
      glow: equipped ? _D02.teal : null,
      padding: const EdgeInsets.all(9),
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(it.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text(it.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _D02.sans(10.5, color: _D02.ink.withOpacity(0.8))),
            const SizedBox(height: 3),
            if (owned)
              Text(equipped ? '착용중' : '보유',
                  style: _D02.serif(10.5,
                      weight: FontWeight.w700,
                      color: equipped ? _D02.ink : _D02.mist))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 2),
                  Text('${it.price}',
                      style: _D02.serif(10.5, weight: FontWeight.w700)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════ 3 · MEMORY ALBUM
class _D02Album extends StatefulWidget {
  const _D02Album({required this.data});
  final AppData data;
  @override
  State<_D02Album> createState() => _D02AlbumState();
}

class _D02AlbumState extends State<_D02Album>
    with SingleTickerProviderStateMixin {
  bool byDate = true;
  DoodleType? filter;

  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  List<Doodle> get _items {
    var list = widget.data.album
        .where((d) => filter == null || d.type == filter)
        .toList();
    if (byDate) {
      list.sort((a, b) => b.at.compareTo(a.at));
    } else {
      list.sort((a, b) => a.type.index.compareTo(b.type.index));
    }
    return list;
  }

  void _replay() {
    _ripple.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _D02Background(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Column(
              children: [
                // header + sort toggle ------------------------------------
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('낙서 사진첩',
                            style: _D02.serif(26, weight: FontWeight.w700)),
                        Text('유리에 갇힌 우리의 기억들',
                            style: _D02.sans(11.5,
                                color: _D02.ink.withOpacity(0.55))),
                      ],
                    ),
                    const Spacer(),
                    _D02Glass(
                      radius: 22,
                      opacity: 0.16,
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          for (final b in const [true, false])
                            GestureDetector(
                              onTap: () {
                                setState(() => byDate = b);
                                _replay();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: byDate == b
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.transparent,
                                  boxShadow: byDate == b
                                      ? [
                                          BoxShadow(
                                              color: _D02.lavender
                                                  .withOpacity(0.55),
                                              blurRadius: 14)
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  b ? '날짜별' : '유형별',
                                  style: _D02.serif(
                                    12.5,
                                    weight: FontWeight.w700,
                                    color: byDate == b
                                        ? _D02.ink
                                        : _D02.mist.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // type filters --------------------------------------------
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filterChip('전체', filter == null, () {
                        setState(() => filter = null);
                        _replay();
                      }),
                      for (final t in DoodleType.values)
                        _filterChip(t.label, filter == t, () {
                          setState(() => filter = t);
                          _replay();
                        }, icon: t.icon),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // grid ----------------------------------------------------
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _memoryCard(items[i], i, items.length),
                  ),
                ),
                const SizedBox(height: 12),
                const _D02Nav(current: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool sel, VoidCallback onTap,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: GestureDetector(
        onTap: onTap,
        child: _D02Glass(
          radius: 20,
          opacity: sel ? 0.34 : 0.12,
          blur: 12,
          glow: sel ? _D02.teal : null,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 14,
                    color: sel ? _D02.ink : _D02.mist.withOpacity(0.7)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: _D02.serif(
                  12.5,
                  weight: FontWeight.w700,
                  color: sel ? _D02.ink : _D02.mist.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A glass memory card settling into the album with a slow liquid ripple.
  Widget _memoryCard(Doodle d, int index, int count) {
    return AnimatedBuilder(
      animation: _ripple,
      builder: (context, child) {
        final start = (index / (count + 1)) * 0.55;
        final t = Curves.easeOutCubic.transform(
          ((_ripple.value - start) / 0.55).clamp(0.0, 1.0),
        );
        final elastic = Curves.elasticOut.transform(
          ((_ripple.value - start) / 0.7).clamp(0.0, 1.0),
        );
        final scale = 0.72 + elastic * 0.28;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 26),
            child: Transform.scale(
              scale: scale.clamp(0.0, 1.06),
              child: child,
            ),
          ),
        );
      },
      child: _memoryCardBody(d),
    );
  }

  Widget _memoryCardBody(Doodle d) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: d.swatch.last.withOpacity(0.5),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // swatch gradient — the captured light
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: d.swatch,
                ),
              ),
            ),
            // frosted glass over the swatch
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(d.type.icon,
                            size: 13, color: Colors.white),
                      ),
                      const Spacer(),
                      if (d.mode == SendMode.disappearing)
                        Icon(Icons.hourglass_bottom_rounded,
                            size: 14, color: Colors.white.withOpacity(0.9)),
                      if (d.liked)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.favorite,
                              size: 15, color: Colors.white.withOpacity(0.95)),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: Text(d.emoji, style: const TextStyle(fontSize: 46)),
                  ),
                  const Spacer(),
                  Text(
                    d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _D02.serif(15,
                        weight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.author} · ${d.at.month}월 ${d.at.day}일',
                    style: _D02.sans(11,
                        color: Colors.white.withOpacity(0.85), weight: FontWeight.w400),
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
