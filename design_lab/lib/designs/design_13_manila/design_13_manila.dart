// design_13_manila — "Manila".
//
// An oat manila folder holding the pair's memories. Content sits on dry
// index-card panels; the shared pet lives on a tabbed card. Warm-neutral,
// papery, undecorated MUJI stationery.
//
// The ONE quiet signature: a single rounded index tab (folder tab) marks the
// active section — ink outline only, never a color fill. The tab is the sole
// piece of chrome.
//
// Self-contained: no external packages, no assets, no network, no Random,
// no DateTime.now(). Imagery is muted gradient + emoji from shared demo data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ---------------------------------------------------------------- palette
const Color _d13Manila = Color(0xFFEDE6D6); // ground
const Color _d13Dim = Color(0xFFE4DBC8); // recessed / tracks
const Color _d13Ink = Color(0xFF33302A); // bister ink
const Color _d13Ochre = Color(0xFFB79A63); // the one muted accent
const Color _d13Card = Color(0xFFF3EDDF); // index-card cream lift

Color _d13InkA(double a) => _d13Ink.withOpacity(a);
Color _d13OchreA(double a) => _d13Ochre.withOpacity(a);

// soft humanist sans everywhere (platform default) — friendlier than the
// anchor, with body warmth from a comfortable line height.
TextStyle _d13Text({
  double size = 14,
  Color color = _d13Ink,
  FontWeight weight = FontWeight.w400,
  double spacing = 0.1,
  double height = 1.4,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

// tiny filed label — generous tracking, the MUJI stationery voice.
TextStyle _d13Label({
  double size = 10,
  Color color = _d13Ink,
  FontWeight weight = FontWeight.w600,
  double spacing = 2.4,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.2,
    );

class Design13 extends DesignVariant {
  @override
  String get id => '13';
  @override
  String get name => 'Manila';
  @override
  String get concept =>
      '한 통의 오트빛 마닐라 폴더가 두 사람의 기억을 담는다 — 마른 인덱스카드 패널 위의 콘텐츠, 탭이 달린 카드에 사는 공용 펫. 꾸밈없는 무인양품 문구의 결.';
  @override
  String get signature =>
      '단 하나의 둥근 인덱스 탭(폴더 탭)이 현재 섹션을 표시한다 — 잉크 아웃라인뿐, 색 채움은 결코 없다. 이 탭이 화면의 유일한 크롬이다.';
  @override
  String get inspiration =>
      'Manila folder / index-card filing · MUJI stationery restraint · warm oat neutrals';
  @override
  Color get accent => _d13Ochre;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d13Text(),
      child: switch (screen) {
        HeroScreen.drawSend => _D13DrawSend(data: data),
        HeroScreen.petHome => _D13PetHome(data: data),
        HeroScreen.memoryAlbum => _D13Album(data: data),
      },
    );
  }
}

// ============================================================ folder tab (signature)
// The lone piece of chrome: a rounded index tab, ink outline only, open at the
// bottom so it flows into the folder body. Sits on the folder's top edge.
class _D13TabPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const taper = 7.0, cr = 8.0;
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(taper, cr)
      ..quadraticBezierTo(taper, 0, taper + cr, 0)
      ..lineTo(w - taper - cr, 0)
      ..quadraticBezierTo(w - taper, 0, w - taper, cr)
      ..lineTo(w, h);
    final paint = Paint()
      ..color = _d13InkA(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// A folder = the signature tab + a dry index-card panel body below it.
class _D13Folder extends StatelessWidget {
  const _D13Folder({
    required this.label,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final String label;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- the tab row: short left stub · tab · folder top edge
        SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 6),
              Container(width: 10, height: 1, color: _d13InkA(0.16)),
              CustomPaint(
                painter: _D13TabPainter(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 9, 20, 9),
                  child: Text(label,
                      style: _d13Label(
                          size: 11, color: _d13InkA(0.85), spacing: 3)),
                ),
              ),
              Expanded(child: Container(height: 1, color: _d13InkA(0.16))),
            ],
          ),
        ),
        // ---- the folder body: dry index card, top edge left open to the tab
        Expanded(
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: _d13Card,
              border: Border(
                left: BorderSide(color: _d13InkA(0.16)),
                right: BorderSide(color: _d13InkA(0.16)),
                bottom: BorderSide(color: _d13InkA(0.16)),
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

// A hairline — the paper's quiet ruling.
class _D13Hair extends StatelessWidget {
  const _D13Hair({this.opacity = 0.12});
  final double opacity;
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _d13InkA(opacity));
}

// A muted swatch: the saturated demo gradient veiled back into the manila
// system, with the memory emoji on top.
class _D13Swatch extends StatelessWidget {
  const _D13Swatch({required this.colors, required this.emoji, this.size = 48});
  final List<Color> colors;
  final String emoji;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _d13InkA(0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // manila veil mutes the swatch into the papery palette
            ColoredBox(color: _d13Manila.withOpacity(0.44)),
            Center(
                child: Text(emoji, style: TextStyle(fontSize: size * 0.44))),
          ],
        ),
      ),
    );
  }
}

class _D13IconTap extends StatelessWidget {
  const _D13IconTap({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 21, color: _d13InkA(0.7)),
      ),
    );
  }
}

// ================================================================== Draw & Send
class _D13DrawSend extends StatefulWidget {
  const _D13DrawSend({required this.data});
  final AppData data;
  @override
  State<_D13DrawSend> createState() => _D13DrawSendState();
}

class _D13DrawSendState extends State<_D13DrawSend> {
  int pen = 0;
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    return Scaffold(
      backgroundColor: _d13Manila,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- top bar: back / recipient / send
              Row(
                children: [
                  _D13IconTap(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => HapticFeedback.selectionClick(),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text('받는 사람',
                          style: _d13Label(
                              size: 9,
                              color: _d13OchreA(0.9),
                              spacing: 3)),
                      const SizedBox(height: 4),
                      Text(couple.partnerNickname,
                          style: _d13Text(
                              size: 17,
                              weight: FontWeight.w600,
                              spacing: 0.4)),
                    ],
                  ),
                  const Spacer(),
                  _D13SendButton(onTap: () => HapticFeedback.mediumImpact()),
                ],
              ),
              const SizedBox(height: 14),
              // ---- the 소통 folder: its body is the calm canvas
              Expanded(
                child: _D13Folder(
                  label: '소통',
                  padding: const EdgeInsets.all(18),
                  child: _canvas(),
                ),
              ),
              const SizedBox(height: 16),
              // ---- pen colors
              Text('펜 색', style: _d13Label(color: _d13InkA(0.5))),
              const SizedBox(height: 12),
              _penRow(),
              const SizedBox(height: 18),
              // ---- thickness
              Row(
                children: [
                  Text('굵기', style: _d13Label(color: _d13InkA(0.5))),
                  const Spacer(),
                  Text('${thickness.round()}',
                      style: _d13Text(
                          size: 12,
                          color: _d13Ochre,
                          weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              _D13Slider(
                value: thickness,
                color: demoPenColors[pen],
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => thickness = v);
                },
              ),
              const SizedBox(height: 16),
              const _D13Hair(),
              const SizedBox(height: 14),
              // ---- mode toggle + description
              _modeToggle(),
              const SizedBox(height: 10),
              Text(mode.description,
                  style: _d13Text(size: 12, color: _d13InkA(0.5))),
              const SizedBox(height: 16),
              // ---- quiet actions
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvas() {
    final ink = demoPenColors[pen];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('여기에 낙서를 그려요',
              style: _d13Text(size: 15, color: _d13InkA(0.35))),
          const SizedBox(height: 20),
          // a single mark of the chosen ink at the chosen weight
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
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: demoPenColors[i],
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: pen == i ? _d13Ochre : _d13InkA(0.2),
                  width: pen == i ? 2 : 1,
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
          _D13ModeSeg(
            label: m.label,
            selected: mode == m,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => mode = m);
            },
          ),
          if (m != SendMode.values.last) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _actions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _D13Action(
          glyph: '🖼',
          label: '갤러리',
          onTap: () => HapticFeedback.selectionClick(),
        ),
        _D13Action(
          glyph: '📷',
          label: '사진',
          onTap: () => HapticFeedback.selectionClick(),
        ),
        _D13Action(
          glyph: '👉',
          label: '찌르기',
          accent: true,
          onTap: () => HapticFeedback.heavyImpact(),
        ),
      ],
    );
  }
}

class _D13SendButton extends StatelessWidget {
  const _D13SendButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _d13InkA(0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('보내기',
                style:
                    _d13Text(size: 12, weight: FontWeight.w600, spacing: 0.6)),
            const SizedBox(width: 8),
            Container(
              width: 5,
              height: 5,
              decoration:
                  const BoxDecoration(color: _d13Ochre, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

class _D13ModeSeg extends StatelessWidget {
  const _D13ModeSeg({
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
          Text(label,
              style: _d13Text(
                size: 14,
                color: selected ? _d13Ink : _d13InkA(0.4),
                weight: selected ? FontWeight.w600 : FontWeight.w400,
                spacing: 0.5,
              )),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 46,
            color: selected ? _d13Ochre : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _D13Slider extends StatelessWidget {
  const _D13Slider({
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
      builder: (context, box) {
        final w = box.maxWidth;
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
                Container(
                  width: w,
                  height: 3,
                  decoration: BoxDecoration(
                      color: _d13Dim, borderRadius: BorderRadius.circular(2)),
                ),
                Container(
                  width: t * w,
                  height: 3,
                  decoration: BoxDecoration(
                      color: _d13Ochre, borderRadius: BorderRadius.circular(2)),
                ),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 6,
                    height: 22,
                    decoration: BoxDecoration(
                        color: _d13Ink,
                        borderRadius: BorderRadius.circular(3)),
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

class _D13Action extends StatelessWidget {
  const _D13Action({
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
              color: _d13Card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: accent ? _d13OchreA(0.7) : _d13InkA(0.14)),
            ),
            child: Text(glyph, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: _d13Label(
                  size: 10,
                  color: accent ? _d13Ochre : _d13InkA(0.6),
                  spacing: 1.6)),
        ],
      ),
    );
  }
}

// ==================================================================== Pet Home
class _D13PetHome extends StatefulWidget {
  const _D13PetHome({required this.data});
  final AppData data;
  @override
  State<_D13PetHome> createState() => _D13PetHomeState();
}

class _D13PetHomeState extends State<_D13PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    return Scaffold(
      backgroundColor: _d13Manila,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // ---- the 펫 folder: a tabbed card the pet lives on
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _D13Folder(
                  label: '펫',
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    children: [
                      // name + Lv / coins
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(pet.name,
                              style: _d13Text(
                                  size: 20, weight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text('Lv.${pet.level}',
                                style: _d13Label(
                                    size: 11,
                                    color: _d13Ochre,
                                    spacing: 1.5)),
                          ),
                          const Spacer(),
                          _D13Coins(coins: pet.coins),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // speech slip, revealed on pat
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(opacity: anim, child: child),
                                child: patted
                                    ? _D13SpeechSlip(text: pet.speech)
                                    : const SizedBox(
                                        height: 46, key: ValueKey('empty')),
                              ),
                              const SizedBox(height: 10),
                              // the pet, on a dry card tile
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => patted = !patted);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _d13Dim,
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: _d13InkA(0.12)),
                                  ),
                                  child: Text(pet.moodEmoji,
                                      style: const TextStyle(fontSize: 74)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (equipped.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('착용',
                                        style: _d13Label(
                                            size: 9,
                                            color: _d13InkA(0.45),
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
                              Text('쓰다듬어 인사를 들어보세요',
                                  style: _d13Text(
                                      size: 12, color: _d13InkA(0.4))),
                            ],
                          ),
                        ),
                      ),
                      _D13Growth(growth: pet.growth),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ---- store
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text('스토어', style: _d13Label(color: _d13InkA(0.5))),
                  const Spacer(),
                  Text('전체보기',
                      style: _d13Label(
                          size: 9, color: _d13InkA(0.4), spacing: 1.5)),
                ],
              ),
            ),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: pet.store.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _D13StoreCard(
                  item: pet.store[i],
                  onTap: () => HapticFeedback.selectionClick(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _D13Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

class _D13Coins extends StatelessWidget {
  const _D13Coins({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _d13Manila,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _d13InkA(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 7),
          Text('$coins',
              style: _d13Text(size: 12, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _D13SpeechSlip extends StatelessWidget {
  const _D13SpeechSlip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('speech'),
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        color: _d13Manila,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _d13OchreA(0.5)),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: _d13Text(size: 13, weight: FontWeight.w500)),
    );
  }
}

class _D13Growth extends StatelessWidget {
  const _D13Growth({required this.growth});
  final double growth;
  @override
  Widget build(BuildContext context) {
    final pct = (growth * 100).round();
    return Column(
      children: [
        Row(
          children: [
            Text('다음 레벨까지',
                style: _d13Label(size: 9, color: _d13InkA(0.5), spacing: 1.5)),
            const Spacer(),
            Text('$pct%',
                style: _d13Text(
                    size: 11, color: _d13Ochre, weight: FontWeight.w600)),
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
                  Container(width: w, height: 4, color: _d13Dim),
                  Container(
                    width: w * growth.clamp(0.0, 1.0),
                    height: 4,
                    color: _d13Ochre,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _D13StoreCard extends StatelessWidget {
  const _D13StoreCard({required this.item, required this.onTap});
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
          color: _d13Card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.equipped ? _d13OchreA(0.7) : _d13InkA(0.12),
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
                style: _d13Text(size: 11, weight: FontWeight.w500)),
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
          style: _d13Label(size: 9, color: _d13Ochre, spacing: 1.2));
    }
    if (it.owned) {
      return Text('보유',
          style: _d13Label(size: 9, color: _d13InkA(0.45), spacing: 1.5));
    }
    return Text('🪙 ${it.price}',
        style: _d13Text(size: 10, color: _d13InkA(0.6)));
  }
}

// ================================================================ Memory Album
class _D13Album extends StatefulWidget {
  const _D13Album({required this.data});
  final AppData data;
  @override
  State<_D13Album> createState() => _D13AlbumState();
}

class _D13AlbumState extends State<_D13Album> {
  bool byDate = true;
  DoodleType? filter;

  @override
  Widget build(BuildContext context) {
    final all = widget.data.album;
    final items =
        all.where((d) => filter == null || d.type == filter).toList();
    return Scaffold(
      backgroundColor: _d13Manila,
      body: SafeArea(
        child: Column(
          children: [
            // ---- header: count + sort toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('총 ${all.length}개의 기록',
                      style: _d13Label(size: 10, color: _d13InkA(0.5))),
                  const Spacer(),
                  _D13SortToggle(
                    byDate: byDate,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => byDate = !byDate);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ---- the 사진첩 folder: filters + filed rows
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _D13Folder(
                  label: '사진첩',
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
                  child: Column(
                    children: [
                      // type filters
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _D13FilterChip(
                              label: '전체',
                              selected: filter == null,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => filter = null);
                              },
                            ),
                            for (final t in DoodleType.values)
                              _D13FilterChip(
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
                      // filed rows
                      Expanded(
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 14),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 2),
                            child: _D13Hair(opacity: 0.09),
                          ),
                          itemBuilder: (_, i) =>
                              _D13MemoryRow(doodle: items[i]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const _D13Nav(current: 1),
          ],
        ),
      ),
    );
  }
}

class _D13SortToggle extends StatelessWidget {
  const _D13SortToggle({required this.byDate, required this.onTap});
  final bool byDate;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: on ? _d13Ink : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(label,
              style: _d13Label(
                size: 9,
                color: on ? _d13Card : _d13InkA(0.5),
                spacing: 1.2,
              )),
        );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _d13InkA(0.14)),
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

class _D13FilterChip extends StatelessWidget {
  const _D13FilterChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _d13OchreA(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? _d13OchreA(0.6) : _d13InkA(0.16),
            ),
          ),
          child: Text(label,
              style: _d13Text(
                size: 11,
                color: selected ? _d13Ink : _d13InkA(0.55),
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                spacing: 0.6,
              )),
        ),
      ),
    );
  }
}

class _D13MemoryRow extends StatelessWidget {
  const _D13MemoryRow({required this.doodle});
  final Doodle doodle;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _D13Swatch(colors: d.swatch, emoji: d.emoji, size: 50),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        _d13Text(size: 15, weight: FontWeight.w600)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(d.type.label,
                        style: _d13Label(
                            size: 9, color: _d13OchreA(0.9), spacing: 1)),
                    const SizedBox(width: 8),
                    Text('·',
                        style: _d13Text(size: 10, color: _d13InkA(0.3))),
                    const SizedBox(width: 8),
                    Text('${d.author} · ${d.at.month}/${d.at.day}',
                        style: _d13Text(size: 11, color: _d13InkA(0.5))),
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
                    style: TextStyle(fontSize: 15, color: _d13OchreA(0.95)))
                : Text('♡',
                    style: TextStyle(fontSize: 15, color: _d13InkA(0.22))),
          ),
        ],
      ),
    );
  }
}

// ==================================================================== bottom nav
class _D13Nav extends StatelessWidget {
  const _D13Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      decoration: BoxDecoration(
        color: _d13Manila,
        border: Border(top: BorderSide(color: _d13InkA(0.12))),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
          Text(label,
              style: _d13Label(
                size: 11,
                color: active ? _d13Ink : _d13InkA(0.4),
                weight: active ? FontWeight.w700 : FontWeight.w500,
                spacing: 1.5,
              )),
          const SizedBox(height: 6),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: active ? _d13Ochre : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
