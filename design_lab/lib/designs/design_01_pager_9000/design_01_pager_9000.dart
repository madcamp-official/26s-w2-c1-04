// design_01_pager_9000 — "PAGER-9000"
//
// A screaming black-and-phosphor terminal that treats every memory as an
// incoming page. Hard borders, zero radius, dot-matrix everything, monospace at
// two brutal sizes. A real 5x7 dot-matrix font engine renders every numeral;
// the fat physical SEND PAGE button depresses with a ka-chunk and transmits the
// doodle as a dot-matrix wipe that reassembles pixel-by-pixel like a '90s beep-in.
//
// Fully self-contained. Everything except `Design01` is private with a _D01
// prefix so it never clashes with the other nine variants.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

class Design01 extends DesignVariant {
  @override
  String get id => '01';
  @override
  String get name => 'PAGER-9000';
  @override
  String get concept =>
      '흑색-인광 터미널. 모든 추억을 수신되는 삐삐 페이지로 취급 — 각진 테두리, 도트매트릭스, 모노스페이스 2단.';
  @override
  String get signature =>
      '물리 SEND PAGE 버튼이 카-청 눌리고, 낙서가 도트매트릭스 와이프로 픽셀 단위 재조립되며 전송.';
  @override
  String get inspiration => '1990s numeric pagers · dot-matrix LED signs · CRT phosphor terminals';
  @override
  Color get accent => _D01.orange;
  @override
  Brightness get brightness => Brightness.dark;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return switch (screen) {
      HeroScreen.drawSend => _D01DrawSend(data: data),
      HeroScreen.petHome => _D01PetHome(data: data),
      HeroScreen.memoryAlbum => _D01Album(data: data),
    };
  }
}

// =============================================================== design tokens
class _D01 {
  static const black = Color(0xFF000000);
  static const phos = Color(0xFF39FF14);
  static const orange = Color(0xFFFF6A00);
  static const dim = Color(0xFF2A2A2A);
  static const offDot = Color(0xFF0E2A08); // unlit dot on a matrix display
  static const panel = Color(0xFF050A05);
  static const edgeGreen = Color(0xFF1A7A0A);
  static const edgeOrange = Color(0xFF803400);

  static const mono = 'Courier New';
  static const List<String> monoFallback = ['monospace', 'Menlo', 'Consolas', 'Roboto Mono'];

  static TextStyle head(double size, Color color) => TextStyle(
        fontFamily: mono,
        fontFamilyFallback: monoFallback,
        fontSize: size,
        height: 1.0,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 1.5,
      );

  static TextStyle cap(Color color, {double size = 11, FontWeight w = FontWeight.w700, double ls = 1.0}) =>
      TextStyle(
        fontFamily: mono,
        fontFamilyFallback: monoFallback,
        fontSize: size,
        fontWeight: w,
        color: color,
        letterSpacing: ls,
        height: 1.2,
      );
}

// ============================================================= 5x7 dot font
class _D01Font {
  static const List<String> blank = ['00000', '00000', '00000', '00000', '00000', '00000', '00000'];
  static const Map<String, List<String>> glyphs = {
    '0': ['01110', '10001', '10011', '10101', '11001', '10001', '01110'],
    '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
    '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
    '3': ['11111', '00010', '00100', '00010', '00001', '10001', '01110'],
    '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
    '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
    '6': ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
    '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
    '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
    '9': ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
    '/': ['00001', '00001', '00010', '00100', '01000', '10000', '10000'],
    '%': ['11000', '11001', '00010', '00100', '01000', '10011', '00011'],
    '.': ['00000', '00000', '00000', '00000', '00000', '01100', '01100'],
    ':': ['00000', '01100', '01100', '00000', '01100', '01100', '00000'],
    '-': ['00000', '00000', '00000', '11111', '00000', '00000', '00000'],
    '+': ['00000', '00100', '00100', '11111', '00100', '00100', '00000'],
    ' ': blank,
  };
}

class _D01Matrix extends StatelessWidget {
  final String text;
  final double cell;
  final Color color;
  final Color off;
  const _D01Matrix(this.text, {this.cell = 4, this.color = _D01.phos, this.off = _D01.offDot});

  @override
  Widget build(BuildContext context) {
    final n = text.length;
    final w = n <= 0 ? 0.0 : (n * 6 - 1) * cell;
    final h = 7 * cell;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(painter: _D01MatrixPainter(text.toUpperCase(), cell, color, off)),
    );
  }
}

class _D01MatrixPainter extends CustomPainter {
  final String text;
  final double cell;
  final Color color;
  final Color off;
  _D01MatrixPainter(this.text, this.cell, this.color, this.off);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final r = cell * 0.42;
    for (int i = 0; i < text.length; i++) {
      final g = _D01Font.glyphs[text[i]] ?? _D01Font.blank;
      final ox = i * 6 * cell;
      for (int row = 0; row < 7; row++) {
        final line = g[row];
        for (int col = 0; col < 5; col++) {
          final on = col < line.length && line[col] == '1';
          p.color = on ? color : off;
          canvas.drawCircle(Offset(ox + col * cell + cell / 2, row * cell + cell / 2), r, p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _D01MatrixPainter o) =>
      o.text != text || o.color != color || o.off != off || o.cell != cell;
}

// ============================================================= CRT overlays
class _D01ScanPainter extends CustomPainter {
  const _D01ScanPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (double y = 0; y < s.height; y += 3) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _D01DotGridPainter extends CustomPainter {
  const _D01DotGridPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = _D01.offDot;
    const step = 13.0;
    for (double y = step / 2; y < s.height; y += step) {
      for (double x = step / 2; x < s.width; x += step) {
        c.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _D01TransmitPainter extends CustomPainter {
  final double progress;
  _D01TransmitPainter(this.progress);
  @override
  void paint(Canvas c, Size s) {
    const pitch = 9.0;
    final cols = (s.width / pitch).floor();
    final rows = (s.height / pitch).floor();
    final lit = Paint()..color = _D01.phos;
    final unlit = Paint()..color = _D01.offDot;
    for (int r = 0; r < rows; r++) {
      for (int col = 0; col < cols; col++) {
        // deterministic scattered reveal order → pixel-by-pixel beep-in
        final threshold = (((r * 73856093) ^ (col * 19349663)) & 0x3ff) / 1023.0;
        final on = threshold <= progress;
        c.drawCircle(
          Offset(col * pitch + pitch / 2, r * pitch + pitch / 2),
          on ? 3.0 : 1.2,
          on ? lit : unlit,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _D01TransmitPainter o) => o.progress != progress;
}

// ============================================================= shared chrome
Widget _d01Scaffold({required Widget body, Widget? bottomNav}) {
  return Scaffold(
    backgroundColor: _D01.black,
    body: SafeArea(
      top: true,
      bottom: bottomNav == null,
      child: Stack(
        children: [
          Positioned.fill(child: body),
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _D01ScanPainter())),
          ),
        ],
      ),
    ),
    bottomNavigationBar: bottomNav,
  );
}

class _D01Blink extends StatefulWidget {
  final Widget child;
  const _D01Blink({required this.child});
  @override
  State<_D01Blink> createState() => _D01BlinkState();
}

class _D01BlinkState extends State<_D01Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 720))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.15).animate(_c),
      child: widget.child,
    );
  }
}

class _D01IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _D01IconBtn(this.icon, this.onTap, {this.color = _D01.phos});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 34,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: _D01.black, border: Border.all(color: color, width: 2)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _D01TopBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  const _D01TopBar({required this.title, this.leading, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _D01.phos, width: 2))),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Text('▛ $title', style: _D01.cap(_D01.phos, size: 12, ls: 1.5)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _D01Nav extends StatelessWidget {
  final int current;
  const _D01Nav(this.current);
  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    const icons = [Icons.pets, Icons.dashboard_outlined, Icons.podcasts];
    return Container(
      color: _D01.black,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _D01.phos, width: 2))),
          child: Row(
            children: [
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => HapticFeedback.selectionClick(),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: i == current ? _D01.orange : _D01.black,
                        border: Border(
                          right: i < 2 ? const BorderSide(color: _D01.dim, width: 1) : BorderSide.none,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icons[i], size: 20, color: i == current ? _D01.black : _D01.phos),
                          const SizedBox(height: 4),
                          Text(
                            labels[i],
                            style: _D01.cap(i == current ? _D01.black : _D01.phos, size: 10, ls: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Fat physical button that depresses with a ka-chunk.
class _D01BigButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color edge;
  final VoidCallback onPressed;
  const _D01BigButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.edge,
    required this.onPressed,
  });
  @override
  State<_D01BigButton> createState() => _D01BigButtonState();
}

class _D01BigButtonState extends State<_D01BigButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.heavyImpact();
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 55),
        transform: Matrix4.translationValues(0, _down ? 5.0 : 0.0, 0),
        height: 60,
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(color: _D01.black, width: 2),
          boxShadow: [
            BoxShadow(color: widget.edge, offset: Offset(0, _down ? 1.0 : 7.0), blurRadius: 0),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: _D01.black, size: 22),
            const SizedBox(width: 10),
            Text(widget.label, style: _D01.head(18, _D01.black)),
          ],
        ),
      ),
    );
  }
}

class _D01Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color onColor;
  const _D01Toggle(this.label, this.selected, this.onTap, {this.onColor = _D01.phos});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? onColor : _D01.black,
          border: Border.all(color: onColor, width: 2),
        ),
        child: Text(label, style: _D01.cap(selected ? _D01.black : onColor, size: 12, ls: 1.2)),
      ),
    );
  }
}

// ================================================================ DRAW & SEND
class _D01DrawSend extends StatefulWidget {
  final AppData data;
  const _D01DrawSend({required this.data});
  @override
  State<_D01DrawSend> createState() => _D01DrawSendState();
}

class _D01DrawSendState extends State<_D01DrawSend> with SingleTickerProviderStateMixin {
  int pen = 1;
  int thickness = 4;
  SendMode mode = SendMode.normal;
  bool sending = false;

  late final AnimationController _tx =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void initState() {
    super.initState();
    _tx.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tx.dispose();
    super.dispose();
  }

  void _send() {
    if (sending) return;
    setState(() => sending = true);
    _tx.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.data.couple;
    return _d01Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _D01TopBar(
              title: 'PAGE COMPOSER',
              leading: _D01IconBtn(Icons.chevron_left, () {}),
              trailing: Row(
                children: [
                  const _D01Blink(child: Icon(Icons.circle, color: _D01.orange, size: 9)),
                  const SizedBox(width: 5),
                  Text('LINK OK', style: _D01.cap(_D01.orange, size: 10)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('▶ TO:', style: _D01.cap(_D01.phos, size: 12)),
                const SizedBox(width: 6),
                Text(c.partnerNickname, style: _D01.head(20, _D01.phos)),
                const Spacer(),
                Text('CH.01', style: _D01.cap(_D01.phos, size: 11)),
                const SizedBox(width: 6),
                _D01Matrix('${c.streakDays}', cell: 3.2, color: _D01.orange),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: _canvas()),
            const SizedBox(height: 10),
            _penRow(),
            const SizedBox(height: 8),
            _thicknessRow(),
            const SizedBox(height: 8),
            _modeRow(),
            const SizedBox(height: 6),
            Text('▷ ${mode.description}', style: _D01.cap(_D01.phos.withOpacity(0.8), size: 10, ls: 0.5)),
            const SizedBox(height: 10),
            _actionsRow(),
            const SizedBox(height: 10),
            _D01BigButton(
              label: 'SEND PAGE',
              icon: Icons.podcasts,
              color: _D01.orange,
              edge: _D01.edgeOrange,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _canvas() {
    return Container(
      decoration: BoxDecoration(color: _D01.panel, border: Border.all(color: _D01.phos, width: 2)),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _D01DotGridPainter())),
          Positioned(
            left: 8,
            top: 6,
            child: Row(
              children: [
                const _D01Blink(child: Icon(Icons.fiber_manual_record, color: _D01.orange, size: 10)),
                const SizedBox(width: 4),
                Text('REC', style: _D01.cap(_D01.orange, size: 10)),
              ],
            ),
          ),
          Positioned(right: 8, top: 6, child: Text('428x480', style: _D01.cap(_D01.dim, size: 9))),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✎', style: TextStyle(fontSize: 46, color: _D01.phos.withOpacity(0.85))),
                const SizedBox(height: 8),
                Text('TAP TO DRAW', style: _D01.head(20, _D01.phos)),
                const SizedBox(height: 4),
                Text('// DOT-MATRIX CANVAS', style: _D01.cap(_D01.phos.withOpacity(0.6), size: 10)),
              ],
            ),
          ),
          if (sending)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (_tx.isCompleted) setState(() => sending = false);
                },
                child: Container(
                  color: _D01.black,
                  child: Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: _D01TransmitPainter(_tx.value))),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          color: _D01.black.withOpacity(0.82),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _tx.isCompleted ? '◉ PAGE SENT' : '◉ TRANSMITTING',
                                style: _D01.cap(_tx.isCompleted ? _D01.orange : _D01.phos, size: 12, ls: 2),
                              ),
                              const SizedBox(height: 8),
                              _D01Matrix('${(_tx.value * 100).floor()}%',
                                  cell: 6, color: _tx.isCompleted ? _D01.orange : _D01.phos),
                              const SizedBox(height: 8),
                              Text(
                                _tx.isCompleted ? 'TAP TO CLOSE' : 'DO NOT POWER OFF',
                                style: _D01.cap(_D01.phos.withOpacity(0.7), size: 9, ls: 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _penRow() {
    return Row(
      children: [
        Text('PEN', style: _D01.cap(_D01.phos, size: 11)),
        const SizedBox(width: 10),
        for (int i = 0; i < demoPenColors.length; i++)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => pen = i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: demoPenColors[i],
                border: Border.all(color: pen == i ? _D01.orange : _D01.dim, width: pen == i ? 3 : 1),
              ),
            ),
          ),
        const Spacer(),
        _D01Matrix('0${pen + 1}', cell: 3.4, color: _D01.orange),
      ],
    );
  }

  Widget _thicknessRow() {
    return Row(
      children: [
        Text('WIDTH', style: _D01.cap(_D01.phos, size: 11)),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              for (int i = 0; i < 8; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => thickness = i + 1);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 3),
                      height: 16,
                      decoration: BoxDecoration(
                        color: i < thickness ? _D01.phos : _D01.black,
                        border: Border.all(color: _D01.dim, width: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: thickness * 2.0 + 4,
          height: thickness * 2.0 + 4,
          decoration: const BoxDecoration(color: _D01.phos, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _modeRow() {
    return Row(
      children: [
        Text('MODE', style: _D01.cap(_D01.phos, size: 11)),
        const SizedBox(width: 10),
        Expanded(
          child: _D01Toggle(SendMode.normal.label, mode == SendMode.normal,
              () => setState(() => mode = SendMode.normal)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _D01Toggle(SendMode.disappearing.label, mode == SendMode.disappearing,
              () => setState(() => mode = SendMode.disappearing),
              onColor: _D01.orange),
        ),
      ],
    );
  }

  Widget _actionsRow() {
    return Row(
      children: [
        Expanded(child: _D01ActionBtn(Icons.photo_library_outlined, '갤러리')),
        const SizedBox(width: 8),
        Expanded(child: _D01ActionBtn(Icons.photo_camera_outlined, '사진')),
        const SizedBox(width: 8),
        Expanded(child: _D01ActionBtn(Icons.notifications_active_outlined, '찌르기', color: _D01.orange)),
      ],
    );
  }
}

class _D01ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _D01ActionBtn(this.icon, this.label, {this.color = _D01.phos});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: _D01.black, border: Border.all(color: color, width: 2)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: _D01.cap(color, size: 10, ls: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ==================================================================== PET HOME
class _D01PetHome extends StatefulWidget {
  final AppData data;
  const _D01PetHome({required this.data});
  @override
  State<_D01PetHome> createState() => _D01PetHomeState();
}

class _D01PetHomeState extends State<_D01PetHome> {
  bool patted = false;
  double _scale = 1;

  void _pat() {
    HapticFeedback.lightImpact();
    setState(() {
      patted = true;
      _scale = _scale == 1 ? 1.14 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((e) => e.equipped).toList();
    final filled = (pet.growth * 20).round();
    return _d01Scaffold(
      bottomNav: const _D01Nav(0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _D01TopBar(
            title: 'PET UNIT :: ${pet.name}',
            trailing: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                _D01Matrix('${pet.coins}', cell: 3.4, color: _D01.orange),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- pet enclosure
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    decoration: BoxDecoration(color: _D01.panel, border: Border.all(color: _D01.phos, width: 2)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('UNIT #${pet.level}07', style: _D01.cap(_D01.phos.withOpacity(0.6), size: 10)),
                            const Spacer(),
                            const _D01Blink(child: Icon(Icons.circle, color: _D01.phos, size: 8)),
                            const SizedBox(width: 5),
                            Text('ONLINE', style: _D01.cap(_D01.phos, size: 10)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (patted)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(border: Border.all(color: _D01.orange, width: 2)),
                            child: Text('${pet.name} >> ${pet.speech}',
                                style: _D01.cap(_D01.orange, size: 11, ls: 0.4)),
                          ),
                        GestureDetector(
                          onTap: _pat,
                          child: SizedBox(
                            height: 128,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Positioned.fill(child: CustomPaint(painter: _D01DotGridPainter())),
                                Positioned(
                                  top: 8,
                                  child: Text(equipped.isNotEmpty ? equipped.first.emoji : '',
                                      style: const TextStyle(fontSize: 30)),
                                ),
                                AnimatedScale(
                                  scale: _scale,
                                  duration: const Duration(milliseconds: 170),
                                  child: Text(pet.moodEmoji, style: const TextStyle(fontSize: 76)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(pet.name, style: _D01.head(30, _D01.phos)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('LV', style: _D01.cap(_D01.phos, size: 11)),
                            const SizedBox(width: 6),
                            _D01Matrix('0${pet.level}', cell: 4, color: _D01.orange),
                            const SizedBox(width: 16),
                            Text('STREAK', style: _D01.cap(_D01.phos, size: 11)),
                            const SizedBox(width: 6),
                            _D01Matrix('${widget.data.couple.streakDays}', cell: 4, color: _D01.orange),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // growth gauge
                        Row(
                          children: [
                            Text('GROW', style: _D01.cap(_D01.phos, size: 11)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  for (int i = 0; i < 20; i++)
                                    Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 2),
                                        height: 12,
                                        color: i < filled ? _D01.phos : _D01.offDot,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _D01Matrix('${(pet.growth * 100).round()}%', cell: 3, color: _D01.phos),
                          ],
                        ),
                        if (equipped.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text('EQUIP', style: _D01.cap(_D01.phos.withOpacity(0.6), size: 10)),
                              const SizedBox(width: 8),
                              Text(equipped.map((e) => e.emoji).join('  '),
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        _D01BigButton(
                          label: 'PAT UNIT',
                          icon: Icons.back_hand_outlined,
                          color: _D01.phos,
                          edge: _D01.edgeGreen,
                          onPressed: _pat,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // --- store
                  Row(
                    children: [
                      Text('STORE', style: _D01.head(20, _D01.phos)),
                      const SizedBox(width: 8),
                      Text('// 상점', style: _D01.cap(_D01.phos.withOpacity(0.6), size: 11)),
                      const Spacer(),
                      const Text('🪙', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      _D01Matrix('${pet.coins}', cell: 2.8, color: _D01.orange),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: pet.store.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _storeCard(pet.store[i]),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeCard(PetItem it) {
    final Color b = it.equipped ? _D01.orange : (it.owned ? _D01.phos : _D01.dim);
    return Container(
      width: 92,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: _D01.panel, border: Border.all(color: b, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(it.category, style: _D01.cap(_D01.phos.withOpacity(0.55), size: 9, ls: 0.5)),
          const SizedBox(height: 4),
          Center(child: Text(it.emoji, style: const TextStyle(fontSize: 34))),
          const Spacer(),
          if (it.owned)
            Text(it.equipped ? '● 착용중' : '○ 보유', style: _D01.cap(b, size: 10))
          else
            Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                _D01Matrix('${it.price}', cell: 2.4, color: _D01.phos),
              ],
            ),
        ],
      ),
    );
  }
}

// ================================================================ MEMORY ALBUM
class _D01Album extends StatefulWidget {
  final AppData data;
  const _D01Album({required this.data});
  @override
  State<_D01Album> createState() => _D01AlbumState();
}

class _D01AlbumState extends State<_D01Album> {
  bool byDate = true;
  DoodleType? filter;

  @override
  Widget build(BuildContext context) {
    final items = widget.data.album.where((d) => filter == null || d.type == filter).toList();
    items.sort((a, b) {
      if (byDate) return b.at.compareTo(a.at);
      final t = a.type.index.compareTo(b.type.index);
      return t != 0 ? t : b.at.compareTo(a.at);
    });
    return _d01Scaffold(
      bottomNav: const _D01Nav(1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _D01TopBar(
            title: 'MEMORY LOG',
            trailing: Row(
              children: [
                Text('PAGES', style: _D01.cap(_D01.phos.withOpacity(0.6), size: 10)),
                const SizedBox(width: 6),
                _D01Matrix('${widget.data.album.length}', cell: 3.4, color: _D01.orange),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Text('SORT', style: _D01.cap(_D01.phos, size: 11)),
                const SizedBox(width: 10),
                _D01Toggle('날짜별', byDate, () => setState(() => byDate = true)),
                const SizedBox(width: 8),
                _D01Toggle('유형별', !byDate, () => setState(() => byDate = false), onColor: _D01.orange),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _filterChip('전체', filter == null, () => setState(() => filter = null)),
                for (final t in DoodleType.values)
                  _filterChip(t.label, filter == t, () => setState(() => filter = t)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _pageRow(items[i], i + 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: sel ? _D01.phos : _D01.black,
            border: Border.all(color: _D01.phos, width: 2),
          ),
          child: Text(label, style: _D01.cap(sel ? _D01.black : _D01.phos, size: 11, ls: 0.5)),
        ),
      ),
    );
  }

  Widget _pageRow(Doodle d, int index) {
    final wipe = d.mode == SendMode.disappearing;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _D01.panel, border: Border.all(color: _D01.phos, width: 2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // index + date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PAGE', style: _D01.cap(_D01.phos.withOpacity(0.55), size: 8, ls: 1)),
              const SizedBox(height: 3),
              _D01Matrix(index.toString().padLeft(3, '0'), cell: 3, color: _D01.orange),
              const SizedBox(height: 8),
              _D01Matrix('${d.at.month}/${d.at.day}', cell: 2.6, color: _D01.phos),
            ],
          ),
          const SizedBox(width: 12),
          // swatch thumbnail
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: d.swatch, begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border.all(color: _D01.phos, width: 2),
            ),
            child: Text(d.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 12),
          // meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.caption, style: _D01.head(15, _D01.phos), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text('FROM ${d.author}', style: _D01.cap(_D01.phos.withOpacity(0.7), size: 10, ls: 0.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _tag(d.type.label, _D01.phos),
                    const SizedBox(width: 6),
                    _tag(wipe ? 'AUTO-WIPE' : 'PINNED', wipe ? _D01.orange : _D01.dim),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            d.liked ? Icons.favorite : Icons.favorite_border,
            color: d.liked ? _D01.orange : _D01.dim,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: color, width: 1)),
      child: Text(label, style: _D01.cap(color, size: 9, ls: 0.3)),
    );
  }
}
