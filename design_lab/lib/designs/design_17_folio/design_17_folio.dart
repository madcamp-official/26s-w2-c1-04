// design_17_folio — "Folio".
//
// The album as a bound book resting on neutral fog. A running header sits above
// wide top/bottom margins; every memory is a numbered leaf you turn through in
// order, separated by fine rules. The sole ornament is a corner folio index —
// a lone tabular-mono counter that increments like turning pages (014 / 128).
// No blink, no colour motion: precision and negative space carry the mood.
//
// Self-contained: Material/widgets only, no external packages, no assets, no
// network, no Random, no DateTime.now(). Imagery is muted gradient + emoji from
// the shared demo data. Everything except Design17 is private (_D17 prefix).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ------------------------------------------------------------------ palette
const Color _d17Fog = Color(0xFFECEBE7); // ground — neutral fog
const Color _d17Dim = Color(0xFFE1E0DB); // dimmer fog for wells
const Color _d17Page = Color(0xFFF4F3EF); // the leaf / bound page
const Color _d17Ink = Color(0xFF211F1D); // near-black ink
const Color _d17Sage = Color(0xFF7E8972); // the one muted accent

Color _d17InkA(double a) => _d17Ink.withOpacity(a);
Color _d17SageA(double a) => _d17Sage.withOpacity(a);

String _d17Pad3(int n) => n.abs().toString().padLeft(3, '0');

// ------------------------------------------------------------------ type
// Grotesque small-caps header voice — uppercased, wide-tracked, systematic.
TextStyle _d17Head({
  double size = 12,
  Color color = _d17Ink,
  FontWeight weight = FontWeight.w600,
  double spacing = 2.6,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.2,
    );

// Restrained sans for captions / body.
TextStyle _d17Body({
  double size = 14,
  Color color = _d17Ink,
  FontWeight weight = FontWeight.w400,
  double spacing = 0.2,
  double height = 1.4,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

// Tabular monospace folio numerals — the counter's exact, non-jittering voice.
TextStyle _d17Folio({
  double size = 13,
  Color color = _d17Ink,
  FontWeight weight = FontWeight.w500,
  double spacing = 1.4,
}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

class Design17 extends DesignVariant {
  @override
  String get id => '17';
  @override
  String get name => 'Folio';
  @override
  String get concept =>
      '중립 안개 위에 놓인 제본된 책 — 러닝 헤더와 넉넉한 위아래 여백, 모든 기억은 순서대로 넘기는 번호 매겨진 낱장(leaf).';
  @override
  String get signature =>
      '모서리의 폴리오 인덱스가 책장을 넘기듯 숫자만 올라간다 ( 014 / 128 ) — 깜빡임도 색의 움직임도 없이, 등폭 모노 카운터 하나가 유일한 장식이다.';
  @override
  String get inspiration =>
      'Bound book on fog · running headers & folio numbers · grotesque small-caps + tabular figures';
  @override
  Color get accent => _d17Sage;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d17Body(),
      child: switch (screen) {
        HeroScreen.drawSend => _D17DrawSend(data: data),
        HeroScreen.petHome => _D17PetHome(data: data),
        HeroScreen.memoryAlbum => _D17Album(data: data),
      },
    );
  }
}

// ============================================================= shared atoms

// A hairline — the fine rule that separates leaves and sections.
class _D17Rule extends StatelessWidget {
  const _D17Rule({this.opacity = 0.12});
  final double opacity;
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: _d17InkA(opacity));
  }
}

// THE signature. A lone tabular-mono folio index shown in a page/header corner.
class _D17FolioIndex extends StatelessWidget {
  const _D17FolioIndex({
    required this.value,
    this.total,
    this.label = 'FOLIO',
    this.size = 13,
  });
  final int value;
  final int? total;
  final String label;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: _d17Head(size: 8, color: _d17SageA(0.95), spacing: 2.4)),
        const SizedBox(width: 9),
        Text(_d17Pad3(value), style: _d17Folio(size: size, color: _d17Ink)),
        if (total != null) ...[
          Text('  /  ', style: _d17Folio(size: size - 2, color: _d17InkA(0.32))),
          Text(_d17Pad3(total!),
              style: _d17Folio(size: size - 1, color: _d17InkA(0.42))),
        ],
      ],
    );
  }
}

// The running header — book title left, folio index right, over wide margins.
class _D17RunningHeader extends StatelessWidget {
  const _D17RunningHeader({required this.title, required this.folio});
  final String title;
  final Widget folio;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _d17Head(size: 11, color: _d17InkA(0.75))),
            ),
            const SizedBox(width: 12),
            folio,
          ],
        ),
        const SizedBox(height: 12),
        const _D17Rule(opacity: 0.16),
      ],
    );
  }
}

// A muted swatch leaf — the saturated demo gradient softened under a fog scrim.
class _D17Swatch extends StatelessWidget {
  const _D17Swatch({
    required this.colors,
    required this.emoji,
    this.size = 40,
    this.emojiSize = 20,
  });
  final List<Color> colors;
  final String emoji;
  final double size;
  final double emojiSize;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // fog scrim + desaturating overlay keeps the swatch quiet.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _d17Fog.withOpacity(0.42),
                border: Border.all(color: _d17InkA(0.10)),
              ),
            ),
          ),
          Center(
              child: Text(emoji, style: TextStyle(fontSize: emojiSize))),
        ],
      ),
    );
  }
}

// Quiet bottom nav — mono small-caps, active leaf marked by a short sage rule.
class _D17Nav extends StatelessWidget {
  const _D17Nav({required this.current});
  final int current;
  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      decoration: const BoxDecoration(
        color: _d17Fog,
        border: Border(top: BorderSide(color: Color(0x22211F1D))),
      ),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 10),
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
          Container(
            height: 2,
            width: 16,
            color: active ? _d17Sage : Colors.transparent,
          ),
          const SizedBox(height: 8),
          Text(label,
              style: _d17Head(
                size: 10,
                color: active ? _d17Ink : _d17InkA(0.4),
                weight: active ? FontWeight.w700 : FontWeight.w500,
                spacing: 1.6,
              )),
        ],
      ),
    );
  }
}

// ================================================================ Draw & Send
class _D17DrawSend extends StatefulWidget {
  const _D17DrawSend({required this.data});
  final AppData data;
  @override
  State<_D17DrawSend> createState() => _D17DrawSendState();
}

class _D17DrawSendState extends State<_D17DrawSend> {
  int pen = 0;
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    // The draft would be bound as the next leaf after the 128 already kept.
    final nextLeaf = widget.data.report.totalDoodles + 1;
    return Scaffold(
      backgroundColor: _d17Fog,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- top: back / recipient / send
              Row(
                children: [
                  _D17IconTap(
                    icon: Icons.arrow_back,
                    onTap: () => HapticFeedback.selectionClick(),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text('TO',
                          style: _d17Head(
                              size: 8, color: _d17SageA(0.95), spacing: 3)),
                      const SizedBox(height: 4),
                      Text(couple.partnerNickname,
                          style: _d17Body(
                              size: 17, weight: FontWeight.w600, spacing: 0.6)),
                    ],
                  ),
                  const Spacer(),
                  _D17SendButton(onTap: () => HapticFeedback.mediumImpact()),
                ],
              ),
              const SizedBox(height: 18),
              // ---- running header + folio (the draft's leaf number)
              _D17RunningHeader(
                title: '새 낙서 · new leaf',
                folio: _D17FolioIndex(
                    label: 'LEAF',
                    value: nextLeaf,
                    total: widget.data.report.totalDoodles),
              ),
              const SizedBox(height: 18),
              // ---- the bound page: a calm canvas with a corner folio number
              Expanded(child: _page(nextLeaf)),
              const SizedBox(height: 22),
              // ---- pen colours
              Text('잉크 · INK',
                  style: _d17Head(size: 9, color: _d17InkA(0.5), spacing: 2.4)),
              const SizedBox(height: 14),
              _penRow(),
              const SizedBox(height: 22),
              // ---- thickness
              Row(
                children: [
                  Text('굵기 · WEIGHT',
                      style:
                          _d17Head(size: 9, color: _d17InkA(0.5), spacing: 2.4)),
                  const Spacer(),
                  Text('${thickness.round().toString().padLeft(2, '0')} PT',
                      style: _d17Folio(size: 11, color: _d17Sage)),
                ],
              ),
              const SizedBox(height: 12),
              _D17Thickness(
                value: thickness,
                color: demoPenColors[pen],
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => thickness = v);
                },
              ),
              const SizedBox(height: 20),
              const _D17Rule(opacity: 0.12),
              const SizedBox(height: 16),
              // ---- mode toggle + description
              _modeToggle(),
              const SizedBox(height: 10),
              Text(mode.description,
                  style: _d17Body(size: 12, color: _d17InkA(0.55))),
              const SizedBox(height: 18),
              // ---- quiet actions
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _page(int folio) {
    final ink = demoPenColors[pen];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _d17Page,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _d17InkA(0.14)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _D17RulePainter())),
          // wide-margin quiet prompt + a preview mark of the chosen ink
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('이 장에 오늘을 적습니다',
                    style: _d17Body(size: 14, color: _d17InkA(0.4))),
                const SizedBox(height: 20),
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
          // the page's own folio number, printed in the bottom corner.
          Positioned(
            right: 16,
            bottom: 14,
            child: Text(_d17Pad3(folio),
                style: _d17Folio(size: 12, color: _d17InkA(0.5))),
          ),
          Positioned(
            left: 16,
            top: 14,
            child: Text('§',
                style: _d17Body(size: 14, color: _d17InkA(0.28))),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: demoPenColors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: pen == i ? _d17Ink : _d17InkA(0.15),
                      width: pen == i ? 1.6 : 1,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  height: 2,
                  width: 14,
                  color: pen == i ? _d17Sage : Colors.transparent,
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
          _D17ModeTab(
            label: m.label,
            selected: mode == m,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => mode = m);
            },
          ),
          if (m != SendMode.values.last) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _actions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _D17Action(
            glyph: '🖼', label: '갤러리', onTap: () => HapticFeedback.selectionClick()),
        _D17Action(
            glyph: '📷', label: '사진', onTap: () => HapticFeedback.selectionClick()),
        _D17Action(
            glyph: '⚡',
            label: '찌르기',
            accent: true,
            onTap: () => HapticFeedback.heavyImpact()),
      ],
    );
  }
}

class _D17RulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _d17InkA(0.05)
      ..strokeWidth = 1;
    const gap = 32.0;
    for (double y = gap; y < size.height; y += gap) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _D17IconTap extends StatelessWidget {
  const _D17IconTap({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: _d17InkA(0.75)),
      ),
    );
  }
}

class _D17SendButton extends StatelessWidget {
  const _D17SendButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _d17Ink,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text('보내기',
            style: _d17Head(size: 10, color: _d17Fog, spacing: 2.4)),
      ),
    );
  }
}

class _D17ModeTab extends StatelessWidget {
  const _D17ModeTab({
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
              style: _d17Body(
                size: 14,
                color: selected ? _d17Ink : _d17InkA(0.4),
                weight: selected ? FontWeight.w600 : FontWeight.w400,
                spacing: 0.8,
              )),
          const SizedBox(height: 7),
          Container(
            height: 2,
            width: 48,
            color: selected ? _d17Sage : _d17InkA(0.10),
          ),
        ],
      ),
    );
  }
}

class _D17Thickness extends StatelessWidget {
  const _D17Thickness({
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
                Container(width: w, height: 1, color: _d17InkA(0.14)),
                Container(width: t * w, height: 2, color: _d17SageA(0.75)),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 3,
                    height: 24,
                    color: _d17Ink,
                  ),
                ),
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

class _D17Action extends StatelessWidget {
  const _D17Action({
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
              color: accent ? _d17SageA(0.12) : _d17Dim,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                  color: accent ? _d17SageA(0.55) : _d17InkA(0.10)),
            ),
            child: Text(glyph, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 9),
          Text(label,
              style: _d17Head(
                  size: 9,
                  color: accent ? _d17Sage : _d17InkA(0.6),
                  spacing: 1.8)),
        ],
      ),
    );
  }
}

// ==================================================================== Pet Home
class _D17PetHome extends StatefulWidget {
  const _D17PetHome({required this.data});
  final AppData data;
  @override
  State<_D17PetHome> createState() => _D17PetHomeState();
}

class _D17PetHomeState extends State<_D17PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    final pct = (pet.growth * 100).round();
    return Scaffold(
      backgroundColor: _d17Fog,
      body: SafeArea(
        child: Column(
          children: [
            // ---- running header: pet title + growth folio
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
              child: _D17RunningHeader(
                title: '우리 펫 · ${pet.name}',
                folio:
                    _D17FolioIndex(label: 'GROW', value: pct, total: 100, size: 13),
              ),
            ),
            const SizedBox(height: 16),
            // ---- name + Lv + coins
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(pet.name,
                      style: _d17Body(
                          size: 22, weight: FontWeight.w600, spacing: 0.4)),
                  const SizedBox(width: 10),
                  Text('LV.${pet.level.toString().padLeft(2, '0')}',
                      style: _d17Folio(size: 12, color: _d17Sage)),
                  const Spacer(),
                  _D17Coins(coins: pet.coins),
                ],
              ),
            ),
            // ---- the one subject: the pet (pat reveals speech)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: patted
                          ? _D17SpeechSlip(text: pet.speech)
                          : const SizedBox(height: 48, key: ValueKey('empty')),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => patted = !patted);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 172,
                        height: 172,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _d17Page,
                          shape: BoxShape.circle,
                          border: Border.all(color: _d17InkA(0.12)),
                        ),
                        child: Text(pet.moodEmoji,
                            style: const TextStyle(fontSize: 80)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (equipped.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('착용',
                              style: _d17Head(
                                  size: 8,
                                  color: _d17InkA(0.5),
                                  spacing: 2.2)),
                          const SizedBox(width: 10),
                          for (final e in equipped) ...[
                            Text(e.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text('쓰다듬어 인사를 듣기',
                        style: _d17Body(size: 12, color: _d17InkA(0.45))),
                    const SizedBox(height: 26),
                    _D17Growth(growth: pet.growth),
                  ],
                ),
              ),
            ),
            // ---- store
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
              child: Row(
                children: [
                  Text('스토어 · STORE',
                      style: _d17Head(
                          size: 9, color: _d17InkA(0.5), spacing: 2.2)),
                  const Spacer(),
                  Text('전체보기',
                      style: _d17Head(
                          size: 8, color: _d17InkA(0.4), spacing: 1.6)),
                ],
              ),
            ),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                itemCount: pet.store.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _D17StoreCard(
                  item: pet.store[i],
                  onTap: () => HapticFeedback.selectionClick(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _D17Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

class _D17Coins extends StatelessWidget {
  const _D17Coins({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _d17Dim,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d17InkA(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Text('$coins', style: _d17Folio(size: 12, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _D17SpeechSlip extends StatelessWidget {
  const _D17SpeechSlip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('speech'),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _d17Page,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d17SageA(0.45)),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: _d17Body(size: 13, weight: FontWeight.w500)),
    );
  }
}

class _D17Growth extends StatelessWidget {
  const _D17Growth({required this.growth});
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
              Text('다음 레벨 · NEXT',
                  style: _d17Head(size: 8, color: _d17InkA(0.5), spacing: 2)),
              const Spacer(),
              Text('$pct%', style: _d17Folio(size: 11, color: _d17Sage)),
            ],
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return Stack(
                children: [
                  Container(width: w, height: 3, color: _d17InkA(0.10)),
                  Container(
                    width: w * growth.clamp(0.0, 1.0),
                    height: 3,
                    color: _d17Sage,
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

class _D17StoreCard extends StatelessWidget {
  const _D17StoreCard({required this.item, required this.onTap});
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
          color: item.equipped ? _d17SageA(0.10) : _d17Page,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: item.equipped ? _d17SageA(0.5) : _d17InkA(0.10),
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
                style: _d17Body(size: 11, spacing: 0.1)),
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
          style: _d17Head(size: 8, color: _d17Sage, spacing: 1.4));
    }
    if (it.owned) {
      return Text('보유',
          style: _d17Head(size: 8, color: _d17InkA(0.45), spacing: 1.6));
    }
    return Text('🪙 ${it.price}',
        style: _d17Folio(size: 9, color: _d17InkA(0.6)));
  }
}

// ================================================================ Memory Album
class _D17Album extends StatefulWidget {
  const _D17Album({required this.data});
  final AppData data;
  @override
  State<_D17Album> createState() => _D17AlbumState();
}

class _D17AlbumState extends State<_D17Album> {
  static const double _leafHeight = 90;
  bool byDate = true;
  DoodleType? filter;
  int _topLeaf = 1; // 1-based index of the top-visible leaf (the signature)
  late final ScrollController _sc;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _sc.removeListener(_onScroll);
    _sc.dispose();
    super.dispose();
  }

  List<Doodle> get _items {
    final list =
        widget.data.album.where((d) => filter == null || d.type == filter).toList();
    if (!byDate) {
      list.sort((a, b) => a.type.index.compareTo(b.type.index));
    }
    return list;
  }

  void _onScroll() {
    if (!_sc.hasClients) return;
    final n = _items.length;
    final idx = (_sc.offset / _leafHeight).floor().clamp(0, n == 0 ? 0 : n - 1);
    final leaf = idx + 1;
    if (leaf != _topLeaf) setState(() => _topLeaf = leaf);
  }

  void _resetTop() {
    _topLeaf = 1;
    if (_sc.hasClients) _sc.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final total = widget.data.report.totalDoodles;
    final topLeaf = items.isEmpty ? 0 : _topLeaf.clamp(1, items.length);
    return Scaffold(
      backgroundColor: _d17Fog,
      body: SafeArea(
        child: Column(
          children: [
            // ---- running header with the LIVE folio counter (the signature)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
              child: _D17RunningHeader(
                title: '낙서첩 · memory album',
                folio: _D17FolioIndex(
                    label: 'FOLIO', value: topLeaf, total: total, size: 14),
              ),
            ),
            const SizedBox(height: 16),
            // ---- controls: sort toggle + type filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Text('${items.length}장의 낱장',
                      style: _d17Body(size: 12, color: _d17InkA(0.5))),
                  const Spacer(),
                  _D17SortToggle(
                    byDate: byDate,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        byDate = !byDate;
                        _resetTop();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                children: [
                  _D17FilterChip(
                    label: '전체',
                    selected: filter == null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        filter = null;
                        _resetTop();
                      });
                    },
                  ),
                  for (final t in DoodleType.values)
                    _D17FilterChip(
                      label: t.label,
                      selected: filter == t,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          filter = t;
                          _resetTop();
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: _D17Rule(opacity: 0.14),
            ),
            // ---- the bound leaves: numbered, hairline-divided, turned in order
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text('빈 장',
                          style: _d17Head(
                              size: 11, color: _d17InkA(0.4), spacing: 3)))
                  : ListView.builder(
                      controller: _sc,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: items.length,
                      itemExtent: _leafHeight,
                      itemBuilder: (_, i) => _D17Leaf(
                        doodle: items[i],
                        leaf: i + 1,
                        height: _leafHeight,
                      ),
                    ),
            ),
            const _D17Nav(current: 1),
          ],
        ),
      ),
    );
  }
}

class _D17SortToggle extends StatelessWidget {
  const _D17SortToggle({required this.byDate, required this.onTap});
  final bool byDate;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? _d17Ink : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
          ),
          child: Text(label,
              style: _d17Head(
                size: 8,
                color: on ? _d17Fog : _d17InkA(0.45),
                spacing: 1.4,
              )),
        );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: _d17InkA(0.14)),
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

class _D17FilterChip extends StatelessWidget {
  const _D17FilterChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _d17SageA(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
            border: Border.all(
              color: selected ? _d17SageA(0.5) : _d17InkA(0.14),
            ),
          ),
          child: Text(label,
              style: _d17Head(
                size: 9,
                color: selected ? _d17Ink : _d17InkA(0.55),
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                spacing: 1.2,
              )),
        ),
      ),
    );
  }
}

// a single numbered leaf — folio number, muted swatch, caption, meta, liked.
class _D17Leaf extends StatelessWidget {
  const _D17Leaf({
    required this.doodle,
    required this.leaf,
    required this.height,
  });
  final Doodle doodle;
  final int leaf;
  final double height;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1F211F1D))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // leaf folio number — quiet tabular mono
          SizedBox(
            width: 34,
            child: Text(_d17Pad3(leaf),
                style: _d17Folio(size: 12, color: _d17InkA(0.5))),
          ),
          _D17Swatch(colors: d.swatch, emoji: d.emoji, size: 44, emojiSize: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d17Body(
                        size: 15, weight: FontWeight.w600, spacing: 0.1)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(d.type.label,
                        style: _d17Head(
                            size: 8, color: _d17SageA(0.95), spacing: 1.2)),
                    const SizedBox(width: 8),
                    Text('·',
                        style: _d17Body(size: 10, color: _d17InkA(0.3))),
                    const SizedBox(width: 8),
                    Text('${d.author} · ${d.at.month}/${d.at.day}',
                        style: _d17Folio(size: 10, color: _d17InkA(0.5))),
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
                    style: TextStyle(fontSize: 14, color: _d17SageA(0.9)))
                : Text('♡',
                    style: TextStyle(fontSize: 14, color: _d17InkA(0.22))),
          ),
        ],
      ),
    );
  }
}
