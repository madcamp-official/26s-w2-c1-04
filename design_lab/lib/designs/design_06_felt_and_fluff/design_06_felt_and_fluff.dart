// design_06_felt_and_fluff — "Felt & Fluff"
//
// A hand-sewn felt world: chunky stitched shapes, warm fabric shadows, yarn,
// and sewing buttons. The shared pet is a squeezable felt plushie the couple
// raises together — press it and it deforms under your finger, then springs
// back. Everything is cut-felt patches held together with running stitches.
//
// Fully self-contained: Material/widgets only, no assets, no network, no
// randomness. Imagery is gradients + emoji from the shared AppData.

import 'package:flutter/material.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ============================================================ palette + tokens
class _D06 {
  static const cream = Color(0xFFEFE6D6); // oatmeal base
  static const creamDeep = Color(0xFFE4D6BF); // recessed fabric
  static const coral = Color(0xFFF09B8E); // candy-felt coral
  static const mint = Color(0xFFA8D8C4); // candy-felt mint
  static const mustard = Color(0xFFE3B857); // candy-felt mustard
  static const ink = Color(0xFF5B4534); // embroidered thread-dark text
  static const inkSoft = Color(0xFF977C63); // faded thread text
  static const threadDark = Color(0xFFB89B79); // stitches on light fabric
  static const threadLight = Color(0xFFFBF3E4); // stitches on colored fabric

  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x2E6B4A2A), blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> shadowSoft = [
    BoxShadow(color: Color(0x226B4A2A), blurRadius: 10, offset: Offset(0, 5)),
  ];

  // Pick a stitch thread color that reads against the fabric it sits on.
  static Color stitchOn(Color fabric) =>
      fabric.computeLuminance() > 0.62 ? threadDark : threadLight;

  // Fat, rounded, embroidered display type.
  static TextStyle head(double size,
          {Color color = ink,
          FontWeight w = FontWeight.w900,
          double ls = 0.2,
          bool sewn = false}) =>
      TextStyle(
        fontSize: size,
        fontWeight: w,
        color: color,
        letterSpacing: ls,
        height: 1.05,
        shadows: sewn
            ? const [Shadow(color: Color(0x22000000), offset: Offset(0, 1.5), blurRadius: 0.5)]
            : null,
      );

  static TextStyle body(double size,
          {Color color = inkSoft, FontWeight w = FontWeight.w700, double ls = 0}) =>
      TextStyle(fontSize: size, fontWeight: w, color: color, letterSpacing: ls, height: 1.25);
}

// ================================================================ Design06
class Design06 extends DesignVariant {
  @override
  String get id => '06';
  @override
  String get name => 'Felt & Fluff';
  @override
  String get concept =>
      '손바느질 펠트 세상 — 통통한 스티치 조각과 천 그림자, 단추와 실. 함께 키우는 펫은 말랑한 펠트 인형.';
  @override
  String get signature =>
      '펫 꾹 누르기 — 손끝 아래에서 말랑 눌렸다 스프링처럼 튕겨오고, 쓰다듬으면 상대에게도 콩콩 진동이 전해진다.';
  @override
  String get inspiration =>
      'Kawaii needle-felt craft + tactile squish toys (felted plushie / running-stitch UI)';
  @override
  Color get accent => _D06.coral;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return switch (screen) {
      HeroScreen.drawSend => _D06DrawSend(data: data),
      HeroScreen.petHome => _D06PetHome(data: data),
      HeroScreen.memoryAlbum => _D06Album(data: data),
    };
  }
}

// ========================================================= stitch/button paint
class _D06StitchPainter extends CustomPainter {
  _D06StitchPainter({
    required this.color,
    this.radius = 18,
    this.inset = 7,
    this.dash = 7,
    this.gap = 5,
    this.stroke = 2.4,
  });
  final Color color;
  final double radius, inset, dash, gap, stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= inset * 2 || size.height <= inset * 2) return;
    final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rr);
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final end = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_D06StitchPainter old) =>
      old.color != color || old.radius != radius || old.inset != inset;
}

class _D06ButtonPainter extends CustomPainter {
  _D06ButtonPainter(this.color, this.hole);
  final Color color;
  final Color hole;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c + const Offset(0, 1), r, Paint()..color = const Color(0x33000000));
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(c, r, Paint()
      ..color = hole.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14);
    final hr = r * 0.16;
    final off = r * 0.34;
    final hp = Paint()..color = hole;
    for (final o in [
      Offset(-off, -off),
      Offset(off, -off),
      Offset(-off, off),
      Offset(off, off),
    ]) {
      canvas.drawCircle(c + o, hr, hp);
    }
  }

  @override
  bool shouldRepaint(_D06ButtonPainter old) => old.color != color || old.hole != hole;
}

class _D06Button extends StatelessWidget {
  const _D06Button({this.size = 16, this.color = _D06.mustard});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _D06ButtonPainter(color, _D06.ink));
}

// ================================================================= felt patch
class _D06Felt extends StatelessWidget {
  const _D06Felt({
    required this.child,
    this.color = _D06.cream,
    this.radius = 26,
    this.padding = const EdgeInsets.all(18),
    this.stitch,
    this.softShadow = false,
  });
  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? stitch;
  final bool softShadow;

  @override
  Widget build(BuildContext context) {
    final st = stitch ?? _D06.stitchOn(color);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: softShadow ? _D06.shadowSoft : _D06.shadow,
      ),
      child: CustomPaint(
        foregroundPainter: _D06StitchPainter(color: st, radius: radius - 7, inset: 7),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// A tappable felt "pill" that presses in on tap-down (fabric squish).
class _D06Press extends StatefulWidget {
  const _D06Press({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  State<_D06Press> createState() => _D06PressState();
}

class _D06PressState extends State<_D06Press> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// A cushiony round felt icon-button.
class _D06Round extends StatelessWidget {
  const _D06Round(this.glyph,
      {this.color = _D06.cream, this.size = 52, this.glyphSize = 22});
  final String glyph;
  final Color color;
  final double size;
  final double glyphSize;
  @override
  Widget build(BuildContext context) {
    return _D06Press(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: _D06.shadowSoft),
        child: CustomPaint(
          foregroundPainter: _D06StitchPainter(
              color: _D06.stitchOn(color), radius: size, inset: 6, dash: 6, gap: 4, stroke: 2),
          child: Center(child: Text(glyph, style: TextStyle(fontSize: glyphSize))),
        ),
      ),
    );
  }
}

// =========================================================== screen scaffold
class _D06Scaffold extends StatelessWidget {
  const _D06Scaffold({required this.body, this.nav});
  final Widget body;
  final Widget? nav;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _D06.cream,
      body: Stack(
        children: [
          // faint fabric weave: two overlaid diagonal tints
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF3EBDC), Color(0xFFE9DEC9)],
                ),
              ),
            ),
          ),
          SafeArea(bottom: nav == null, child: body),
          if (nav != null)
            Positioned(left: 0, right: 0, bottom: 0, child: SafeArea(top: false, child: nav!)),
        ],
      ),
    );
  }
}

class _D06Nav extends StatelessWidget {
  const _D06Nav(this.current);
  final int current; // 0 pet, 1 album, 2 talk
  @override
  Widget build(BuildContext context) {
    const items = [
      ('🧸', '펫키우기'),
      ('🖼️', '사진첩'),
      ('✉️', '소통'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: _D06Felt(
        color: _D06.cream,
        radius: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (int i = 0; i < items.length; i++)
              _D06Press(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 40,
                      decoration: BoxDecoration(
                        color: i == current ? _D06.coral : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(child: Text(items[i].$1, style: const TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(height: 3),
                    Text(items[i].$2,
                        style: _D06.body(11,
                            color: i == current ? _D06.ink : _D06.inkSoft, w: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// A reusable stitched top bar.
class _D06Bar extends StatelessWidget {
  const _D06Bar({this.leading, required this.title, this.trailing, this.subtitle});
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _D06.head(22, sewn: true), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle!, style: _D06.body(12)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ============================================================= 1) DRAW & SEND
class _D06DrawSend extends StatefulWidget {
  const _D06DrawSend({required this.data});
  final AppData data;
  @override
  State<_D06DrawSend> createState() => _D06DrawSendState();
}

class _D06DrawSendState extends State<_D06DrawSend> {
  int pen = 1;
  double thickness = 8;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    return _D06Scaffold(
      body: Column(
        children: [
          _D06Bar(
            leading: const _D06Round('‹', size: 46, glyphSize: 26),
            title: '${couple.partnerNickname}에게',
            subtitle: '펠트 조각에 낙서를 꿰매 보내요',
            trailing: _D06Press(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: _D06.coral,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _D06.shadowSoft,
                ),
                child: CustomPaint(
                  foregroundPainter: _D06StitchPainter(
                      color: _D06.threadLight, radius: 16, inset: 5, dash: 6, gap: 4, stroke: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('보내기', style: _D06.head(14, color: Colors.white)),
                      const SizedBox(width: 4),
                      const Text('🪡', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ---- canvas patch
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: _D06Felt(
                color: _D06.mint,
                radius: 30,
                padding: const EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Positioned(top: 2, left: 2, child: _D06Button(size: 15, color: _D06.mustard)),
                    Positioned(top: 2, right: 2, child: _D06Button(size: 15, color: _D06.coral)),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _D06.threadLight.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('✏️', style: TextStyle(fontSize: 44)),
                          ),
                          const SizedBox(height: 12),
                          Text('여기에 조각조각 그려요',
                              style: _D06.head(15, color: _D06.ink.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    // live stroke preview swatch
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        width: (thickness * 1.8).clamp(10, 40),
                        height: (thickness * 1.8).clamp(10, 40),
                        decoration: BoxDecoration(
                          color: demoPenColors[pen],
                          shape: BoxShape.circle,
                          border: Border.all(color: _D06.threadLight, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ---- tools tray
          _D06Felt(
            color: _D06.cream,
            radius: 28,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // pen yarn spools
                Row(
                  children: [
                    Text('실색', style: _D06.head(13)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (int i = 0; i < demoPenColors.length; i++)
                            _D06Press(
                              onTap: () => setState(() => pen = i),
                              child: _D06Spool(color: demoPenColors[i], selected: pen == i),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // thickness
                Row(
                  children: [
                    Text('굵기', style: _D06.head(13)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 10,
                          activeTrackColor: _D06.coral,
                          inactiveTrackColor: _D06.creamDeep,
                          thumbColor: _D06.mustard,
                          overlayColor: _D06.coral.withValues(alpha: 0.15),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        ),
                        child: Slider(
                          value: thickness,
                          min: 2,
                          max: 20,
                          onChanged: (v) => setState(() => thickness = v),
                        ),
                      ),
                    ),
                    Container(
                      width: 34,
                      alignment: Alignment.center,
                      child: Text('${thickness.round()}', style: _D06.head(14)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // mode toggle
                Row(
                  children: [
                    for (final m in SendMode.values)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: m == SendMode.normal ? 8 : 0),
                          child: _D06Press(
                            onTap: () => setState(() => mode = m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: mode == m ? _D06.mustard : _D06.creamDeep,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: mode == m ? _D06.shadowSoft : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${m == SendMode.normal ? '📌' : '⏳'} ${m.label}',
                                  style: _D06.head(14, color: mode == m ? _D06.ink : _D06.inkSoft),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _D06.mint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(mode.description, style: _D06.body(12, color: _D06.ink)),
                ),
                const SizedBox(height: 12),
                // bottom actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _D06Action('🖼️', '갤러리', _D06.mint),
                    _D06Action('📷', '사진', _D06.mustard),
                    _D06Action('👉', '찌르기', _D06.coral),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _D06Spool extends StatelessWidget {
  const _D06Spool({required this.color, required this.selected});
  final Color color;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: selected ? _D06.shadowSoft : null,
        border: Border.all(color: selected ? _D06.mustard : _D06.cream, width: selected ? 3 : 2),
      ),
      child: CustomPaint(
        painter: _D06StitchPainter(
            color: _D06.stitchOn(color), radius: 34, inset: 5, dash: 4, gap: 3.5, stroke: 1.6),
      ),
    );
  }
}

class _D06Action extends StatelessWidget {
  const _D06Action(this.glyph, this.label, this.color);
  final String glyph;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _D06Round(glyph, color: color, size: 50, glyphSize: 22),
        const SizedBox(height: 5),
        Text(label, style: _D06.body(11, color: _D06.ink, w: FontWeight.w800)),
      ],
    );
  }
}

// ================================================================= 2) PET HOME
class _D06PetHome extends StatefulWidget {
  const _D06PetHome({required this.data});
  final AppData data;
  @override
  State<_D06PetHome> createState() => _D06PetHomeState();
}

class _D06PetHomeState extends State<_D06PetHome> {
  bool _speaking = false;
  bool _buzzed = false;

  void _pat() => setState(() {
        _speaking = true;
        _buzzed = true;
      });

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    return _D06Scaffold(
      nav: const _D06Nav(0),
      body: Column(
        children: [
          _D06Bar(
            title: pet.name,
            subtitle: 'Lv.${pet.level} · 함께 꿰맨 펠트 인형',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _D06.mustard,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _D06.shadowSoft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text('${pet.coins}', style: _D06.head(15, color: _D06.ink)),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Column(
                children: [
                  // speech bubble
                  AnimatedOpacity(
                    opacity: _speaking ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: _D06Felt(
                      color: _D06.mint,
                      radius: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      softShadow: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Flexible(child: Text(pet.speech, style: _D06.head(14, color: _D06.ink))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // the squeezable plushie
                  _D06Plushie(
                    pet: pet,
                    onSquish: _pat,
                  ),
                  const SizedBox(height: 6),
                  Text('꾹 눌러 말랑말랑 · 쓰다듬어 밥 주기',
                      style: _D06.body(12, color: _D06.inkSoft)),
                  const SizedBox(height: 14),
                  // growth gauge
                  _D06Felt(
                    radius: 24,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('성장 게이지', style: _D06.head(15)),
                            const Spacer(),
                            Text('${(pet.growth * 100).round()}%', style: _D06.head(15, color: _D06.coral)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _D06Gauge(value: pet.growth),
                        const SizedBox(height: 8),
                        Text('다음 레벨까지 조금 더 · 낙서할수록 통통해져요',
                            style: _D06.body(12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // pat / feed CTA
                  _D06Press(
                    onTap: _pat,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: _D06.coral,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: _D06.shadowSoft,
                      ),
                      child: CustomPaint(
                        foregroundPainter: _D06StitchPainter(
                            color: _D06.threadLight, radius: 18, inset: 6, dash: 7, gap: 5, stroke: 2),
                        child: Center(
                          child: Text('🫳 쓰다듬고 밥 주기',
                              style: _D06.head(16, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedOpacity(
                    opacity: _buzzed ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Text('📳 토리에게도 콩콩 진동이 전해졌어요',
                        style: _D06.body(12, color: _D06.ink, w: FontWeight.w800)),
                  ),
                  const SizedBox(height: 16),
                  // store
                  _D06Felt(
                    color: _D06.cream,
                    radius: 26,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('바느질 상점', style: _D06.head(16)),
                            const SizedBox(width: 6),
                            const Text('🧶', style: TextStyle(fontSize: 16)),
                            const Spacer(),
                            Text('모자 · 옷 · 집 · 소품', style: _D06.body(11)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 132,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: pet.store.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (_, i) => _D06StoreCard(item: pet.store[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 84),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _D06Gauge extends StatelessWidget {
  const _D06Gauge({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Container(
        height: 20,
        decoration: BoxDecoration(
          color: _D06.creamDeep,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Container(
              width: (w * value).clamp(20.0, w),
              decoration: BoxDecoration(
                color: _D06.coral,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomPaint(
                foregroundPainter: _D06StitchPainter(
                    color: _D06.threadLight, radius: 10, inset: 4, dash: 5, gap: 4, stroke: 1.6),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// The squeezable felt plushie — deforms under a press, springs back.
class _D06Plushie extends StatefulWidget {
  const _D06Plushie({required this.pet, required this.onSquish});
  final Pet pet;
  final VoidCallback onSquish;
  @override
  State<_D06Plushie> createState() => _D06PlushieState();
}

class _D06PlushieState extends State<_D06Plushie> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onSquish();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: 260,
        height: 240,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _pressed ? 1.0 : 0.0),
          duration: Duration(milliseconds: _pressed ? 120 : 640),
          curve: _pressed ? Curves.easeOut : Curves.elasticOut,
          builder: (context, t, child) {
            final sx = 1 + 0.16 * t; // widen
            final sy = 1 - 0.15 * t; // squash
            return Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(sx, sy, 1.0),
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // shadow puddle
              Positioned(
                bottom: 8,
                child: Container(
                  width: 150,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0x2E6B4A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              // felt body
              Positioned(
                bottom: 20,
                child: Container(
                  width: 186,
                  height: 176,
                  decoration: BoxDecoration(
                    color: _D06.mustard,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(90),
                      topRight: Radius.circular(90),
                      bottomLeft: Radius.circular(72),
                      bottomRight: Radius.circular(72),
                    ),
                    boxShadow: _D06.shadow,
                  ),
                  child: CustomPaint(
                    foregroundPainter: _D06StitchPainter(
                        color: _D06.threadLight, radius: 78, inset: 9, dash: 8, gap: 6, stroke: 2.4),
                    child: Center(
                      child: Text(pet.moodEmoji, style: const TextStyle(fontSize: 84)),
                    ),
                  ),
                ),
              ),
              // stitched cheek patches (buttons as decorative accents)
              const Positioned(bottom: 96, left: 58, child: _D06Button(size: 14, color: _D06.coral)),
              const Positioned(bottom: 96, right: 58, child: _D06Button(size: 14, color: _D06.coral)),
              // equipped hat floats on top
              if (equipped.isNotEmpty)
                Positioned(
                  top: 2,
                  child: Text(equipped.first.emoji, style: const TextStyle(fontSize: 40)),
                ),
              // equipped prop tucked at the base corner
              if (equipped.length > 1)
                Positioned(
                  bottom: 14,
                  right: 20,
                  child: Text(equipped[1].emoji, style: const TextStyle(fontSize: 34)),
                ),
              // level ribbon
              Positioned(
                bottom: 26,
                left: 8,
                child: _D06Felt(
                  color: _D06.mint,
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  softShadow: true,
                  child: Text('Lv.${pet.level}', style: _D06.head(13, color: _D06.ink)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _D06StoreCard extends StatelessWidget {
  const _D06StoreCard({required this.item});
  final PetItem item;
  @override
  Widget build(BuildContext context) {
    final ring = item.equipped ? _D06.mustard : _D06.cream;
    return SizedBox(
      width: 98,
      child: _D06Felt(
        color: _D06.creamDeep,
        radius: 22,
        stitch: item.equipped ? _D06.mustard : _D06.stitchOn(_D06.creamDeep),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        softShadow: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _D06.cream,
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2),
              ),
              child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 26))),
            ),
            Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _D06.head(12, color: _D06.ink)),
            _D06StoreStatus(item: item),
          ],
        ),
      ),
    );
  }
}

class _D06StoreStatus extends StatelessWidget {
  const _D06StoreStatus({required this.item});
  final PetItem item;
  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = item.equipped
        ? (_D06.mustard, _D06.ink, '착용중')
        : item.owned
            ? (_D06.mint, _D06.ink, '보유')
            : (_D06.coral, Colors.white, '🪙${item.price}');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: _D06.head(11, color: fg)),
    );
  }
}

// ================================================================ 3) ALBUM
class _D06Album extends StatefulWidget {
  const _D06Album({required this.data});
  final AppData data;
  @override
  State<_D06Album> createState() => _D06AlbumState();
}

class _D06AlbumState extends State<_D06Album> {
  bool byDate = true;
  DoodleType? filter;

  @override
  Widget build(BuildContext context) {
    var items = widget.data.album.where((d) => filter == null || d.type == filter).toList();
    if (byDate) {
      items.sort((a, b) => b.at.compareTo(a.at));
    } else {
      items.sort((a, b) => a.type.index.compareTo(b.type.index));
    }

    return _D06Scaffold(
      nav: const _D06Nav(1),
      body: Column(
        children: [
          _D06Bar(
            title: '낙서 조각보',
            subtitle: '함께 꿰맨 ${widget.data.album.length}개의 추억',
            trailing: _D06Press(
              onTap: () => setState(() => byDate = !byDate),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _D06.mustard,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _D06.shadowSoft,
                ),
                child: Text(byDate ? '🗓️ 날짜별' : '🧵 유형별', style: _D06.head(13, color: _D06.ink)),
              ),
            ),
          ),
          // filter chips
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _D06Chip(label: '전체', selected: filter == null, onTap: () => setState(() => filter = null)),
                for (final t in DoodleType.values)
                  _D06Chip(
                    label: t.label,
                    selected: filter == t,
                    onTap: () => setState(() => filter = t),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.70,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _D06Patch(doodle: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _D06Chip extends StatelessWidget {
  const _D06Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: _D06Press(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? _D06.coral : _D06.cream,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected ? _D06.shadowSoft : null,
          ),
          child: CustomPaint(
            foregroundPainter: selected
                ? _D06StitchPainter(
                    color: _D06.threadLight, radius: 14, inset: 5, dash: 5, gap: 4, stroke: 1.8)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Text(label,
                  style: _D06.head(13, color: selected ? Colors.white : _D06.inkSoft)),
            ),
          ),
        ),
      ),
    );
  }
}

class _D06Patch extends StatefulWidget {
  const _D06Patch({required this.doodle});
  final Doodle doodle;
  @override
  State<_D06Patch> createState() => _D06PatchState();
}

class _D06PatchState extends State<_D06Patch> {
  late bool liked = widget.doodle.liked;
  @override
  Widget build(BuildContext context) {
    final d = widget.doodle;
    return _D06Felt(
      color: _D06.cream,
      radius: 24,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // fabric "photo"
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: d.swatch,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                foregroundPainter: _D06StitchPainter(
                    color: _D06.threadLight, radius: 12, inset: 5, dash: 6, gap: 4, stroke: 2),
                child: Stack(
                  children: [
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(d.type.label,
                            style: _D06.head(9, color: _D06.ink, ls: 0)),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _D06Press(
                        onTap: () => setState(() => liked = !liked),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Text(liked ? '❤️' : '🤍', style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                    if (d.mode == SendMode.disappearing)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('⏳ 사라짐', style: _D06.head(9, color: Colors.white, ls: 0)),
                        ),
                      ),
                    Center(child: Text(d.emoji, style: const TextStyle(fontSize: 46))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(d.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _D06.head(14, color: _D06.ink)),
          const SizedBox(height: 2),
          Row(
            children: [
              const _D06Button(size: 11, color: _D06.mint),
              const SizedBox(width: 5),
              Expanded(
                child: Text('${d.author} · ${d.at.month}/${d.at.day}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _D06.body(11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
