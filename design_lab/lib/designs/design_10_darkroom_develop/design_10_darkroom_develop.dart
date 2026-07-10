// design_10_darkroom_develop — "Darkroom".
//
// A red-safelight film lab. Negative amber on silver-gelatin grays, sprocket-hole
// rails and contact-sheet grids. Every photo arrives UNDEVELOPED: it lands as a
// blank paper frame and only blooms into view as a thumb rubs it — and only fully
// resolves once the partner rubs it too (a shared-warmth reveal).
//
// Self-contained: Flutter Material/widgets only, no packages, no assets, no
// network, no DateTime.now(), no Random(). Imagery = gradients + emoji.
//
// Everything except `Design10` is private with the `_D10` prefix.

import 'package:flutter/material.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

class Design10 extends DesignVariant {
  @override
  String get id => '10';
  @override
  String get name => 'Darkroom';
  @override
  String get concept =>
      '레드 세이프라이트 암실 — 네거티브 앰버와 실버젤라틴 그레이, 스프로킷 레일과 콘택트 시트. 모든 사진은 미현상 상태로 도착한다.';
  @override
  String get signature =>
      '손끝으로 현상 — 사진은 빈 인화지로 오고, 엄지로 문지르면 약 8초에 걸쳐 이미지가 떠오른다. 상대가 함께 문질러야 완전히 현상되는 공동의 온기.';
  @override
  String get inspiration =>
      '아날로그 암실 인화 · 필름 콘택트 시트 · 세이프라이트 레드 · 데이트백 LED';
  @override
  Color get accent => _D10C.amber;
  @override
  Brightness get brightness => Brightness.dark;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return switch (screen) {
      HeroScreen.drawSend => _D10DrawSend(data: data),
      HeroScreen.petHome => _D10PetHome(data: data),
      HeroScreen.memoryAlbum => _D10MemoryAlbum(data: data),
    };
  }
}

// ============================================================ palette + type
class _D10C {
  static const bg = Color(0xFF0A0806); // deep darkroom black
  static const panel = Color(0xFF15110F);
  static const panelHi = Color(0xFF201A17);
  static const safelight = Color(0xFF7A0E12); // safelight red
  static const safeGlow = Color(0x667A0E12);
  static const amber = Color(0xFFD98A3D); // negative amber
  static const amberHi = Color(0xFFF2AB5E);
  static const silverDark = Color(0xFF3A3A3A);
  static const silverMid = Color(0xFF6E6E6E);
  static const silver = Color(0xFFB8B8B8);
  static const paper = Color(0xFFEDE7DC); // undeveloped print white
  static const line = Color(0xFF2C2622);
}

// LED date-back numerals.
TextStyle _d10Led({double size = 14, Color color = _D10C.amber, double sp = 3}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      color: color,
      letterSpacing: sp,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );

// Typewriter captions.
TextStyle _d10Type({double size = 12, Color color = _D10C.silver, double sp = 0.5}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      color: color,
      letterSpacing: sp,
      height: 1.25,
    );

String _d10Pad(int n) => n.toString().padLeft(2, '0');

// ================================================================ scaffolding
class _D10Screen extends StatelessWidget {
  const _D10Screen({required this.child, this.nav});
  final Widget child;
  final Widget? nav;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D10C.bg,
      body: Stack(
        children: [
          // base + safelight radial from the top.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.05),
                  radius: 1.35,
                  colors: [_D10C.safeGlow, Color(0x00000000)],
                  stops: [0.0, 0.62],
                ),
                color: _D10C.bg,
              ),
            ),
          ),
          SafeArea(child: child),
          // film grain over everything.
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _D10Grain(density: 0.5, opacity: 0.05)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: nav,
    );
  }
}

// grain: deterministic LCG dots (no Random()).
class _D10Grain extends CustomPainter {
  const _D10Grain({this.density = 1, this.opacity = 0.08, this.seed = 0x9E3779B9});
  final double density;
  final double opacity;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final count = ((size.width * size.height) / 1400 * density).clamp(0, 1400).toInt();
    // MINSTD (Park–Miller): products stay < 2^53, so it is exact on Flutter web.
    int s = (seed % 2147483646).abs() + 1;
    int next() {
      s = (s * 48271) % 2147483647;
      return s;
    }

    final light = Paint()..color = _D10C.paper.withValues(alpha: opacity);
    final dark = Paint()..color = Colors.black.withValues(alpha: opacity * 1.2);
    for (int i = 0; i < count; i++) {
      final dx = (next() % 1000) / 1000 * size.width;
      final dy = (next() % 1000) / 1000 * size.height;
      final r = (next() % 100) / 100 * 0.7 + 0.3;
      canvas.drawCircle(Offset(dx, dy), r, (next() % 2 == 0) ? light : dark);
    }
  }

  @override
  bool shouldRepaint(covariant _D10Grain old) => false;
}

// sprocket-hole rail.
class _D10Sprockets extends StatelessWidget {
  const _D10Sprockets({this.vertical = false, this.count = 10, this.hole = _D10C.paper});
  final bool vertical;
  final int count;
  final Color hole;

  @override
  Widget build(BuildContext context) {
    final squares = List<Widget>.generate(
      count,
      (_) => Container(
        width: vertical ? 9 : 8,
        height: vertical ? 7 : 9,
        decoration: BoxDecoration(
          color: hole.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
    return vertical
        ? Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: squares)
        : Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: squares);
  }
}

// LED readout pill.
class _D10Led extends StatelessWidget {
  const _D10Led(this.text, {this.icon, this.color = _D10C.amber, this.size = 13});
  final String text;
  final String? icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _D10C.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Text(icon!, style: const TextStyle(fontSize: 13)), const SizedBox(width: 6)],
          Text(text, style: _d10Led(size: size, color: color)),
        ],
      ),
    );
  }
}

// =================================================================== DRAW & SEND
class _D10DrawSend extends StatefulWidget {
  const _D10DrawSend({required this.data});
  final AppData data;
  @override
  State<_D10DrawSend> createState() => _D10DrawSendState();
}

class _D10Stroke {
  _D10Stroke(this.color, this.width);
  final Color color;
  final double width;
  final List<Offset> points = [];
}

class _D10DrawSendState extends State<_D10DrawSend> {
  int pen = 2;
  double thickness = 6;
  SendMode mode = SendMode.normal;
  final List<_D10Stroke> strokes = [];

  Color get _ink => demoPenColors[pen];

  @override
  Widget build(BuildContext context) {
    final c = widget.data.couple;
    return _D10Screen(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topBar(c.partnerNickname),
            const SizedBox(height: 12),
            Expanded(child: _negativeCanvas()),
            const SizedBox(height: 12),
            _penRail(),
            const SizedBox(height: 10),
            _thicknessDial(),
            const SizedBox(height: 12),
            _modeToggle(),
            const SizedBox(height: 12),
            _bottomTools(),
          ],
        ),
      ),
    );
  }

  Widget _topBar(String nick) {
    return Row(
      children: [
        _iconBtn(Icons.arrow_back_ios_new_rounded, () {}),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EXPOSING TO', style: _d10Type(size: 9, color: _D10C.silverMid, sp: 3)),
              const SizedBox(height: 3),
              Text('▸ $nick', style: _d10Led(size: 18, color: _D10C.amberHi)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: _D10C.safelight,
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: _D10C.safeGlow, blurRadius: 18, spreadRadius: 1)],
              border: Border.all(color: _D10C.amber.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('EXPOSE', style: _d10Led(size: 12, color: _D10C.paper, sp: 2)),
                const SizedBox(width: 6),
                const Icon(Icons.send_rounded, size: 14, color: _D10C.paper),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _negativeCanvas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D10C.silverDark, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          const SizedBox(width: 12, child: _D10Sprockets(vertical: true, count: 12)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // negative field.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.2),
                        radius: 1.1,
                        colors: [Color(0xFF241C16), Color(0xFF0C0A08)],
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) => setState(() {
                      final s = _D10Stroke(_ink, thickness);
                      s.points.add(d.localPosition);
                      strokes.add(s);
                    }),
                    onPanUpdate: (d) => setState(() {
                      if (strokes.isNotEmpty) strokes.last.points.add(d.localPosition);
                    }),
                    child: CustomPaint(painter: _D10CanvasPainter(strokes)),
                  ),
                  if (strokes.isEmpty)
                    IgnorePointer(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('◐ 미노출 필름', style: _d10Led(size: 13, color: _D10C.amber.withValues(alpha: 0.6))),
                            const SizedBox(height: 8),
                            Text('여기에 빛으로 낙서하세요', style: _d10Type(size: 11, color: _D10C.silverMid)),
                          ],
                        ),
                      ),
                    ),
                  // frame counter + clear.
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Text('26  ▸  ${_d10Pad(strokes.length)}', style: _d10Led(size: 11, color: _D10C.amber)),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: _iconBtn(Icons.cleaning_services_rounded, () => setState(strokes.clear), mini: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12, child: _D10Sprockets(vertical: true, count: 12)),
        ],
      ),
    );
  }

  Widget _penRail() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _D10C.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _D10C.line),
      ),
      child: Row(
        children: [
          Text('CHEM', style: _d10Type(size: 9, color: _D10C.silverMid, sp: 2)),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < demoPenColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => pen = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: demoPenColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: pen == i ? _D10C.amberHi : Colors.black,
                          width: pen == i ? 3 : 1.5,
                        ),
                        boxShadow: pen == i
                            ? const [BoxShadow(color: _D10C.safeGlow, blurRadius: 10, spreadRadius: 1)]
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thicknessDial() {
    return Row(
      children: [
        Text('APERTURE', style: _d10Type(size: 9, color: _D10C.silverMid, sp: 2)),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _D10C.amber,
              inactiveTrackColor: _D10C.silverDark,
              thumbColor: _D10C.amberHi,
              overlayColor: _D10C.safeGlow,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: thickness,
              min: 1,
              max: 20,
              onChanged: (v) => setState(() => thickness = v),
            ),
          ),
        ),
        _D10Led('f/${thickness.round()}', size: 12),
      ],
    );
  }

  Widget _modeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final m in SendMode.values) ...[
              Expanded(child: _shutter(m)),
              if (m == SendMode.values.first) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 13, color: _D10C.silverMid),
            const SizedBox(width: 6),
            Expanded(child: Text(mode.description, style: _d10Type(size: 11, color: _D10C.silver))),
          ],
        ),
      ],
    );
  }

  Widget _shutter(SendMode m) {
    final on = mode == m;
    return GestureDetector(
      onTap: () => setState(() => mode = m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: on ? _D10C.panelHi : _D10C.panel,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: on ? _D10C.amber : _D10C.line, width: on ? 2 : 1),
          boxShadow: on ? const [BoxShadow(color: _D10C.safeGlow, blurRadius: 14)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(m == SendMode.normal ? Icons.push_pin_rounded : Icons.timer_rounded,
                size: 14, color: on ? _D10C.amberHi : _D10C.silverMid),
            const SizedBox(width: 7),
            Text(m.label, style: _d10Led(size: 12, color: on ? _D10C.amberHi : _D10C.silver, sp: 1)),
          ],
        ),
      ),
    );
  }

  Widget _bottomTools() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _D10C.line),
        color: _D10C.panel,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _tool(Icons.photo_library_rounded, '갤러리'),
          _divider(),
          _tool(Icons.photo_camera_rounded, '사진'),
          _divider(),
          _tool(Icons.notifications_active_rounded, '찌르기'),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 34, color: _D10C.line);

  Widget _tool(IconData i, String l) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(i, color: _D10C.amber, size: 22),
            const SizedBox(height: 5),
            Text(l, style: _d10Type(size: 10, color: _D10C.silver)),
          ],
        ),
      );

  Widget _iconBtn(IconData i, VoidCallback onTap, {bool mini = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: mini ? 30 : 38,
          height: mini ? 30 : 38,
          decoration: BoxDecoration(
            color: _D10C.panel,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _D10C.line),
          ),
          child: Icon(i, size: mini ? 15 : 17, color: _D10C.silver),
        ),
      );
}

class _D10CanvasPainter extends CustomPainter {
  _D10CanvasPainter(this.strokes);
  final List<_D10Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      // amber "glow" underlay for the exposed-light feel.
      final glow = Paint()
        ..color = s.color.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = s.width + 6;
      final ink = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = s.width;
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, s.width / 2, ink);
        continue;
      }
      for (int i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, ink);
    }
  }

  @override
  bool shouldRepaint(covariant _D10CanvasPainter old) => true;
}

// ====================================================================== PET HOME
class _D10PetHome extends StatefulWidget {
  const _D10PetHome({required this.data});
  final AppData data;
  @override
  State<_D10PetHome> createState() => _D10PetHomeState();
}

class _D10PetHomeState extends State<_D10PetHome> {
  int patCount = 0;
  bool get patted => patCount > 0;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((e) => e.equipped).toList();
    return _D10Screen(
      nav: const _D10Nav(current: 0),
      child: Column(
        children: [
          _header(pet),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                children: [
                  _enlarger(pet, equipped),
                  const SizedBox(height: 14),
                  _growth(pet),
                  const SizedBox(height: 16),
                  _store(pet),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Pet pet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DARKROOM PET', style: _d10Type(size: 9, color: _D10C.silverMid, sp: 3)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(pet.name, style: _d10Led(size: 20, color: _D10C.amberHi, sp: 2)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _D10C.safelight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('LV.${pet.level}', style: _d10Led(size: 11, color: _D10C.paper, sp: 1)),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _D10Led('${pet.coins}', icon: '🪙', color: _D10C.amberHi, size: 14),
        ],
      ),
    );
  }

  Widget _enlarger(Pet pet, List<PetItem> equipped) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _D10C.silverDark, width: 2),
      ),
      child: Column(
        children: [
          const SizedBox(height: 26, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: _D10Sprockets(count: 14),
          )),
          GestureDetector(
            onTap: () => setState(() => patCount++),
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.25),
                  radius: 0.95,
                  colors: [Color(0x33D98A3D), Color(0xFF0C0A08)],
                  stops: [0.0, 0.85],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // enlarger cone light.
                  const Positioned(
                    top: 0,
                    child: SizedBox(
                      width: 210,
                      height: 130,
                      child: CustomPaint(painter: _D10ConePainter()),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (equipped.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('착용', style: _d10Type(size: 10, color: _D10C.silverMid)),
                              const SizedBox(width: 8),
                              for (final e in equipped)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(e.emoji, style: const TextStyle(fontSize: 20)),
                                ),
                            ],
                          ),
                        ),
                      AnimatedScale(
                        scale: patted ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: Text(pet.moodEmoji, style: const TextStyle(fontSize: 96)),
                      ),
                      const SizedBox(height: 10),
                      if (patted)
                        _speech(pet.speech)
                      else
                        Text('쓰다듬어 현상하세요 ✋', style: _d10Type(size: 11, color: _D10C.silver)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26, child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: _D10Sprockets(count: 14),
          )),
        ],
      ),
    );
  }

  Widget _speech(String speech) {
    return Container(
      key: ValueKey(patCount),
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _D10C.panelHi,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _D10C.amber.withValues(alpha: 0.5)),
      ),
      child: TweenAnimationBuilder<double>(
        key: ValueKey(patCount),
        tween: Tween(begin: 0, end: speech.length.toDouble()),
        duration: const Duration(milliseconds: 700),
        builder: (_, v, __) {
          final n = v.round().clamp(0, speech.length);
          return Text('${speech.substring(0, n)}▌', style: _d10Type(size: 12, color: _D10C.amberHi));
        },
      ),
    );
  }

  Widget _growth(Pet pet) {
    final pct = (pet.growth * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _D10C.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _D10C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('EXPOSURE METER', style: _d10Type(size: 9, color: _D10C.silverMid, sp: 2)),
              const Spacer(),
              Text('다음 Lv까지 $pct%', style: _d10Led(size: 12, color: _D10C.amberHi, sp: 1)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              width: double.infinity,
              height: 12,
              child: Stack(
                children: [
                  const Positioned.fill(child: ColoredBox(color: _D10C.silverDark)),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pet.growth,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [_D10C.safelight, _D10C.amber, _D10C.amberHi]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
        Row(
          children: [
            Text('■ 암실 상점', style: _d10Led(size: 13, color: _D10C.silver, sp: 1)),
            const Spacer(),
            Text('전체보기 ▸', style: _d10Type(size: 10, color: _D10C.amber)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pet.store.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _storeItem(pet.store[i]),
          ),
        ),
      ],
    );
  }

  Widget _storeItem(PetItem it) {
    final on = it.equipped;
    return Container(
      width: 86,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _D10C.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: on ? _D10C.amber : _D10C.line, width: on ? 2 : 1),
        boxShadow: on ? const [BoxShadow(color: _D10C.safeGlow, blurRadius: 12)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(it.category, style: _d10Type(size: 8, color: _D10C.silverMid, sp: 1)),
          const SizedBox(height: 2),
          Expanded(child: Center(child: Text(it.emoji, style: const TextStyle(fontSize: 34)))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              it.owned ? (it.equipped ? '착용중' : '보유') : '🪙${it.price}',
              style: _d10Led(size: 10, color: it.owned ? (on ? _D10C.amberHi : _D10C.silver) : _D10C.amber, sp: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _D10ConePainter extends CustomPainter {
  const _D10ConePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.42, 0)
      ..lineTo(size.width * 0.58, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55F2AB5E), Color(0x00000000)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ================================================================= MEMORY ALBUM
class _D10MemoryAlbum extends StatefulWidget {
  const _D10MemoryAlbum({required this.data});
  final AppData data;
  @override
  State<_D10MemoryAlbum> createState() => _D10MemoryAlbumState();
}

class _D10MemoryAlbumState extends State<_D10MemoryAlbum> {
  bool byDate = true;
  DoodleType? filter;

  @override
  Widget build(BuildContext context) {
    final album = widget.data.album;
    final items = album.where((d) => filter == null || d.type == filter).toList();
    if (byDate) {
      items.sort((a, b) => b.at.compareTo(a.at));
    } else {
      items.sort((a, b) => a.type.index.compareTo(b.type.index));
    }
    final streak = widget.data.couple.streakDays;

    return _D10Screen(
      nav: const _D10Nav(current: 1),
      child: Column(
        children: [
          _header(streak, album.length),
          _filters(),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.62,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final d = items[i];
                // partner-develop state is deterministic (no Random()).
                final partnerDone = d.liked || d.id.hashCode.isEven;
                return _D10ContactCell(doodle: d, partnerDone: partnerDone);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(int streak, int frames) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CONTACT SHEET', style: _d10Type(size: 9, color: _D10C.silverMid, sp: 3)),
              const SizedBox(height: 4),
              Text('ROLL $streak · ${_d10Pad(frames)} 프레임', style: _d10Led(size: 16, color: _D10C.amberHi, sp: 1)),
            ],
          ),
          const Spacer(),
          _sortToggle(),
        ],
      ),
    );
  }

  Widget _sortToggle() {
    Widget seg(String label, bool on, VoidCallback tap) => GestureDetector(
          onTap: tap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: on ? _D10C.amber : Colors.transparent,
            child: Text(label,
                style: _d10Type(size: 10, color: on ? Colors.black : _D10C.silver, sp: 0.5)
                    .copyWith(fontWeight: on ? FontWeight.w700 : FontWeight.w400)),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _D10C.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg('날짜별', byDate, () => setState(() => byDate = true)),
            Container(width: 1, height: 26, color: _D10C.line),
            seg('유형별', !byDate, () => setState(() => byDate = false)),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    Widget chip(String label, bool on, VoidCallback tap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: tap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: on ? _D10C.safelight : _D10C.panel,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: on ? _D10C.amber : _D10C.line),
              ),
              child: Text(label,
                  style: _d10Type(size: 11, color: on ? _D10C.paper : _D10C.silver, sp: 0.5)),
            ),
          ),
        );
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip('전체', filter == null, () => setState(() => filter = null)),
          for (final t in DoodleType.values)
            chip(t.label, filter == t, () => setState(() => filter = t)),
        ],
      ),
    );
  }
}

// One contact-sheet cell: a print that must be DEVELOPED by rubbing.
class _D10ContactCell extends StatefulWidget {
  const _D10ContactCell({required this.doodle, required this.partnerDone});
  final Doodle doodle;
  final bool partnerDone;
  @override
  State<_D10ContactCell> createState() => _D10ContactCellState();
}

class _D10ContactCellState extends State<_D10ContactCell> {
  double dev = 0; // 0..1 how much *I* have rubbed.

  void _rub(double distance) {
    setState(() => dev = (dev + distance / 240).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doodle;
    final b = Curves.easeInOut.transform(dev);
    final partner = widget.partnerDone;
    // image resolves fully only if partner has also rubbed.
    final imgOpacity = b * (partner ? 1.0 : 0.62);
    final fullyDone = dev >= 0.999 && partner;

    return Container(
      decoration: BoxDecoration(
        color: _D10C.panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _D10C.silverDark, width: 1.5),
      ),
      padding: const EdgeInsets.all(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // the developing print.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // horizontal rub develops; vertical drag still scrolls the grid.
                onHorizontalDragUpdate: (e) => _rub(e.delta.distance),
                onTap: () => _rub(26),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // developed image (blooms up).
                    Opacity(
                      opacity: imgOpacity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: d.swatch,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(child: Text(d.emoji, style: const TextStyle(fontSize: 44))),
                      ),
                    ),
                    // waiting-for-partner haze.
                    if (!partner && b > 0.05)
                      IgnorePointer(
                        child: Opacity(
                          opacity: (1 - b) * 0 + b * 0.35,
                          child: const ColoredBox(color: Color(0xFF9AA0A6)),
                        ),
                      ),
                    // undeveloped paper on top (fades out as it develops).
                    IgnorePointer(
                      child: Opacity(
                        opacity: (1 - b).clamp(0.0, 1.0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const ColoredBox(color: _D10C.paper),
                            CustomPaint(painter: _D10Grain(density: 1.2, opacity: 0.06, seed: d.id.hashCode | 1)),
                          ],
                        ),
                      ),
                    ),
                    // top badges.
                    Positioned(
                      left: 6,
                      top: 6,
                      child: _tag(Icon(d.type.icon, size: 12, color: _D10C.paper)),
                    ),
                    if (d.liked)
                      const Positioned(
                        right: 6,
                        top: 6,
                        child: Icon(Icons.favorite, size: 15, color: _D10C.safelight),
                      ),
                    // centered develop status.
                    if (dev < 0.02)
                      IgnorePointer(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.touch_app_rounded, size: 22, color: _D10C.silverMid),
                              const SizedBox(height: 4),
                              Text('문질러 현상', style: _d10Type(size: 10, color: _D10C.silverDark)),
                            ],
                          ),
                        ),
                      )
                    else
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: IgnorePointer(
                          child: Text('현상 ${(dev * 100).round()}%',
                              style: _d10Led(size: 10, color: _D10C.paper, sp: 1)),
                        ),
                      ),
                    // partner status pill.
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: IgnorePointer(child: _partnerPill(fullyDone)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          // print margin: typewriter caption + author + LED date.
          Text(d.caption,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: _d10Type(size: 12, color: _D10C.silver)),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(d.author, style: _d10Type(size: 10, color: _D10C.silverMid)),
              const Spacer(),
              Text('${_d10Pad(d.at.month)}·${_d10Pad(d.at.day)}', style: _d10Led(size: 11, color: _D10C.amber, sp: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(Widget child) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      );

  Widget _partnerPill(bool fullyDone) {
    final on = widget.partnerDone;
    final label = fullyDone
        ? '완성'
        : on
            ? '토리 ✓'
            : '토리 대기';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: fullyDone ? _D10C.amber : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: on ? _D10C.amber : _D10C.silverDark, width: 1),
      ),
      child: Text(label,
          style: _d10Type(size: 9, color: fullyDone ? Colors.black : (on ? _D10C.amberHi : _D10C.silver), sp: 0.5)),
    );
  }
}

// ======================================================================== nav
class _D10Nav extends StatelessWidget {
  const _D10Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.pets_rounded, '펫키우기'),
      (Icons.photo_library_rounded, '사진첩'),
      (Icons.forum_rounded, '소통'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: _D10C.panel,
        border: Border(top: BorderSide(color: _D10C.silverDark, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: SizedBox(height: 8, child: _D10Sprockets(count: 22, hole: _D10C.silverDark)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < items.length; i++)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i].$1,
                            size: 22, color: i == current ? _D10C.amberHi : _D10C.silverMid),
                        const SizedBox(height: 4),
                        Text(items[i].$2,
                            style: _d10Type(
                                size: 10,
                                color: i == current ? _D10C.amberHi : _D10C.silverMid,
                                sp: 0.5)),
                        const SizedBox(height: 3),
                        Container(
                          width: 18,
                          height: 2,
                          color: i == current ? _D10C.amber : Colors.transparent,
                        ),
                      ],
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
