// design_12_foolscap — "Foolscap".
//
// The album read like a printed book: one entry per spread, wide literary
// margins, generous leading. The warmest ground of the calm family, with the
// warmth carried entirely by an old-style serif voice — not by decoration.
//
// The one quiet signature: a large old-style drop-cap opens each screen's
// single entry, and it "sets" a half-beat late — the initial fading in and
// settling like ink absorbing into the page. That delayed initial is the
// whole animation vocabulary; everything else is still.
//
// Self-contained: Material/widgets only, no external packages, no assets, no
// network, no Random, no DateTime.now(). Imagery is muted gradient + emoji
// from the shared demo data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ------------------------------------------------------------------ palette
const Color _d12Cream = Color(0xFFF7F2E7); // ground
const Color _d12Dim = Color(0xFFEFE8D8); // recessed paper
const Color _d12Leaf = Color(0xFFFBF7EE); // a fresh leaf / page
const Color _d12Ink = Color(0xFF2A2621); // sepia-black
const Color _d12Rose = Color(0xFFC0958C); // faded rose — the lone accent

Color _d12InkA(double a) => _d12Ink.withOpacity(a);
Color _d12RoseA(double a) => _d12Rose.withOpacity(a);

// Fade a demo colour toward the cream so ink and swatches read as printed,
// slightly-faded plate colour rather than screen-bright pigment.
Color _d12Faded(Color c, [double amount = 0.30]) =>
    Color.alphaBlend(_d12Cream.withOpacity(amount), c);

List<Color> _d12FadedList(List<Color> cs, [double amount = 0.34]) =>
    [for (final c in cs) _d12Faded(c, amount)];

// The literary serif voice for display + body.
TextStyle _d12Serif({
  double size = 15,
  Color color = _d12Ink,
  FontWeight weight = FontWeight.w400,
  double height = 1.52,
  double spacing = 0.2,
  FontStyle style = FontStyle.normal,
}) =>
    TextStyle(
      fontFamily: 'serif',
      fontFamilyFallback: const ['Georgia', 'Times New Roman', 'Songti SC'],
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      fontStyle: style,
    );

// Small-caps-flavoured meta labels — spaced serif, quiet.
TextStyle _d12Meta({
  double size = 10,
  Color? color,
  FontWeight weight = FontWeight.w500,
  double spacing = 2.4,
}) =>
    TextStyle(
      fontFamily: 'serif',
      fontFamilyFallback: const ['Georgia', 'Times New Roman'],
      fontSize: size,
      color: color ?? _d12InkA(0.5),
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.3,
    );

class Design12 extends DesignVariant {
  @override
  String get id => '12';
  @override
  String get name => 'Foolscap';
  @override
  String get concept =>
      '앨범을 인쇄된 책처럼 — 한 화면에 하나의 글, 넓은 문학적 여백과 넉넉한 행간. 가족 중 가장 따뜻한 바탕, 그 온기는 장식이 아니라 활자가 짊어진다.';
  @override
  String get signature =>
      '각 화면의 단 하나의 글을 여는 커다란 올드스타일 두문자 — 반 박자 늦게 "앉는다". 잉크가 종이에 스미듯 그 한 글자만 뒤늦게 배어 나온다. 그 지연된 첫 글자가 이 디자인의 유일한 움직임이다.';
  @override
  String get inspiration =>
      'Foolscap ruled writing paper · letterpress dropped initials · old-style book typography · wide literary margins';
  @override
  Color get accent => _d12Rose;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d12Serif(),
      child: switch (screen) {
        HeroScreen.drawSend => _D12DrawSend(data: data),
        HeroScreen.petHome => _D12PetHome(data: data),
        HeroScreen.memoryAlbum => _D12Album(data: data),
      },
    );
  }
}

// ====================================================== the lone signature
// A large old-style dropped initial that sets a half-beat late — fading in
// and settling (a touch of scale + drift) like ink absorbing into the page.
class _D12DropCap extends StatefulWidget {
  const _D12DropCap(this.letter, {this.size = 56, this.color = _d12Ink});
  final String letter;
  final double size;
  final Color color;
  @override
  State<_D12DropCap> createState() => _D12DropCapState();
}

class _D12DropCapState extends State<_D12DropCap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The half-beat: nothing until ~0.30, then the letter breathes in.
    final fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOut),
    );
    final settle = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.30, 1.0, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = settle.value;
        final scale = 1.05 - 0.05 * t; // over-set, then settle
        final dy = -4.0 * (1 - t); // drift down into the baseline
        return Opacity(
          opacity: fade.value,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.bottomLeft,
              child: Text(
                widget.letter,
                style: _d12Serif(
                  size: widget.size,
                  color: widget.color,
                  weight: FontWeight.w600,
                  height: 0.92,
                  spacing: 0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// A drop-cap opening: the dropped initial beside the first lines of the entry.
class _D12Opening extends StatelessWidget {
  const _D12Opening({
    required this.cap,
    required this.lines,
    this.capSize = 54,
  });
  final String cap;
  final String lines;
  final double capSize;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 14),
          child: _D12DropCap(cap, size: capSize),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              lines,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: _d12Serif(size: 15.5, color: _d12InkA(0.82), height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// A running head: section (serif) on the left, a folio numeral on the right,
// closed by a chapter rule. The book's quiet page furniture.
class _D12RunningHead extends StatelessWidget {
  const _D12RunningHead({required this.section, required this.folio});
  final String section;
  final String folio;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(section,
                style: _d12Serif(
                    size: 11.5, color: _d12InkA(0.55), spacing: 1.1)),
            const Spacer(),
            Text('FOL. $folio', style: _d12Meta(size: 9.5, spacing: 2.2)),
          ],
        ),
        const SizedBox(height: 8),
        const _D12Rule(),
      ],
    );
  }
}

// A single hairline — the page's ruling.
class _D12Rule extends StatelessWidget {
  const _D12Rule({this.opacity = 0.14, this.color = _d12Ink});
  final double opacity;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: color.withOpacity(opacity));
  }
}

class _D12Tap extends StatelessWidget {
  const _D12Tap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

// ================================================================= Draw & Send
class _D12DrawSend extends StatefulWidget {
  const _D12DrawSend({required this.data});
  final AppData data;
  @override
  State<_D12DrawSend> createState() => _D12DrawSendState();
}

class _D12DrawSendState extends State<_D12DrawSend> {
  int pen = 0; // start on the sepia-black ink
  double thickness = 5;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final nick = widget.data.couple.partnerNickname;
    return Scaffold(
      backgroundColor: _d12Cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 20, 34, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- top: back / recipient / send
              Row(
                children: [
                  _D12Tap(
                    onTap: () {},
                    child: Text('←',
                        style:
                            _d12Serif(size: 22, color: _d12InkA(0.7))),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text('받 는 이', style: _d12Meta(size: 9, spacing: 3)),
                      const SizedBox(height: 3),
                      Text(nick,
                          style: _d12Serif(
                              size: 18, weight: FontWeight.w600, spacing: 0.4)),
                    ],
                  ),
                  const Spacer(),
                  _D12SendButton(onTap: () {}),
                ],
              ),
              const SizedBox(height: 16),
              _D12RunningHead(section: '편지 · 오늘의 한 장', folio: '01'),
              const SizedBox(height: 16),
              // ---- the single entry, opened by the delayed initial
              _D12Opening(
                cap: '오',
                lines: '늘 하루를 한 장에 담아\n$nick에게 부치는 낙서.',
              ),
              const SizedBox(height: 16),
              // ---- the foolscap sheet: ruled paper with a rose margin line
              Expanded(child: _canvas()),
              const SizedBox(height: 18),
              // ---- pen inks
              Text('잉 크', style: _d12Meta(size: 9.5, spacing: 3)),
              const SizedBox(height: 12),
              _penRow(),
              const SizedBox(height: 18),
              // ---- thickness
              Row(
                children: [
                  Text('획 의 굵 기', style: _d12Meta(size: 9.5, spacing: 3)),
                  const Spacer(),
                  Text('${thickness.round()}',
                      style: _d12Serif(
                          size: 13, color: _d12Rose, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              _D12Thickness(
                value: thickness,
                color: _d12Faded(demoPenColors[pen], 0.22),
                onChanged: (v) => setState(() => thickness = v),
              ),
              const SizedBox(height: 18),
              const _D12Rule(),
              const SizedBox(height: 14),
              // ---- mode toggle + description
              _modeToggle(),
              const SizedBox(height: 8),
              Text(mode.description,
                  style: _d12Serif(
                      size: 12.5,
                      color: _d12InkA(0.55),
                      style: FontStyle.italic,
                      height: 1.4)),
              const SizedBox(height: 16),
              // ---- quiet actions
              _bottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvas() {
    final ink = _d12Faded(demoPenColors[pen], 0.22);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _d12Leaf,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d12InkA(0.16)),
      ),
      child: Stack(
        children: [
          // the foolscap ruling: faint horizontal rules + a rose margin line
          const Positioned.fill(child: CustomPaint(painter: _D12FoolscapPainter())),
          // the writing area, right of the margin line
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 22, 0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이 장에 오늘을 적어 보세요.',
                      style: _d12Serif(
                          size: 15,
                          color: _d12InkA(0.34),
                          style: FontStyle.italic)),
                  const SizedBox(height: 20),
                  // a single settled stroke — preview of the chosen ink & weight
                  Container(
                    width: 132,
                    height: thickness.clamp(2, 20),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(40),
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

  Widget _penRow() {
    return Row(
      children: [
        for (int i = 0; i < demoPenColors.length; i++) ...[
          _D12Tap(
            onTap: () => setState(() => pen = i),
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _d12Faded(demoPenColors[i], 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(color: _d12InkA(0.2)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 2,
                  width: 20,
                  child: pen == i
                      ? const ColoredBox(color: _d12Rose)
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
          _D12Tap(
            onTap: () => setState(() => mode = m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.label,
                    style: _d12Serif(
                      size: 15,
                      color: mode == m ? _d12Ink : _d12InkA(0.4),
                      weight: mode == m ? FontWeight.w600 : FontWeight.w400,
                      spacing: 0.6,
                    )),
                const SizedBox(height: 6),
                Container(
                  height: 2,
                  width: 52,
                  color: mode == m ? _d12Rose : _d12InkA(0.08),
                ),
              ],
            ),
          ),
          if (m != SendMode.values.last) const SizedBox(width: 18),
        ],
      ],
    );
  }

  Widget _bottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _D12Action(glyph: '🖼', label: '갤러리', onTap: () {}),
        _D12Action(glyph: '📷', label: '사진', onTap: () {}),
        _D12Action(glyph: '✦', label: '찌르기', accent: true, onTap: () {}),
      ],
    );
  }
}

class _D12SendButton extends StatelessWidget {
  const _D12SendButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return _D12Tap(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('보내기',
              style: _d12Serif(
                  size: 16, weight: FontWeight.w600, color: _d12Ink)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 20, height: 2, color: _d12RoseA(0.9)),
              const SizedBox(width: 5),
              Container(
                width: 5,
                height: 5,
                decoration:
                    const BoxDecoration(color: _d12Rose, shape: BoxShape.circle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// custom minimal thickness rule (no Material Slider chrome)
class _D12Thickness extends StatelessWidget {
  const _D12Thickness({
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
          HapticFeedback.selectionClick();
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
                Container(width: w, height: 1, color: _d12InkA(0.16)),
                Container(width: t * w, height: 1.5, color: _d12RoseA(0.75)),
                // the nib — a small ink lozenge
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _d12Ink,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // a settled dot preview at the right margin
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: value.clamp(3, 20),
                    height: value.clamp(3, 20),
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
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

class _D12Action extends StatelessWidget {
  const _D12Action({
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
    return _D12Tap(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ? _d12RoseA(0.10) : _d12Dim,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                  color: accent ? _d12RoseA(0.5) : _d12InkA(0.12)),
            ),
            child: Text(glyph,
                style: TextStyle(
                    fontSize: accent ? 20 : 22,
                    color: accent ? _d12Rose : null)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: _d12Serif(
                  size: 12,
                  color: accent ? _d12Rose : _d12InkA(0.68),
                  spacing: 0.5)),
        ],
      ),
    );
  }
}

class _D12FoolscapPainter extends CustomPainter {
  const _D12FoolscapPainter();
  @override
  void paint(Canvas canvas, Size size) {
    // faint horizontal ruling
    final rule = Paint()
      ..color = _d12InkA(0.05)
      ..strokeWidth = 1;
    const gap = 34.0;
    for (double y = gap; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }
    // the single rose margin line — the mark of foolscap paper
    final margin = Paint()
      ..color = _d12RoseA(0.35)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(30, 10), Offset(30, size.height - 10), margin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==================================================================== Pet Home
class _D12PetHome extends StatefulWidget {
  const _D12PetHome({required this.data});
  final AppData data;
  @override
  State<_D12PetHome> createState() => _D12PetHomeState();
}

class _D12PetHomeState extends State<_D12PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    return Scaffold(
      backgroundColor: _d12Cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 20, 34, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- top: name + Lv / coins
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('우 리 펫', style: _d12Meta(size: 9, spacing: 3)),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(pet.name,
                                  style: _d12Serif(
                                      size: 21, weight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Text('Lv.${pet.level}',
                                  style: _d12Serif(
                                      size: 13,
                                      color: _d12Rose,
                                      weight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      _D12Coins(coins: pet.coins),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _D12RunningHead(section: '우리 펫 · 몽이의 뜰', folio: '02'),
                  const SizedBox(height: 16),
                  _D12Opening(
                    cap: '우',
                    lines: '리 둘이 함께 기른 ${pet.name},\n오늘도 편지를 기다립니다.',
                  ),
                ],
              ),
            ),
            // ---- the pet, the single subject of the page
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // speech, revealed on pat — a margin note in the book
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: patted
                          ? _D12SpeechNote(text: pet.speech)
                          : const SizedBox(height: 46, key: ValueKey('empty')),
                    ),
                    const SizedBox(height: 10),
                    _D12Tap(
                      onTap: () => setState(() => patted = !patted),
                      child: Container(
                        width: 150,
                        height: 150,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _d12Leaf,
                          shape: BoxShape.circle,
                          border: Border.all(color: _d12InkA(0.14)),
                        ),
                        child: Text(pet.moodEmoji,
                            style: const TextStyle(fontSize: 68)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (equipped.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('착 용', style: _d12Meta(size: 8.5, spacing: 2.4)),
                          const SizedBox(width: 10),
                          for (final e in equipped) ...[
                            Text(e.emoji, style: const TextStyle(fontSize: 17)),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text('쓰다듬어 오늘의 한 마디를 듣기',
                        style: _d12Serif(
                            size: 12.5,
                            color: _d12InkA(0.45),
                            style: FontStyle.italic)),
                    const SizedBox(height: 22),
                    _D12Growth(growth: pet.growth),
                  ],
                ),
              ),
            ),
            // ---- the store, a quiet catalogue slip
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 0, 34, 8),
              child: Row(
                children: [
                  Text('스 토 어', style: _d12Meta(size: 9.5, spacing: 3)),
                  const Spacer(),
                  Text('전체보기',
                      style: _d12Serif(
                          size: 12,
                          color: _d12InkA(0.45),
                          style: FontStyle.italic)),
                ],
              ),
            ),
            SizedBox(
              height: 122,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 34),
                itemCount: pet.store.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    _D12StoreCard(item: pet.store[i], onTap: () {}),
              ),
            ),
            const SizedBox(height: 10),
            const _D12Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

class _D12Coins extends StatelessWidget {
  const _D12Coins({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _d12Dim,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d12InkA(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Text('$coins',
              style: _d12Serif(size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _D12SpeechNote extends StatelessWidget {
  const _D12SpeechNote({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('speech'),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _d12Leaf,
        borderRadius: BorderRadius.circular(2),
        border: Border(left: BorderSide(color: _d12RoseA(0.7), width: 2)),
      ),
      child: Text('“$text”',
          textAlign: TextAlign.center,
          style: _d12Serif(
              size: 13.5, weight: FontWeight.w500, style: FontStyle.italic)),
    );
  }
}

class _D12Growth extends StatelessWidget {
  const _D12Growth({required this.growth});
  final double growth;
  @override
  Widget build(BuildContext context) {
    final pct = (growth * 100).round();
    return SizedBox(
      width: 224,
      child: Column(
        children: [
          Row(
            children: [
              Text('다 음 장 까 지', style: _d12Meta(size: 8.5, spacing: 2)),
              const Spacer(),
              Text('$pct%',
                  style: _d12Serif(
                      size: 11.5, color: _d12Rose, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return Stack(
                children: [
                  Container(width: w, height: 2, color: _d12InkA(0.12)),
                  Container(
                    width: w * growth.clamp(0.0, 1.0),
                    height: 2,
                    color: _d12Rose,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _D12StoreCard extends StatelessWidget {
  const _D12StoreCard({required this.item, required this.onTap});
  final PetItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return _D12Tap(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: item.equipped ? _d12RoseA(0.09) : _d12Leaf,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: item.equipped ? _d12RoseA(0.5) : _d12InkA(0.12),
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
                style: _d12Serif(size: 12)),
            const SizedBox(height: 6),
            _statusLine(item),
          ],
        ),
      ),
    );
  }

  Widget _statusLine(PetItem it) {
    if (it.equipped) {
      return Text('착용중',
          style: _d12Serif(
              size: 10.5, color: _d12Rose, weight: FontWeight.w600));
    }
    if (it.owned) {
      return Text('보유',
          style: _d12Serif(size: 10.5, color: _d12InkA(0.45)));
    }
    return Text('🪙 ${it.price}',
        style: _d12Serif(size: 10.5, color: _d12InkA(0.6)));
  }
}

// ================================================================ Memory Album
class _D12Album extends StatefulWidget {
  const _D12Album({required this.data});
  final AppData data;
  @override
  State<_D12Album> createState() => _D12AlbumState();
}

class _D12AlbumState extends State<_D12Album> {
  bool byDate = true;
  DoodleType? filter;

  @override
  Widget build(BuildContext context) {
    final all = widget.data.album;
    final items =
        all.where((d) => filter == null || d.type == filter).toList();
    return Scaffold(
      backgroundColor: _d12Cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 20, 34, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- title + sort toggle
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('사 진 첩', style: _d12Meta(size: 9, spacing: 3)),
                          const SizedBox(height: 4),
                          Text('낙서 사진첩',
                              style: _d12Serif(
                                  size: 21, weight: FontWeight.w600)),
                        ],
                      ),
                      const Spacer(),
                      _D12SortToggle(
                        byDate: byDate,
                        onTap: () => setState(() => byDate = !byDate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _D12RunningHead(section: '지난 낙서 · 한 권의 책', folio: '03'),
                  const SizedBox(height: 16),
                  _D12Opening(
                    cap: '지',
                    lines: '난 낙서들이 모여\n한 권의 책이 되었습니다.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ---- type filters
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 34),
                children: [
                  _D12FilterWord(
                    label: '전체',
                    selected: filter == null,
                    onTap: () => setState(() => filter = null),
                  ),
                  for (final t in DoodleType.values)
                    _D12FilterWord(
                      label: t.label,
                      selected: filter == t,
                      onTap: () => setState(() => filter = t),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // ---- the index of entries, one leaf per memory
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(34, 10, 34, 18),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: _D12Rule(opacity: 0.10),
                ),
                itemBuilder: (_, i) => _D12EntryRow(doodle: items[i]),
              ),
            ),
            const _D12Nav(current: 1),
          ],
        ),
      ),
    );
  }
}

class _D12SortToggle extends StatelessWidget {
  const _D12SortToggle({required this.byDate, required this.onTap});
  final bool byDate;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: _d12Serif(
                  size: 12.5,
                  color: on ? _d12Ink : _d12InkA(0.4),
                  weight: on ? FontWeight.w600 : FontWeight.w400,
                )),
            const SizedBox(height: 4),
            Container(
                height: 2, width: 34, color: on ? _d12Rose : Colors.transparent),
          ],
        );
    return _D12Tap(
      onTap: onTap,
      child: Row(
        children: [
          seg('날짜별', byDate),
          const SizedBox(width: 12),
          seg('유형별', !byDate),
        ],
      ),
    );
  }
}

class _D12FilterWord extends StatelessWidget {
  const _D12FilterWord({
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
      padding: const EdgeInsets.only(right: 20),
      child: _D12Tap(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: _d12Serif(
                  size: 14,
                  color: selected ? _d12Ink : _d12InkA(0.42),
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                )),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 22,
              color: selected ? _d12Rose : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

// a single memory — an entry in the bound index
class _D12EntryRow extends StatelessWidget {
  const _D12EntryRow({required this.doodle});
  final Doodle doodle;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // a muted plate stand-in for the drawn / photographed content
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: _d12FadedList(d.swatch),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _d12InkA(0.1)),
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
                    style: _d12Serif(size: 16, weight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  '${d.type.label} · ${d.author} · ${d.at.month}월 ${d.at.day}일',
                  style: _d12Serif(
                      size: 11.5, color: _d12InkA(0.5), style: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 18,
            child: d.liked
                ? Text('♥', style: TextStyle(fontSize: 15, color: _d12RoseA(0.95)))
                : Text('♡', style: TextStyle(fontSize: 15, color: _d12InkA(0.22))),
          ),
        ],
      ),
    );
  }
}

// ==================================================================== bottom nav
class _D12Nav extends StatelessWidget {
  const _D12Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      decoration: BoxDecoration(
        color: _d12Cream,
        border: Border(top: BorderSide(color: _d12InkA(0.12))),
      ),
      padding: const EdgeInsets.fromLTRB(34, 12, 34, 8),
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
    return _D12Tap(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 2,
            child: active
                ? Container(width: 18, height: 2, color: _d12Rose)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: _d12Serif(
                size: 13,
                color: active ? _d12Ink : _d12InkA(0.4),
                weight: active ? FontWeight.w600 : FontWeight.w400,
                spacing: 0.5,
              )),
        ],
      ),
    );
  }
}
