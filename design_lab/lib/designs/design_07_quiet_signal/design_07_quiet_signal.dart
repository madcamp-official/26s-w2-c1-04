// design_07_quiet_signal — "Quiet Signal".
//
// Low-stimulus warm-paper calm: one strong memory per screen, generous space,
// and a single blinking pager cursor standing in for all ornament. Near-
// monochrome ink on paper with one muted clay accent. Every gesture carries a
// distinct haptic voice — the thumb feels the signal before the eyes read it.
//
// Self-contained: no external packages, no assets, no network, no Random,
// no DateTime.now(). Imagery is gradient + emoji from shared demo data.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ---------------------------------------------------------------- palette
const Color _d07Paper = Color(0xFFF5F1E8);
const Color _d07PaperDim = Color(0xFFEDE7DA);
const Color _d07Ink = Color(0xFF2B2A26);
const Color _d07Clay = Color(0xFFB98A6E);

Color _d07InkA(double a) => _d07Ink.withOpacity(a);
Color _d07ClayA(double a) => _d07Clay.withOpacity(a);

// mono-tinged label voice: evenly spaced, quiet, lots of air.
TextStyle _d07Mono({
  double size = 11,
  Color color = _d07Ink,
  FontWeight weight = FontWeight.w500,
  double spacing = 2.2,
}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.35,
    );

// restrained sans for body / captions.
TextStyle _d07Sans({
  double size = 14,
  Color color = _d07Ink,
  FontWeight weight = FontWeight.w400,
  double spacing = 0.4,
  double height = 1.45,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

class Design07 extends DesignVariant {
  @override
  String get id => '07';
  @override
  String get name => 'Quiet Signal';
  @override
  String get concept =>
      '저자극 웜페이퍼 정적 — 화면당 하나의 강한 기억, 넉넉한 여백, 모든 장식을 대신하는 하나의 깜빡이는 삐삐 커서.';
  @override
  String get signature =>
      '모든 제스처가 고유한 촉각의 목소리를 가진다 — 받은 기억엔 한 번의 진동, 상대가 지금 낙서 중이면 부드러운 두 번의 두드림. 눈보다 엄지가 먼저 신호를 읽는다.';
  @override
  String get inspiration =>
      'Pager/analog restraint · warm-paper minimalism · terminal cursor as sole ornament';
  @override
  Color get accent => _d07Clay;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d07Sans(),
      child: switch (screen) {
        HeroScreen.drawSend => _D07DrawSend(data: data),
        HeroScreen.petHome => _D07PetHome(data: data),
        HeroScreen.memoryAlbum => _D07Album(data: data),
      },
    );
  }
}

// ============================================================== blinking cursor
// The lone pager cursor — the only ornament in the whole language.
class _D07Cursor extends StatefulWidget {
  const _D07Cursor({
    this.color = _d07Clay,
    this.width = 8,
    this.height = 18,
  });
  final Color color;
  final double width;
  final double height;
  @override
  State<_D07Cursor> createState() => _D07CursorState();
}

class _D07CursorState extends State<_D07Cursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1080),
    )..repeat();
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
        // hard square blink like a terminal caret.
        final on = _c.value < 0.55;
        return Opacity(
          opacity: on ? 1 : 0.0,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        );
      },
    );
  }
}

// A hairline divider, the paper's quiet grid line.
class _D07Hair extends StatelessWidget {
  const _D07Hair({this.opacity = 0.10, this.indent = 0});
  final double opacity;
  final double indent;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(horizontal: indent),
      color: _d07InkA(opacity),
    );
  }
}

// Small spaced-out section eyebrow, e.g. "· 신호 01 ·".
class _D07Eyebrow extends StatelessWidget {
  const _D07Eyebrow(this.text, {this.color = _d07Ink});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: _d07Mono(size: 10, color: color.withOpacity(0.55), spacing: 3));
  }
}

// ================================================================== Draw & Send
class _D07DrawSend extends StatefulWidget {
  const _D07DrawSend({required this.data});
  final AppData data;
  @override
  State<_D07DrawSend> createState() => _D07DrawSendState();
}

class _D07DrawSendState extends State<_D07DrawSend> {
  int pen = 2; // start on muted-warm-ish
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    return Scaffold(
      backgroundColor: _d07Paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- top bar: back / recipient / send
              Row(
                children: [
                  _D07IconTap(
                    icon: Icons.arrow_back,
                    onTap: () => HapticFeedback.selectionClick(),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      _D07Eyebrow('TO'),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(couple.partnerNickname,
                              style: _d07Sans(
                                  size: 17, weight: FontWeight.w600, spacing: 1.5)),
                          const SizedBox(width: 4),
                          const _D07Cursor(width: 6, height: 15),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  _D07SendButton(
                    onTap: () => HapticFeedback.mediumImpact(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ---- live partner status (double-tap haptic voice)
              _D07LiveStatus(nick: couple.partnerNickname),
              const SizedBox(height: 14),
              // ---- the canvas: one big quiet field with a lone cursor
              Expanded(child: _canvas()),
              const SizedBox(height: 20),
              // ---- pen colors
              _D07Eyebrow('· 잉크'),
              const SizedBox(height: 12),
              _penRow(),
              const SizedBox(height: 22),
              // ---- thickness
              Row(
                children: [
                  _D07Eyebrow('· 굵기'),
                  const Spacer(),
                  Text('${thickness.round()}',
                      style: _d07Mono(size: 11, color: _d07Clay, spacing: 1)),
                ],
              ),
              const SizedBox(height: 10),
              _D07Thickness(
                value: thickness,
                color: demoPenColors[pen],
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => thickness = v);
                },
              ),
              const SizedBox(height: 22),
              _D07Hair(),
              const SizedBox(height: 16),
              // ---- mode toggle + description
              _modeToggle(),
              const SizedBox(height: 10),
              Text(mode.description,
                  style: _d07Sans(
                      size: 12, color: _d07InkA(0.55), spacing: 0.3)),
              const SizedBox(height: 18),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _d07InkA(0.14)),
      ),
      child: Stack(
        children: [
          // faint ruled baseline — the paper's quiet grid
          Positioned.fill(
            child: CustomPaint(painter: _D07RulePainter()),
          ),
          // corner registration marks (pager print feel)
          const Positioned(top: 12, left: 12, child: _D07Tick()),
          const Positioned(top: 12, right: 12, child: _D07Tick()),
          const Positioned(bottom: 12, left: 12, child: _D07Tick()),
          const Positioned(bottom: 12, right: 12, child: _D07Tick()),
          // one strong prompt + lone blinking cursor + stroke preview
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('여기서부터',
                        style: _d07Sans(
                            size: 15, color: _d07InkA(0.4), spacing: 0.5)),
                    const SizedBox(width: 6),
                    _D07Cursor(color: ink, width: 9, height: 22),
                  ],
                ),
                const SizedBox(height: 18),
                // current stroke preview — a single mark of the chosen ink
                Container(
                  width: 108,
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
                    shape: BoxShape.circle,
                    border: Border.all(color: _d07InkA(0.18)),
                  ),
                ),
                const SizedBox(height: 8),
                // selection = a lone cursor tick under the swatch
                SizedBox(
                  height: 12,
                  child: pen == i
                      ? const _D07Cursor(width: 12, height: 3)
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

  Widget _modeToggle() {
    return Row(
      children: [
        for (final m in SendMode.values) ...[
          _D07ModeTab(
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
        _D07Action(
          glyph: '🖼',
          label: '갤러리',
          onTap: () => HapticFeedback.selectionClick(),
        ),
        _D07Action(
          glyph: '📷',
          label: '사진',
          onTap: () => HapticFeedback.selectionClick(),
        ),
        // 찌르기 — the loudest single buzz
        _D07Action(
          glyph: '⚡',
          label: '찌르기',
          accent: true,
          hint: '진동 한 번',
          onTap: () => HapticFeedback.heavyImpact(),
        ),
      ],
    );
  }
}

// live "partner is doodling now" signal — the soft double-tap voice
class _D07LiveStatus extends StatelessWidget {
  const _D07LiveStatus({required this.nick});
  final String nick;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // the soft double-tap haptic voice
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 90));
        HapticFeedback.lightImpact();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _d07ClayA(0.10),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _d07ClayA(0.35)),
        ),
        child: Row(
          children: [
            const _D07Cursor(color: _d07Clay, width: 6, height: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Text('지금 $nick 가 낙서 중',
                  style: _d07Sans(
                      size: 13, color: _d07Ink, weight: FontWeight.w500)),
            ),
            Text('두 번 두드림',
                style: _d07Mono(size: 9, color: _d07ClayA(0.85), spacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

// registration tick mark at canvas corners
class _D07Tick extends StatelessWidget {
  const _D07Tick();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(painter: _D07TickPainter()),
    );
  }
}

class _D07TickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _d07InkA(0.25)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), p);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _D07RulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _d07InkA(0.045)
      ..strokeWidth = 1;
    const gap = 30.0;
    for (double y = gap; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _D07IconTap extends StatelessWidget {
  const _D07IconTap({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: _d07InkA(0.75)),
      ),
    );
  }
}

class _D07SendButton extends StatelessWidget {
  const _D07SendButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _d07Ink,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('보내기',
                style: _d07Mono(
                    size: 11, color: _d07Paper, spacing: 2, weight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: _d07Clay, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class _D07ModeTab extends StatelessWidget {
  const _D07ModeTab({
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
                const _D07Cursor(width: 5, height: 12),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: _d07Sans(
                    size: 14,
                    color: selected ? _d07Ink : _d07InkA(0.4),
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                    spacing: 1,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 46,
            color: selected ? _d07Clay : _d07InkA(0.08),
          ),
        ],
      ),
    );
  }
}

// custom minimal thickness slider (no Material Slider chrome)
class _D07Thickness extends StatelessWidget {
  const _D07Thickness({
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
            height: 34,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // baseline (explicit width so it doesn't collapse in a Stack)
                Container(width: w, height: 1, color: _d07InkA(0.14)),
                // filled portion
                Container(width: t * w, height: 2, color: _d07ClayA(0.7)),
                // thumb — a small cursor block
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 4,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _d07Ink,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // live dot preview of chosen ink, right edge
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: value.clamp(3, 20),
                    height: value.clamp(3, 20),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
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

class _D07Action extends StatelessWidget {
  const _D07Action({
    required this.glyph,
    required this.label,
    required this.onTap,
    this.accent = false,
    this.hint,
  });
  final String glyph;
  final String label;
  final VoidCallback onTap;
  final bool accent;
  final String? hint;
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
              color: accent ? _d07ClayA(0.14) : _d07PaperDim,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                  color: accent ? _d07ClayA(0.45) : _d07InkA(0.10)),
            ),
            child: Text(glyph, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: _d07Mono(
                  size: 10,
                  color: accent ? _d07Clay : _d07InkA(0.7),
                  spacing: 1.5)),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint!,
                style: _d07Mono(size: 8, color: _d07ClayA(0.75), spacing: 0.5)),
          ],
        ],
      ),
    );
  }
}

// ==================================================================== Pet Home
class _D07PetHome extends StatefulWidget {
  const _D07PetHome({required this.data});
  final AppData data;
  @override
  State<_D07PetHome> createState() => _D07PetHomeState();
}

class _D07PetHomeState extends State<_D07PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    return Scaffold(
      backgroundColor: _d07Paper,
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
                      _D07Eyebrow('· 우리 펫'),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(pet.name,
                              style: _d07Sans(
                                  size: 20, weight: FontWeight.w600, spacing: 1)),
                          const SizedBox(width: 8),
                          Text('LV.${pet.level}',
                              style: _d07Mono(
                                  size: 11, color: _d07Clay, spacing: 1.5)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  _D07Coins(coins: pet.coins),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ---- the one strong subject: the pet
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // speech, revealed on pat, quiet paper slip with a cursor
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: patted
                          ? _D07SpeechSlip(text: pet.speech)
                          : const SizedBox(height: 52, key: ValueKey('empty')),
                    ),
                    const SizedBox(height: 8),
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
                          color: const Color(0xFFFBF8F1),
                          shape: BoxShape.circle,
                          border: Border.all(color: _d07InkA(0.12)),
                        ),
                        child: Text(pet.moodEmoji,
                            style: const TextStyle(fontSize: 78)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // equipped items — a sense of what it's wearing
                    if (equipped.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('착용',
                              style: _d07Mono(
                                  size: 9, color: _d07InkA(0.5), spacing: 2)),
                          const SizedBox(width: 10),
                          for (final e in equipped) ...[
                            Text(e.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('쓰다듬어 신호를 보내기',
                            style: _d07Sans(
                                size: 12, color: _d07InkA(0.45), spacing: 0.5)),
                        const SizedBox(width: 6),
                        const _D07Cursor(width: 5, height: 12),
                      ],
                    ),
                    const SizedBox(height: 26),
                    // growth gauge
                    _D07Growth(growth: pet.growth),
                  ],
                ),
              ),
            ),
            // ---- store row
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
              child: Row(
                children: [
                  _D07Eyebrow('· 스토어'),
                  const Spacer(),
                  Text('전체보기',
                      style: _d07Mono(
                          size: 9, color: _d07InkA(0.45), spacing: 1.5)),
                ],
              ),
            ),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                itemCount: pet.store.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _D07StoreCard(
                  item: pet.store[i],
                  onTap: () => HapticFeedback.selectionClick(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _D07Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

class _D07Coins extends StatelessWidget {
  const _D07Coins({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _d07PaperDim,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _d07InkA(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text('$coins',
              style: _d07Mono(size: 12, weight: FontWeight.w600, spacing: 1)),
        ],
      ),
    );
  }
}

class _D07SpeechSlip extends StatelessWidget {
  const _D07SpeechSlip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('speech'),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _d07ClayA(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _D07Cursor(width: 5, height: 13),
          const SizedBox(width: 10),
          Flexible(
            child: Text(text,
                textAlign: TextAlign.center,
                style: _d07Sans(size: 13, weight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _D07Growth extends StatelessWidget {
  const _D07Growth({required this.growth});
  final double growth;
  @override
  Widget build(BuildContext context) {
    final pct = (growth * 100).round();
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          Row(
            children: [
              Text('다음 레벨',
                  style: _d07Mono(
                      size: 9, color: _d07InkA(0.5), spacing: 1.5)),
              const Spacer(),
              Text('$pct%',
                  style: _d07Mono(size: 10, color: _d07Clay, spacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    Container(width: w, height: 3, color: _d07InkA(0.10)),
                    Container(
                      width: w * growth.clamp(0.0, 1.0),
                      height: 3,
                      color: _d07Clay,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _D07StoreCard extends StatelessWidget {
  const _D07StoreCard({required this.item, required this.onTap});
  final PetItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: item.equipped ? _d07ClayA(0.12) : const Color(0xFFFBF8F1),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: item.equipped ? _d07ClayA(0.5) : _d07InkA(0.10),
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
                style: _d07Sans(size: 11, spacing: 0.2)),
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
          const _D07Cursor(width: 4, height: 9),
          const SizedBox(width: 5),
          Text('착용중',
              style: _d07Mono(size: 9, color: _d07Clay, spacing: 1)),
        ],
      );
    }
    if (it.owned) {
      return Text('보유',
          style: _d07Mono(size: 9, color: _d07InkA(0.45), spacing: 1.5));
    }
    return Text('🪙 ${it.price}',
        style: _d07Mono(size: 9, color: _d07InkA(0.6), spacing: 0.5));
  }
}

// ================================================================ Memory Album
class _D07Album extends StatefulWidget {
  const _D07Album({required this.data});
  final AppData data;
  @override
  State<_D07Album> createState() => _D07AlbumState();
}

class _D07AlbumState extends State<_D07Album> {
  bool byDate = true;
  DoodleType? filter;

  @override
  Widget build(BuildContext context) {
    final all = widget.data.album;
    final items =
        all.where((d) => filter == null || d.type == filter).toList();
    return Scaffold(
      backgroundColor: _d07Paper,
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
                      _D07Eyebrow('· 기록'),
                      const SizedBox(height: 4),
                      Text('낙서 사진첩',
                          style: _d07Sans(
                              size: 20, weight: FontWeight.w600, spacing: 1)),
                    ],
                  ),
                  const Spacer(),
                  _D07SortToggle(
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
            // ---- one strong memory: cross-fading feature
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _D07Featured(items: all),
            ),
            const SizedBox(height: 18),
            // ---- type filters
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                children: [
                  _D07FilterChip(
                    label: '전체',
                    selected: filter == null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => filter = null);
                    },
                  ),
                  for (final t in DoodleType.values)
                    _D07FilterChip(
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
            const SizedBox(height: 6),
            // ---- the log: each memory a quiet signal line
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: _D07Hair(),
                    ),
                itemBuilder: (_, i) => _D07MemoryRow(doodle: items[i]),
              ),
            ),
            const _D07Nav(current: 1),
          ],
        ),
      ),
    );
  }
}

class _D07SortToggle extends StatelessWidget {
  const _D07SortToggle({required this.byDate, required this.onTap});
  final bool byDate;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? _d07Ink : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(label,
              style: _d07Mono(
                size: 9,
                color: on ? _d07Paper : _d07InkA(0.45),
                spacing: 1.2,
              )),
        );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: _d07InkA(0.12)),
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

class _D07FilterChip extends StatelessWidget {
  const _D07FilterChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _d07ClayA(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: selected ? _d07ClayA(0.5) : _d07InkA(0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const _D07Cursor(width: 4, height: 10),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: _d07Mono(
                    size: 10,
                    color: selected ? _d07Ink : _d07InkA(0.55),
                    weight: selected ? FontWeight.w600 : FontWeight.w500,
                    spacing: 1.2,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// the featured, cross-fading memory — memories cross-fade one at a time
class _D07Featured extends StatefulWidget {
  const _D07Featured({required this.items});
  final List<Doodle> items;
  @override
  State<_D07Featured> createState() => _D07FeaturedState();
}

class _D07FeaturedState extends State<_D07Featured> {
  int i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
        if (!mounted) return;
        setState(() => i = (i + 1) % widget.items.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final d = widget.items[i];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _card(d, key: ValueKey(d.id)),
    );
  }

  Widget _card(Doodle d, {required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _d07InkA(0.12)),
      ),
      child: Row(
        children: [
          // swatch gradient stand-in for the memory
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: d.swatch,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(d.emoji, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _D07Cursor(width: 5, height: 11),
                    const SizedBox(width: 8),
                    Text('지금 떠오르는 기억',
                        style: _d07Mono(
                            size: 9, color: _d07ClayA(0.9), spacing: 1.8)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d07Sans(
                        size: 16, weight: FontWeight.w600, spacing: 0.3)),
                const SizedBox(height: 4),
                Text('${d.author} · ${d.at.month}/${d.at.day}',
                    style: _d07Mono(
                        size: 10, color: _d07InkA(0.5), spacing: 1)),
              ],
            ),
          ),
          if (d.liked)
            Text('♥',
                style: TextStyle(fontSize: 16, color: _d07ClayA(0.9))),
        ],
      ),
    );
  }
}

// a single memory line — a received signal in the log
class _D07MemoryRow extends StatelessWidget {
  const _D07MemoryRow({required this.doodle});
  final Doodle doodle;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // swatch gradient + emoji
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                colors: d.swatch,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _d07InkA(0.06)),
            ),
            child: Text(d.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d07Sans(
                        size: 15, weight: FontWeight.w500, spacing: 0.2)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(d.type.label,
                        style: _d07Mono(
                            size: 9, color: _d07ClayA(0.85), spacing: 1)),
                    const SizedBox(width: 8),
                    Text('·',
                        style: _d07Mono(size: 9, color: _d07InkA(0.3))),
                    const SizedBox(width: 8),
                    Text('${d.author} · ${d.at.month}/${d.at.day}',
                        style: _d07Mono(
                            size: 9, color: _d07InkA(0.5), spacing: 1)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // liked heart — quiet, clay
          SizedBox(
            width: 18,
            child: d.liked
                ? Text('♥',
                    style: TextStyle(fontSize: 15, color: _d07ClayA(0.9)))
                : Text('♡',
                    style: TextStyle(
                        fontSize: 15, color: _d07InkA(0.22))),
          ),
        ],
      ),
    );
  }
}

// ==================================================================== bottom nav
class _D07Nav extends StatelessWidget {
  const _D07Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      decoration: const BoxDecoration(
        color: _d07Paper,
        border: Border(top: BorderSide(color: Color(0x1A2B2A26))),
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
            height: 12,
            child: active
                ? const _D07Cursor(width: 14, height: 3)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: _d07Mono(
                size: 11,
                color: active ? _d07Ink : _d07InkA(0.4),
                weight: active ? FontWeight.w700 : FontWeight.w400,
                spacing: 1.5,
              )),
        ],
      ),
    );
  }
}
