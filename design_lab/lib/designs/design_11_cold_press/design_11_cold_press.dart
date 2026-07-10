// design_11_cold_press — "Cold Press".
//
// The cool-stone counterpart to Quiet Signal's warm clay. One hero memory
// floats in a wide off-white mat like a matted gallery print — architectural
// calm, nothing competing. The sole ornament is a hairline passe-partout: a
// single 0.5px inset keyline framing the one memory. Nothing blinks or moves;
// the quiet mat border is the only decoration. Restrained neo-grotesque sans
// throughout, tracked-caps eyebrows, cool mineral palette.
//
// Self-contained: no external packages, no assets, no network, no Random,
// no DateTime.now(). Imagery is gradient + emoji from shared demo data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ---------------------------------------------------------------- palette
const Color _d11Mist = Color(0xFFECEDE9); // ground
const Color _d11Dim = Color(0xFFE2E3DE); // dim ground
const Color _d11Ink = Color(0xFF26282B); // slate ink
const Color _d11Euc = Color(0xFF8A9A8E); // muted eucalyptus accent
const Color _d11Print = Color(0xFFF4F5F2); // cool off-white mat / print field

Color _d11InkA(double a) => _d11Ink.withOpacity(a);
Color _d11EucA(double a) => _d11Euc.withOpacity(a);

// restrained neo-grotesque sans — cool, architectural, no mono anywhere.
TextStyle _d11Sans({
  double size = 14,
  Color color = _d11Ink,
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

// tracked-caps eyebrow — the quiet architectural label voice.
TextStyle _d11EyebrowStyle({Color color = _d11Ink, double size = 10}) =>
    _d11Sans(
      size: size,
      color: color,
      weight: FontWeight.w600,
      spacing: 2.6,
      height: 1.2,
    );

class Design11 extends DesignVariant {
  @override
  String get id => '11';
  @override
  String get name => 'Cold Press';
  @override
  String get concept =>
      '따뜻한 점토 대신 차가운 돌 — 하나의 기억이 넓은 오프화이트 매트 위에 액자 프린트처럼 떠 있다. 건축적 정적, 경쟁하는 것 없음.';
  @override
  String get signature =>
      '헤어라인 파스파르투 — 그 하나의 기억을 감싸는 단 하나의 0.5px 인셋 키라인. 아무것도 깜빡이거나 움직이지 않고, 고요한 매트 테두리만이 유일한 장식이다.';
  @override
  String get inspiration =>
      'Matted gallery print · passe-partout keyline · cool mineral minimalism';
  @override
  Color get accent => _d11Euc;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d11Sans(),
      child: switch (screen) {
        HeroScreen.drawSend => _D11DrawSend(data: data),
        HeroScreen.petHome => _D11PetHome(data: data),
        HeroScreen.memoryAlbum => _D11Album(data: data),
      },
    );
  }
}

// ======================================================= shared quiet pieces

// THE SIGNATURE — a hairline passe-partout. Content floats in a wide off-white
// mat, framed by a single 0.5px inset keyline. Used once per screen on the one
// hero element.
class _D11Matted extends StatelessWidget {
  const _D11Matted({
    required this.child,
    this.mat = 18,
    this.inset = 0,
    this.matColor = _d11Print,
    this.radius = 2,
    this.keyline = 0.30,
  });
  final Widget child;
  final double mat;
  final double inset;
  final double radius;
  final double keyline;
  final Color matColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: matColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _d11InkA(0.07)),
      ),
      padding: EdgeInsets.all(mat),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          // the single hairline keyline — the only ornament.
          border: Border.all(color: _d11InkA(keyline), width: 0.5),
        ),
        padding: EdgeInsets.all(inset),
        child: child,
      ),
    );
  }
}

class _D11Eyebrow extends StatelessWidget {
  const _D11Eyebrow(this.text, {this.color = _d11Ink, this.size = 10});
  final String text;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: _d11EyebrowStyle(color: color.withOpacity(0.55), size: size));
  }
}

class _D11Hair extends StatelessWidget {
  const _D11Hair({this.opacity = 0.10});
  final double opacity;
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _d11InkA(opacity));
}

class _D11IconTap extends StatelessWidget {
  const _D11IconTap({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: _d11InkA(0.7)),
      ),
    );
  }
}

// ================================================================== Draw & Send
class _D11DrawSend extends StatefulWidget {
  const _D11DrawSend({required this.data});
  final AppData data;
  @override
  State<_D11DrawSend> createState() => _D11DrawSendState();
}

class _D11DrawSendState extends State<_D11DrawSend> {
  int pen = 0;
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    return Scaffold(
      backgroundColor: _d11Mist,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- top: back / recipient / send
              Row(
                children: [
                  _D11IconTap(
                    icon: Icons.arrow_back,
                    onTap: () => HapticFeedback.selectionClick(),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      const _D11Eyebrow('TO'),
                      const SizedBox(height: 4),
                      Text(couple.partnerNickname,
                          style: _d11Sans(
                              size: 17,
                              weight: FontWeight.w600,
                              spacing: 0.4)),
                    ],
                  ),
                  const Spacer(),
                  _D11SendButton(onTap: () => HapticFeedback.mediumImpact()),
                ],
              ),
              const SizedBox(height: 20),
              // ---- the one memory: a matted canvas floating in the mat
              Expanded(child: _canvas()),
              const SizedBox(height: 24),
              // ---- pen colors
              const _D11Eyebrow('잉크 · INK'),
              const SizedBox(height: 14),
              _penRow(),
              const SizedBox(height: 24),
              // ---- thickness
              Row(
                children: [
                  const _D11Eyebrow('굵기 · WEIGHT'),
                  const Spacer(),
                  Text('${thickness.round()}',
                      style: _d11Sans(
                          size: 12, color: _d11Euc, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              _D11Thickness(
                value: thickness,
                color: demoPenColors[pen],
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => thickness = v);
                },
              ),
              const SizedBox(height: 20),
              const _D11Hair(),
              const SizedBox(height: 16),
              // ---- mode toggle + description
              _modeToggle(),
              const SizedBox(height: 10),
              Text(mode.description,
                  style: _d11Sans(size: 12, color: _d11InkA(0.5))),
              const SizedBox(height: 18),
              // ---- quiet actions
              _bottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvas() {
    final ink = demoPenColors[pen];
    return _D11Matted(
      mat: 14,
      inset: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _D11Eyebrow('BLANK PRINT', size: 9),
            const SizedBox(height: 14),
            Text('낙서를 시작하세요',
                style: _d11Sans(size: 15, color: _d11InkA(0.4), spacing: 0.4)),
            const SizedBox(height: 20),
            // current stroke preview — a single quiet mark of the chosen ink
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
            // selection echoes the passe-partout: a hairline keyline ring.
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: pen == i ? _d11InkA(0.45) : Colors.transparent,
                  width: 0.5,
                ),
              ),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: demoPenColors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: _d11InkA(0.14)),
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
          _D11ModeTab(
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

  Widget _bottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _D11Action(
          glyph: '🖼',
          label: '갤러리',
          onTap: () => HapticFeedback.selectionClick(),
        ),
        _D11Action(
          glyph: '📷',
          label: '사진',
          onTap: () => HapticFeedback.selectionClick(),
        ),
        _D11Action(
          glyph: '👉',
          label: '찌르기',
          accent: true,
          onTap: () => HapticFeedback.heavyImpact(),
        ),
      ],
    );
  }
}

class _D11SendButton extends StatelessWidget {
  const _D11SendButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _d11Ink,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text('보내기',
            style: _d11Sans(
                size: 12,
                color: _d11Mist,
                weight: FontWeight.w600,
                spacing: 1.6)),
      ),
    );
  }
}

class _D11ModeTab extends StatelessWidget {
  const _D11ModeTab({
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
              style: _d11Sans(
                size: 14,
                color: selected ? _d11Ink : _d11InkA(0.4),
                weight: selected ? FontWeight.w600 : FontWeight.w400,
                spacing: 0.6,
              )),
          const SizedBox(height: 7),
          Container(
            height: 1.5,
            width: 48,
            color: selected ? _d11Euc : _d11InkA(0.08),
          ),
        ],
      ),
    );
  }
}

// minimal thickness control — no Material Slider chrome.
class _D11Thickness extends StatelessWidget {
  const _D11Thickness({
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
                Container(width: w, height: 1, color: _d11InkA(0.14)),
                Container(width: t * w, height: 1.5, color: _d11EucA(0.8)),
                // thumb — a small square stone
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _d11Ink,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // live preview dot of chosen ink, right edge
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

class _D11Action extends StatelessWidget {
  const _D11Action({
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
              color: accent ? _d11EucA(0.12) : _d11Print,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                  color: accent ? _d11EucA(0.5) : _d11InkA(0.12), width: 0.5),
            ),
            child: Text(glyph, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: _d11Sans(
                  size: 11,
                  color: accent ? _d11Euc : _d11InkA(0.6),
                  spacing: 0.6)),
        ],
      ),
    );
  }
}

// ==================================================================== Pet Home
class _D11PetHome extends StatefulWidget {
  const _D11PetHome({required this.data});
  final AppData data;
  @override
  State<_D11PetHome> createState() => _D11PetHomeState();
}

class _D11PetHomeState extends State<_D11PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    return Scaffold(
      backgroundColor: _d11Mist,
      body: SafeArea(
        child: Column(
          children: [
            // ---- top: name / Lv / coins
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _D11Eyebrow('우리 펫 · OUR PET'),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(pet.name,
                              style: _d11Sans(
                                  size: 20, weight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text('LV.${pet.level}',
                              style: _d11Sans(
                                  size: 12,
                                  color: _d11Euc,
                                  weight: FontWeight.w600,
                                  spacing: 1)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  _D11Coins(coins: pet.coins),
                ],
              ),
            ),
            // ---- the one subject: the pet, matted like a portrait print
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // speech, quietly revealed on pat (fade only, no motion loop)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: patted
                          ? _D11SpeechSlip(text: pet.speech)
                          : const SizedBox(height: 44, key: ValueKey('empty')),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => patted = !patted);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: _D11Matted(
                        mat: 16,
                        inset: 14,
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: Center(
                            child: Text(pet.moodEmoji,
                                style: const TextStyle(fontSize: 82)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (equipped.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _D11Eyebrow('착용', size: 9),
                          const SizedBox(width: 10),
                          for (final e in equipped) ...[
                            Text(e.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text('쓰다듬어 한 마디 듣기',
                        style: _d11Sans(size: 12, color: _d11InkA(0.45))),
                    const SizedBox(height: 24),
                    _D11Growth(growth: pet.growth),
                  ],
                ),
              ),
            ),
            // ---- store
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
              child: Row(
                children: [
                  const _D11Eyebrow('스토어 · STORE'),
                  const Spacer(),
                  Text('전체보기',
                      style: _d11Sans(size: 11, color: _d11InkA(0.45))),
                ],
              ),
            ),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                itemCount: pet.store.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _D11StoreCard(
                  item: pet.store[i],
                  onTap: () => HapticFeedback.selectionClick(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _D11Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

class _D11Coins extends StatelessWidget {
  const _D11Coins({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _d11Dim,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d11InkA(0.10), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Text('$coins',
              style: _d11Sans(size: 13, weight: FontWeight.w600, spacing: 0.5)),
        ],
      ),
    );
  }
}

class _D11SpeechSlip extends StatelessWidget {
  const _D11SpeechSlip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('speech'),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _d11Print,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d11EucA(0.45), width: 0.5),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: _d11Sans(size: 13, weight: FontWeight.w500)),
    );
  }
}

class _D11Growth extends StatelessWidget {
  const _D11Growth({required this.growth});
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
              const _D11Eyebrow('다음 레벨', size: 9),
              const Spacer(),
              Text('$pct%',
                  style: _d11Sans(
                      size: 11, color: _d11Euc, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    Container(width: w, height: 3, color: _d11InkA(0.10)),
                    Container(
                      width: w * growth.clamp(0.0, 1.0),
                      height: 3,
                      color: _d11Euc,
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

class _D11StoreCard extends StatelessWidget {
  const _D11StoreCard({required this.item, required this.onTap});
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
          color: _d11Print,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: item.equipped ? _d11EucA(0.55) : _d11InkA(0.10),
            width: 0.5,
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
                style: _d11Sans(size: 11)),
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
          style: _d11Sans(
              size: 9, color: _d11Euc, weight: FontWeight.w600, spacing: 1));
    }
    if (it.owned) {
      return Text('보유', style: _d11Sans(size: 9, color: _d11InkA(0.45), spacing: 1));
    }
    return Text('🪙 ${it.price}',
        style: _d11Sans(size: 9, color: _d11InkA(0.6)));
  }
}

// ================================================================ Memory Album
class _D11Album extends StatefulWidget {
  const _D11Album({required this.data});
  final AppData data;
  @override
  State<_D11Album> createState() => _D11AlbumState();
}

class _D11AlbumState extends State<_D11Album> {
  bool byDate = true;
  DoodleType? filter;
  String? featuredId; // the one memory promoted into the mat

  @override
  Widget build(BuildContext context) {
    final all = widget.data.album;
    final items =
        all.where((d) => filter == null || d.type == filter).toList();
    // the one hero memory: promoted selection, else first in view.
    final Doodle? hero = items.isEmpty
        ? null
        : items.firstWhere((d) => d.id == featuredId,
            orElse: () => items.first);
    return Scaffold(
      backgroundColor: _d11Mist,
      body: SafeArea(
        child: Column(
          children: [
            // ---- header: title + sort toggle
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _D11Eyebrow('기록 · ARCHIVE'),
                      const SizedBox(height: 5),
                      Text('낙서 사진첩',
                          style:
                              _d11Sans(size: 20, weight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  _D11SortToggle(
                    byDate: byDate,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => byDate = !byDate);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // ---- the one hero memory, matted like a gallery print
            if (hero != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _D11Featured(doodle: hero),
              ),
            const SizedBox(height: 18),
            // ---- type filters
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                children: [
                  _D11FilterChip(
                    label: '전체',
                    selected: filter == null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        filter = null;
                        featuredId = null;
                      });
                    },
                  ),
                  for (final t in DoodleType.values)
                    _D11FilterChip(
                      label: t.label,
                      selected: filter == t,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          filter = t;
                          featuredId = null;
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // ---- quiet log: each memory a restrained row
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: _D11Hair(),
                ),
                itemBuilder: (_, i) {
                  final d = items[i];
                  return _D11MemoryRow(
                    doodle: d,
                    active: hero?.id == d.id,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => featuredId = d.id);
                    },
                  );
                },
              ),
            ),
            const _D11Nav(current: 1),
          ],
        ),
      ),
    );
  }
}

class _D11SortToggle extends StatelessWidget {
  const _D11SortToggle({required this.byDate, required this.onTap});
  final bool byDate;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? _d11Ink : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
          ),
          child: Text(label,
              style: _d11Sans(
                size: 10,
                color: on ? _d11Mist : _d11InkA(0.45),
                weight: FontWeight.w600,
                spacing: 0.6,
              )),
        );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: _d11InkA(0.12), width: 0.5),
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

class _D11FilterChip extends StatelessWidget {
  const _D11FilterChip({
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
            color: selected ? _d11EucA(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(1),
            border: Border.all(
              color: selected ? _d11EucA(0.5) : _d11InkA(0.14),
              width: 0.5,
            ),
          ),
          child: Text(label,
              style: _d11Sans(
                size: 11,
                color: selected ? _d11Ink : _d11InkA(0.55),
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                spacing: 0.6,
              )),
        ),
      ),
    );
  }
}

// the one hero memory — matted like a gallery print, framed by the keyline.
class _D11Featured extends StatelessWidget {
  const _D11Featured({required this.doodle});
  final Doodle doodle;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return _D11Matted(
      mat: 16,
      inset: 10,
      child: Row(
        children: [
          // the print itself — muted swatch gradient stand-in
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: [
                  Color.alphaBlend(_d11Print.withOpacity(0.34), d.swatch.first),
                  Color.alphaBlend(_d11Print.withOpacity(0.34), d.swatch.last),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(d.emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('지금 걸린 기억'.toUpperCase(),
                    style: _d11EyebrowStyle(color: _d11EucA(0.9), size: 9)),
                const SizedBox(height: 8),
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d11Sans(size: 16, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${d.author} · ${d.at.month}/${d.at.day}',
                    style: _d11Sans(size: 11, color: _d11InkA(0.5))),
              ],
            ),
          ),
          if (d.liked)
            Text('♥',
                style: TextStyle(fontSize: 15, color: _d11EucA(0.9))),
        ],
      ),
    );
  }
}

// a single quiet memory row in the log.
class _D11MemoryRow extends StatelessWidget {
  const _D11MemoryRow({
    required this.doodle,
    required this.active,
    required this.onTap,
  });
  final Doodle doodle;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // muted swatch + emoji
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: LinearGradient(
                  colors: [
                    Color.alphaBlend(
                        _d11Print.withOpacity(0.38), d.swatch.first),
                    Color.alphaBlend(
                        _d11Print.withOpacity(0.38), d.swatch.last),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: active ? _d11EucA(0.6) : _d11InkA(0.06),
                  width: 0.5,
                ),
              ),
              child: Text(d.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _d11Sans(
                          size: 15, weight: FontWeight.w500, spacing: 0.2)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(d.type.label,
                          style: _d11Sans(
                              size: 10,
                              color: _d11EucA(0.9),
                              weight: FontWeight.w600,
                              spacing: 0.5)),
                      const SizedBox(width: 8),
                      Text('·', style: _d11Sans(size: 10, color: _d11InkA(0.3))),
                      const SizedBox(width: 8),
                      Text('${d.author} · ${d.at.month}/${d.at.day}',
                          style: _d11Sans(size: 10, color: _d11InkA(0.5))),
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
                      style: TextStyle(fontSize: 15, color: _d11EucA(0.9)))
                  : Text('♡',
                      style: TextStyle(fontSize: 15, color: _d11InkA(0.22))),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================== bottom nav
class _D11Nav extends StatelessWidget {
  const _D11Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      decoration: const BoxDecoration(
        color: _d11Mist,
        border: Border(top: BorderSide(color: Color(0x1A26282B))),
      ),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
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
          Container(
            height: 1.5,
            width: 16,
            color: active ? _d11Euc : Colors.transparent,
          ),
          const SizedBox(height: 7),
          Text(label,
              style: _d11Sans(
                size: 12,
                color: active ? _d11Ink : _d11InkA(0.4),
                weight: active ? FontWeight.w600 : FontWeight.w400,
                spacing: 0.8,
              )),
        ],
      ),
    );
  }
}
