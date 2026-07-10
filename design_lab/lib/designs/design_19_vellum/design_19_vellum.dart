// design_19_vellum — "Vellum".
//
// Sheets of tracing vellum over warm white. The album is a stack of soft
// translucent overlays; today's doodle shows faintly through yesterday's.
// Depth without a single shadow — a translucent panel (~85% opacity) is the
// lone motion cue as it slides over the ground. Only ever one layer visible
// at a time, its predecessor ghosting quietly beneath.
//
// Calm sibling of Quiet Signal: same restraint, different voice — a light
// high-waisted display serif, a greyed slate-lilac accent, and layered
// translucency in place of the pager cursor.
//
// Self-contained: no external packages, no assets, no network, no Random,
// no DateTime.now(). Imagery is muted gradient + emoji from shared demo data.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ------------------------------------------------------------------- palette
const Color _d19Ground = Color(0xFFF8F5EE); // warm white ground
const Color _d19Vellum = Color(0xFFFBF9F3); // translucent sheet
const Color _d19Ink = Color(0xFF2E2C27); // soft-black
const Color _d19Lilac = Color(0xFFA79FA6); // greyed slate-lilac accent

Color _d19InkA(double a) => _d19Ink.withOpacity(a);
Color _d19LilacA(double a) => _d19Lilac.withOpacity(a);

// mute a saturated demo swatch toward the vellum — soft pastels, never loud.
List<Color> _d19Soft(List<Color> colors) => colors
    .map((c) => Color.alphaBlend(_d19Vellum.withOpacity(0.58), c))
    .toList();

// light, high-waisted display serif — airy, almost translucent itself.
TextStyle _d19Serif({
  double size = 22,
  Color color = _d19Ink,
  FontWeight weight = FontWeight.w300,
  double spacing = 0.2,
  double height = 1.18,
}) =>
    TextStyle(
      fontFamily: 'serif',
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

// quiet sans caption — the whisper beside the serif.
TextStyle _d19Sans({
  double size = 13,
  Color color = _d19Ink,
  FontWeight weight = FontWeight.w400,
  double spacing = 0.3,
  double height = 1.4,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

class Design19 extends DesignVariant {
  @override
  String get id => '19';
  @override
  String get name => 'Vellum';
  @override
  String get concept =>
      '트레이싱 벨럼을 웜화이트 위에 겹친 앨범 — 어제의 낙서 위로 오늘의 낙서가 은은히 비친다. 그림자 하나 없이 오직 반투명의 겹으로 만드는 깊이.';
  @override
  String get signature =>
      '유일한 깊이·움직임 신호 — 약 85% 불투명한 벨럼 한 장이 바닥 위로 미끄러져 올라온다. 언제나 한 겹만 보이고, 앞선 기억은 그 아래로 조용히 비쳐 사라진다.';
  @override
  String get inspiration =>
      'Tracing vellum overlays · warm-white minimalism · depth by translucency, no shadow';
  @override
  Color get accent => _d19Lilac;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d19Sans(),
      child: switch (screen) {
        HeroScreen.drawSend => _D19DrawSend(data: data),
        HeroScreen.petHome => _D19PetHome(data: data),
        HeroScreen.memoryAlbum => _D19Album(data: data),
      },
    );
  }
}

// ======================================================== shared quiet parts

// The signature entrance: a single translucent panel slides up over the
// ground and settles — the one motion cue in the whole language.
class _D19Reveal extends StatefulWidget {
  const _D19Reveal({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;
  @override
  State<_D19Reveal> createState() => _D19RevealState();
}

class _D19RevealState extends State<_D19Reveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    );
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 16),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// A translucent vellum sheet — ~85% opaque so the warm ground shows through.
// Optional [ghost] draws a fainter sheet offset beneath: the prior memory,
// layered without a single shadow.
class _D19Sheet extends StatelessWidget {
  const _D19Sheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 6,
    this.ghost = false,
    this.opacity = 0.85,
    this.expand = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool ghost;
  final double opacity;
  final bool expand; // fill the parent (e.g. the canvas) vs hug content

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: double.infinity,
      height: expand ? double.infinity : null,
      padding: padding,
      decoration: BoxDecoration(
        color: _d19Vellum.withOpacity(opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _d19LilacA(0.28), width: 1),
      ),
      child: child,
    );
    if (!ghost) return panel;
    return Stack(
      fit: expand ? StackFit.expand : StackFit.loose,
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(7, 9),
            child: Container(
              decoration: BoxDecoration(
                color: _d19Vellum.withOpacity(0.45),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: _d19LilacA(0.14)),
              ),
            ),
          ),
        ),
        panel,
      ],
    );
  }
}

class _D19Hair extends StatelessWidget {
  const _D19Hair({this.opacity = 0.09});
  final double opacity;
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _d19InkA(opacity));
}

// tiny wide-tracked uppercase label — the quiet eyebrow.
class _D19Eyebrow extends StatelessWidget {
  const _D19Eyebrow(this.text, {this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: _d19Sans(
          size: 9.5,
          color: color ?? _d19LilacA(0.95),
          weight: FontWeight.w500,
          spacing: 2.4,
        ),
      );
}

class _D19Tap extends StatelessWidget {
  const _D19Tap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: child,
      );
}

// A muted swatch tile: soft gradient stand-in + emoji, layered under a faint
// vellum scrim so the content only whispers.
class _D19Swatch extends StatelessWidget {
  const _D19Swatch({required this.doodle, this.size = 46, this.emoji = 22});
  final Doodle doodle;
  final double size;
  final double emoji;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          colors: _d19Soft(doodle.swatch),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _d19InkA(0.05)),
      ),
      child: Text(doodle.emoji, style: TextStyle(fontSize: emoji)),
    );
  }
}

// =============================================================== Draw & Send
class _D19DrawSend extends StatefulWidget {
  const _D19DrawSend({required this.data});
  final AppData data;
  @override
  State<_D19DrawSend> createState() => _D19DrawSendState();
}

class _D19DrawSendState extends State<_D19DrawSend> {
  int pen = 0;
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    final ghostEmoji = widget.data.album.first.emoji; // yesterday, showing through
    return Scaffold(
      backgroundColor: _d19Ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- top: back / recipient / send
              Row(
                children: [
                  _D19Tap(
                    onTap: () {},
                    child: Icon(Icons.arrow_back,
                        size: 20, color: _d19InkA(0.7)),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      _D19Eyebrow('받는 사람'),
                      const SizedBox(height: 4),
                      Text(couple.partnerNickname,
                          style: _d19Serif(size: 20, spacing: 0.4)),
                    ],
                  ),
                  const Spacer(),
                  _D19SendButton(onTap: () {}),
                ],
              ),
              const SizedBox(height: 18),
              // ---- the canvas: the one translucent sheet, sliding over ground,
              //      yesterday's mark ghosting faintly through the vellum.
              Expanded(
                child: _D19Reveal(
                  child: _D19Sheet(
                    ghost: true,
                    expand: true,
                    padding: const EdgeInsets.all(22),
                    child: Stack(
                      children: [
                        // yesterday, showing faintly through the vellum
                        Positioned.fill(
                          child: Center(
                            child: Text(
                              ghostEmoji,
                              style: TextStyle(
                                  fontSize: 132,
                                  color: _d19InkA(0.045)),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _D19Eyebrow('오늘의 자국'),
                              const SizedBox(height: 14),
                              Text('어제 위에\n오늘을 겹쳐요',
                                  textAlign: TextAlign.center,
                                  style: _d19Serif(
                                      size: 21,
                                      color: _d19InkA(0.45),
                                      height: 1.4)),
                              const SizedBox(height: 22),
                              // current stroke preview — chosen ink & weight
                              Container(
                                width: 128,
                                height: thickness.clamp(2, 20),
                                decoration: BoxDecoration(
                                  color: demoPenColors[pen],
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // ---- pen colors
              _D19Eyebrow('잉크'),
              const SizedBox(height: 12),
              _penRow(),
              const SizedBox(height: 20),
              // ---- thickness
              Row(
                children: [
                  const _D19Eyebrow('굵기'),
                  const Spacer(),
                  Text('${thickness.round()}',
                      style: _d19Sans(
                          size: 11, color: _d19LilacA(0.95), spacing: 1)),
                ],
              ),
              const SizedBox(height: 8),
              _D19Thickness(
                value: thickness,
                color: demoPenColors[pen],
                onChanged: (v) => setState(() => thickness = v),
              ),
              const SizedBox(height: 18),
              const _D19Hair(),
              const SizedBox(height: 16),
              // ---- mode toggle + description
              _modeToggle(),
              const SizedBox(height: 8),
              Text(mode.description,
                  style:
                      _d19Sans(size: 12, color: _d19InkA(0.5), spacing: 0.2)),
              const SizedBox(height: 16),
              // ---- quiet actions
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _penRow() {
    return Row(
      children: [
        for (int i = 0; i < demoPenColors.length; i++) ...[
          _D19Tap(
            onTap: () => setState(() => pen = i),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: pen == i ? _d19LilacA(0.9) : Colors.transparent,
                  width: 1.4,
                ),
              ),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: demoPenColors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: _d19InkA(0.12)),
                ),
              ),
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
          _D19ModeTab(
            label: m.label,
            selected: mode == m,
            onTap: () => setState(() => mode = m),
          ),
          if (m != SendMode.values.last) const SizedBox(width: 22),
        ],
      ],
    );
  }

  Widget _actions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _D19Action(glyph: '🖼', label: '갤러리', onTap: () {}),
        _D19Action(glyph: '📷', label: '사진', onTap: () {}),
        _D19Action(glyph: '👆', label: '찌르기', accent: true, onTap: () {}),
      ],
    );
  }
}

class _D19SendButton extends StatelessWidget {
  const _D19SendButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return _D19Tap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _d19Ink,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('보내기',
            style: _d19Sans(
                size: 12,
                color: _d19Ground,
                weight: FontWeight.w500,
                spacing: 1.5)),
      ),
    );
  }
}

class _D19ModeTab extends StatelessWidget {
  const _D19ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return _D19Tap(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: _d19Serif(
                size: 17,
                color: selected ? _d19Ink : _d19InkA(0.38),
                weight: selected ? FontWeight.w400 : FontWeight.w300,
              )),
          const SizedBox(height: 6),
          Container(
            height: 1.5,
            width: 40,
            color: selected ? _d19LilacA(0.9) : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

// custom hairline thickness slider — no Material chrome, lilac fill.
class _D19Thickness extends StatelessWidget {
  const _D19Thickness({
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
                Container(width: w, height: 1, color: _d19InkA(0.14)),
                Container(width: t * w, height: 1.5, color: _d19LilacA(0.8)),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: value.clamp(6, 22),
                    height: value.clamp(6, 22),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: _d19Vellum, width: 2),
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

class _D19Action extends StatelessWidget {
  const _D19Action({
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
    return _D19Tap(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ? _d19LilacA(0.14) : _d19Vellum.withOpacity(0.85),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: accent ? _d19LilacA(0.5) : _d19InkA(0.09)),
            ),
            child: Text(glyph, style: const TextStyle(fontSize: 21)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: _d19Sans(
                size: 11,
                color: accent ? _d19LilacA(0.95) : _d19InkA(0.6),
                spacing: 0.6,
              )),
        ],
      ),
    );
  }
}

// ================================================================== Pet Home
class _D19PetHome extends StatefulWidget {
  const _D19PetHome({required this.data});
  final AppData data;
  @override
  State<_D19PetHome> createState() => _D19PetHomeState();
}

class _D19PetHomeState extends State<_D19PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    return Scaffold(
      backgroundColor: _d19Ground,
      body: SafeArea(
        child: Column(
          children: [
            // ---- top: name + Lv / coins
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _D19Eyebrow('우리 펫'),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(pet.name, style: _d19Serif(size: 24)),
                          const SizedBox(width: 10),
                          Text('Lv.${pet.level}',
                              style: _d19Sans(
                                  size: 12,
                                  color: _d19LilacA(0.95),
                                  spacing: 1)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  _D19Coins(coins: pet.coins),
                ],
              ),
            ),
            // ---- the pet: one translucent disc over the ground
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // speech revealed on pat — a vellum slip sliding in
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 340),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SizeTransition(
                          sizeFactor: anim,
                          axisAlignment: -1,
                          child: child,
                        ),
                      ),
                      child: patted
                          ? _D19SpeechSlip(text: pet.speech)
                          : const SizedBox(
                              height: 4, key: ValueKey('empty')),
                    ),
                    const SizedBox(height: 16),
                    _D19Tap(
                      onTap: () => setState(() => patted = !patted),
                      child: _D19Reveal(
                        child: Container(
                          width: 176,
                          height: 176,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _d19Vellum.withOpacity(0.85),
                            shape: BoxShape.circle,
                            border: Border.all(color: _d19LilacA(0.28)),
                          ),
                          child: Text(pet.moodEmoji,
                              style: const TextStyle(fontSize: 84)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // equipped — what it's wearing, whispered
                    if (equipped.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('착용',
                              style: _d19Sans(
                                  size: 9.5,
                                  color: _d19InkA(0.45),
                                  spacing: 2)),
                          const SizedBox(width: 10),
                          for (final e in equipped) ...[
                            Text(e.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text('쓰다듬어 말을 걸어보세요',
                        style: _d19Sans(size: 12, color: _d19InkA(0.42))),
                    const SizedBox(height: 26),
                    _D19Growth(growth: pet.growth),
                  ],
                ),
              ),
            ),
            // ---- store: restrained horizontal row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  const _D19Eyebrow('스토어'),
                  const Spacer(),
                  Text('전체보기',
                      style: _d19Sans(size: 10, color: _d19InkA(0.42))),
                ],
              ),
            ),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: pet.store.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _D19StoreCard(item: pet.store[i]),
              ),
            ),
            const SizedBox(height: 10),
            const _D19Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

class _D19Coins extends StatelessWidget {
  const _D19Coins({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _d19Vellum.withOpacity(0.85),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _d19InkA(0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Text('$coins',
              style: _d19Sans(
                  size: 12, weight: FontWeight.w500, spacing: 0.5)),
        ],
      ),
    );
  }
}

class _D19SpeechSlip extends StatelessWidget {
  const _D19SpeechSlip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('speech'),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: _d19Vellum.withOpacity(0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _d19LilacA(0.32)),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: _d19Serif(size: 15, weight: FontWeight.w400, height: 1.3)),
    );
  }
}

class _D19Growth extends StatelessWidget {
  const _D19Growth({required this.growth});
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
              Text('다음 레벨',
                  style: _d19Sans(
                      size: 9.5, color: _d19InkA(0.45), spacing: 1.5)),
              const Spacer(),
              Text('$pct%',
                  style: _d19Sans(
                      size: 10, color: _d19LilacA(0.95), spacing: 0.5)),
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
                    Container(width: w, height: 2, color: _d19InkA(0.1)),
                    Container(
                      width: w * growth.clamp(0.0, 1.0),
                      height: 2,
                      color: _d19LilacA(0.9),
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

class _D19StoreCard extends StatelessWidget {
  const _D19StoreCard({required this.item});
  final PetItem item;
  @override
  Widget build(BuildContext context) {
    return _D19Tap(
      onTap: () {},
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: _d19Vellum.withOpacity(item.equipped ? 0.85 : 0.6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: item.equipped ? _d19LilacA(0.5) : _d19InkA(0.08),
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
                style: _d19Sans(size: 11)),
            const SizedBox(height: 6),
            _status(item),
          ],
        ),
      ),
    );
  }

  Widget _status(PetItem it) {
    if (it.equipped) {
      return Text('착용중',
          style: _d19Sans(
              size: 9.5, color: _d19LilacA(0.95), spacing: 0.5));
    }
    if (it.owned) {
      return Text('보유',
          style: _d19Sans(size: 9.5, color: _d19InkA(0.42), spacing: 0.5));
    }
    return Text('🪙 ${it.price}',
        style: _d19Sans(size: 9.5, color: _d19InkA(0.55)));
  }
}

// =============================================================== Memory Album
class _D19Album extends StatefulWidget {
  const _D19Album({required this.data});
  final AppData data;
  @override
  State<_D19Album> createState() => _D19AlbumState();
}

class _D19AlbumState extends State<_D19Album> {
  bool byDate = true;
  DoodleType? filter;

  @override
  Widget build(BuildContext context) {
    final all = widget.data.album;
    final items =
        all.where((d) => filter == null || d.type == filter).toList();
    return Scaffold(
      backgroundColor: _d19Ground,
      body: SafeArea(
        child: Column(
          children: [
            // ---- header: title + sort toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _D19Eyebrow('기록'),
                      const SizedBox(height: 5),
                      Text('낙서 사진첩', style: _d19Serif(size: 24)),
                    ],
                  ),
                  const Spacer(),
                  _D19SortToggle(
                    byDate: byDate,
                    onTap: () => setState(() => byDate = !byDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ---- featured: sheets cross-slide, one visible, prior ghosting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _D19Featured(items: all),
            ),
            const SizedBox(height: 18),
            // ---- type filters
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _D19FilterChip(
                    label: '전체',
                    selected: filter == null,
                    onTap: () => setState(() => filter = null),
                  ),
                  for (final t in DoodleType.values)
                    _D19FilterChip(
                      label: t.label,
                      selected: filter == t,
                      onTap: () => setState(() => filter = t),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // ---- the calm list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: _D19Hair(),
                ),
                itemBuilder: (_, i) => _D19MemoryRow(doodle: items[i]),
              ),
            ),
            const _D19Nav(current: 1),
          ],
        ),
      ),
    );
  }
}

class _D19SortToggle extends StatelessWidget {
  const _D19SortToggle({required this.byDate, required this.onTap});
  final bool byDate;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: on ? _d19Ink : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(label,
              style: _d19Sans(
                size: 10,
                color: on ? _d19Ground : _d19InkA(0.45),
                spacing: 0.8,
              )),
        );
    return _D19Tap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: _d19InkA(0.12)),
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

class _D19FilterChip extends StatelessWidget {
  const _D19FilterChip({
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
      child: _D19Tap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? _d19LilacA(0.14)
                : _d19Vellum.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected ? _d19LilacA(0.5) : _d19InkA(0.1),
            ),
          ),
          child: Text(label,
              style: _d19Sans(
                size: 11,
                color: selected ? _d19Ink : _d19InkA(0.55),
                weight: selected ? FontWeight.w500 : FontWeight.w400,
                spacing: 0.6,
              )),
        ),
      ),
    );
  }
}

// featured memory — sheets slide over one another, one layer at a time,
// the prior memory ghosting faintly beneath. The album's one motion cue.
class _D19Featured extends StatefulWidget {
  const _D19Featured({required this.items});
  final List<Doodle> items;
  @override
  State<_D19Featured> createState() => _D19FeaturedState();
}

class _D19FeaturedState extends State<_D19Featured> {
  int i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
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
      duration: const Duration(milliseconds: 720),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim);
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(position: slide, child: child),
        );
      },
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      child: _card(d, key: ValueKey(d.id)),
    );
  }

  Widget _card(Doodle d, {required Key key}) {
    return _D19Sheet(
      key: key,
      ghost: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _D19Swatch(doodle: d, size: 62, emoji: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _D19Eyebrow('지금 떠오르는 기억'),
                const SizedBox(height: 8),
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d19Serif(size: 18)),
                const SizedBox(height: 5),
                Text('${d.author} · ${d.at.month}/${d.at.day}',
                    style: _d19Sans(size: 10.5, color: _d19InkA(0.5))),
              ],
            ),
          ),
          Text(d.liked ? '♥' : '♡',
              style: TextStyle(
                  fontSize: 15,
                  color: d.liked ? _d19LilacA(0.95) : _d19InkA(0.2))),
        ],
      ),
    );
  }
}

class _D19MemoryRow extends StatelessWidget {
  const _D19MemoryRow({required this.doodle});
  final Doodle doodle;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          _D19Swatch(doodle: d, size: 48, emoji: 23),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d19Serif(size: 16, weight: FontWeight.w400)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(d.type.label,
                        style: _d19Sans(
                            size: 9.5,
                            color: _d19LilacA(0.95),
                            spacing: 0.5)),
                    const SizedBox(width: 8),
                    Text('·', style: _d19Sans(size: 9.5, color: _d19InkA(0.3))),
                    const SizedBox(width: 8),
                    Text('${d.author} · ${d.at.month}/${d.at.day}',
                        style: _d19Sans(size: 9.5, color: _d19InkA(0.48))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(d.liked ? '♥' : '♡',
              style: TextStyle(
                  fontSize: 15,
                  color: d.liked ? _d19LilacA(0.95) : _d19InkA(0.2))),
        ],
      ),
    );
  }
}

// ==================================================================== nav
class _D19Nav extends StatelessWidget {
  const _D19Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x162E2C27))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
    return _D19Tap(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: active ? _d19LilacA(0.95) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 7),
          Text(label,
              style: _d19Sans(
                size: 11,
                color: active ? _d19Ink : _d19InkA(0.4),
                weight: active ? FontWeight.w500 : FontWeight.w400,
                spacing: 0.8,
              )),
        ],
      ),
    );
  }
}
