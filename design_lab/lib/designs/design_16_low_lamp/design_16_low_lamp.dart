// design_16_low_lamp — "Low Lamp".
//
// The one dark sibling of Quiet Signal — the app you open after the day.
// A single memory lit as if by one dim desk lamp on a warm near-black ground.
// Low-stimulus by construction: hairline sans, one large quiet line per screen,
// everything centered in deep dark space. The ONE signature is a soft lamp-halo
// that breathes behind the single lit element — a very slow (~7s) swell of warm
// light, then settles. Nothing else on screen ever glows.
//
// Self-contained: no external packages, no assets, no network, no Random,
// no DateTime.now(). Imagery is gradient + emoji from shared demo data.

import 'package:flutter/material.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ---------------------------------------------------------------- palette
const Color _d16Ink = Color(0xFF16171B); // ground: warm near-black ink-blue
const Color _d16Dim = Color(0xFF1E2026); // dim raised surface
const Color _d16Bone = Color(0xFFE7E1D4); // warm bone text
const Color _d16Ember = Color(0xFFC79A5E); // dim amber ember accent (held low)

Color _d16BoneA(double a) => _d16Bone.withOpacity(a);
Color _d16EmberA(double a) => _d16Ember.withOpacity(a);

// Restrained hairline-weight sans — nocturnal, soft, no mono chatter.
TextStyle _d16Text({
  double size = 15,
  Color? color,
  FontWeight weight = FontWeight.w300,
  double spacing = 0.3,
  double height = 1.4,
}) =>
    TextStyle(
      fontSize: size,
      color: color ?? _d16Bone,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

// tiny spaced eyebrow in dim ember — the only "label voice".
TextStyle _d16Eyebrow() => _d16Text(
      size: 10,
      color: _d16EmberA(0.72),
      weight: FontWeight.w400,
      spacing: 2.6,
    );

// gradient + emoji stand-in for a memory, muted for the dark ground by caller.
Widget _d16Swatch(Doodle d, double s) => Container(
      width: s,
      height: s,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          colors: d.swatch,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(d.emoji, style: TextStyle(fontSize: s * 0.44)),
    );

// a 1px hairline, the quiet seam between things.
class _D16Hair extends StatelessWidget {
  const _D16Hair({this.opacity = 0.08});
  final double opacity;
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _d16BoneA(opacity));
}

class Design16 extends DesignVariant {
  @override
  String get id => '16';
  @override
  String get name => 'Low Lamp';
  @override
  String get concept =>
      '하루가 끝난 뒤 켜는 앱 — 따뜻한 근흑색 바탕 위에 단 하나의 기억만 흐린 스탠드 불빛처럼 밝힌다. 구조 자체가 저자극이라 밤 11시의 눈에 편안하다.';
  @override
  String get signature =>
      '단 하나의 기억 뒤에서 숨 쉬는 부드러운 램프 헤일로 — 약 7초에 걸쳐 따뜻한 빛이 천천히 부풀었다 가라앉는다. 화면의 그 무엇도 함께 빛나지 않는다.';
  @override
  String get inspiration =>
      'One dim desk lamp at night · warm-dark restraint · a single lit object in deep space';
  @override
  Color get accent => _d16Ember;
  @override
  Brightness get brightness => Brightness.dark;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d16Text(),
      child: switch (screen) {
        HeroScreen.drawSend => _D16DrawSend(data: data),
        HeroScreen.petHome => _D16PetHome(data: data),
        HeroScreen.memoryAlbum => _D16Album(data: data),
      },
    );
  }
}

// ============================================================ the lone signature
// One soft lamp-halo that breathes behind the single lit element. Very slow
// warm swell, then settles. This is the ONLY thing on screen that glows.
class _D16LampHalo extends StatefulWidget {
  const _D16LampHalo({this.size = 320, this.intensity = 1.0});
  final double size;
  final double intensity;
  @override
  State<_D16LampHalo> createState() => _D16LampHaloState();
}

class _D16LampHaloState extends State<_D16LampHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat(reverse: true);
    _t = CurvedAnimation(parent: _c, curve: Curves.easeInOutSine);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _t,
        builder: (_, __) {
          final v = _t.value; // 0..1, breathing
          final glow = (0.10 + 0.15 * v) * widget.intensity;
          final scale = 0.92 + 0.12 * v;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _d16EmberA(glow),
                    _d16EmberA(glow * 0.42),
                    _d16EmberA(0.0),
                  ],
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================================================================== Draw & Send
class _D16DrawSend extends StatefulWidget {
  const _D16DrawSend({required this.data});
  final AppData data;
  @override
  State<_D16DrawSend> createState() => _D16DrawSendState();
}

class _D16DrawSendState extends State<_D16DrawSend> {
  int pen = 2;
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    return Scaffold(
      backgroundColor: _d16Ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- top bar: back / recipient / send
              Row(
                children: [
                  _D16IconTap(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {},
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text('TO', style: _d16Eyebrow()),
                      const SizedBox(height: 4),
                      Text(
                        couple.partnerNickname,
                        style: _d16Text(
                            size: 16, weight: FontWeight.w400, spacing: 1),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _D16GhostButton(label: '보내기', onTap: () {}),
                ],
              ),
              const SizedBox(height: 12),
              // ---- the lit canvas: one memory under the lamp
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const _D16LampHalo(size: 340),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: _d16Bone.withOpacity(0.015),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _d16BoneA(0.08)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '오늘 하나를',
                              style: _d16Text(
                                  size: 24,
                                  weight: FontWeight.w200,
                                  color: _d16BoneA(0.9),
                                  spacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '천천히 그려요',
                              style: _d16Text(
                                  size: 24,
                                  weight: FontWeight.w200,
                                  color: _d16BoneA(0.55),
                                  spacing: 0.5),
                            ),
                            const SizedBox(height: 30),
                            // a single stroke preview in the chosen ink
                            Container(
                              width: 96,
                              height: thickness.clamp(2, 20).toDouble(),
                              decoration: BoxDecoration(
                                color: demoPenColors[pen].withOpacity(0.9),
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // ---- pen colors
              Text('잉크', style: _d16Eyebrow()),
              const SizedBox(height: 12),
              _penRow(),
              const SizedBox(height: 20),
              // ---- thickness
              Row(
                children: [
                  Text('굵기', style: _d16Eyebrow()),
                  const Spacer(),
                  Text('${thickness.round()}',
                      style: _d16Text(size: 11, color: _d16EmberA(0.9))),
                ],
              ),
              const SizedBox(height: 8),
              _D16Thickness(
                value: thickness,
                color: demoPenColors[pen],
                onChanged: (v) => setState(() => thickness = v),
              ),
              const SizedBox(height: 18),
              const _D16Hair(),
              const SizedBox(height: 16),
              // ---- mode toggle + description
              _modeToggle(),
              const SizedBox(height: 10),
              Text(mode.description,
                  style: _d16Text(size: 12, color: _d16BoneA(0.5))),
              const SizedBox(height: 18),
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
          GestureDetector(
            onTap: () => setState(() => pen = i),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: pen == i ? _d16EmberA(0.9) : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: demoPenColors[i].withOpacity(0.82),
                  shape: BoxShape.circle,
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
    Widget tab(SendMode m) {
      final on = mode == m;
      return GestureDetector(
        onTap: () => setState(() => mode = m),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              m.label,
              style: _d16Text(
                size: 14,
                color: on ? _d16Bone : _d16BoneA(0.38),
                weight: on ? FontWeight.w400 : FontWeight.w300,
                spacing: 0.8,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              height: 1.5,
              width: 44,
              color: on ? _d16EmberA(0.85) : _d16BoneA(0.06),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        for (final m in SendMode.values) ...[
          tab(m),
          if (m != SendMode.values.last) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _actions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _D16Action(icon: Icons.image_outlined, label: '갤러리', onTap: () {}),
        _D16Action(
            icon: Icons.photo_camera_outlined, label: '사진', onTap: () {}),
        _D16Action(
            icon: Icons.touch_app_outlined,
            label: '찌르기',
            accent: true,
            onTap: () {}),
      ],
    );
  }
}

class _D16IconTap extends StatelessWidget {
  const _D16IconTap({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 17, color: _d16BoneA(0.65)),
      ),
    );
  }
}

class _D16GhostButton extends StatelessWidget {
  const _D16GhostButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _d16EmberA(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: _d16Text(
                    size: 12, color: _d16Ember, weight: FontWeight.w400)),
            const SizedBox(width: 7),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: _d16EmberA(0.85),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _D16Action extends StatelessWidget {
  const _D16Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    final c = accent ? _d16Ember : _d16BoneA(0.7);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ? _d16EmberA(0.08) : _d16Dim,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: accent ? _d16EmberA(0.4) : _d16BoneA(0.07)),
            ),
            child: Icon(icon, size: 20, color: c),
          ),
          const SizedBox(height: 8),
          Text(label, style: _d16Text(size: 10, color: c, spacing: 1)),
        ],
      ),
    );
  }
}

// custom minimal thickness slider — hairline track, ember fill, ink-dot thumb.
class _D16Thickness extends StatelessWidget {
  const _D16Thickness({
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
        final dot = value.clamp(6, 22).toDouble();
        return GestureDetector(
          onTapDown: (d) => update(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 28,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(width: w, height: 1, color: _d16BoneA(0.12)),
                Container(width: t * w, height: 1.5, color: _d16EmberA(0.65)),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: dot,
                    height: dot,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.88),
                      shape: BoxShape.circle,
                      border: Border.all(color: _d16BoneA(0.22)),
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

// ==================================================================== Pet Home
class _D16PetHome extends StatefulWidget {
  const _D16PetHome({required this.data});
  final AppData data;
  @override
  State<_D16PetHome> createState() => _D16PetHomeState();
}

class _D16PetHomeState extends State<_D16PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    return Scaffold(
      backgroundColor: _d16Ink,
      body: SafeArea(
        child: Column(
          children: [
            // ---- top bar: name + Lv / coins
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('우리 펫', style: _d16Eyebrow()),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(pet.name,
                              style: _d16Text(
                                  size: 20, weight: FontWeight.w300, spacing: 1)),
                          const SizedBox(width: 9),
                          Text('Lv.${pet.level}',
                              style: _d16Text(
                                  size: 12, color: _d16EmberA(0.9))),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  _D16Coins(coins: pet.coins),
                ],
              ),
            ),
            // ---- the lit subject: the pet under the lamp
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // speech, revealed on pat
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: patted
                          ? _D16SpeechSlip(text: pet.speech)
                          : const SizedBox(height: 46, key: ValueKey('empty')),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => setState(() => patted = !patted),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const _D16LampHalo(size: 240),
                            Text(pet.moodEmoji,
                                style: const TextStyle(fontSize: 84)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('쓰다듬으면 말을 해요',
                        style: _d16Text(size: 12, color: _d16BoneA(0.42))),
                    if (equipped.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('착용', style: _d16Eyebrow()),
                          const SizedBox(width: 12),
                          for (final e in equipped) ...[
                            Text(e.emoji, style: const TextStyle(fontSize: 17)),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    _D16Growth(growth: pet.growth),
                  ],
                ),
              ),
            ),
            // ---- store
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Text('스토어', style: _d16Eyebrow()),
                  const Spacer(),
                  Text('전체보기',
                      style: _d16Text(size: 10, color: _d16BoneA(0.4))),
                ],
              ),
            ),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: pet.store.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _D16StoreCard(item: pet.store[i]),
              ),
            ),
            const SizedBox(height: 8),
            const _D16Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

class _D16Coins extends StatelessWidget {
  const _D16Coins({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: _d16Dim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _d16BoneA(0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: _d16EmberA(0.85)),
          const SizedBox(width: 8),
          Text('$coins',
              style: _d16Text(size: 12, weight: FontWeight.w400, spacing: 0.5)),
        ],
      ),
    );
  }
}

class _D16SpeechSlip extends StatelessWidget {
  const _D16SpeechSlip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('speech'),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _d16Dim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _d16EmberA(0.35)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: _d16Text(size: 13, weight: FontWeight.w300),
      ),
    );
  }
}

class _D16Growth extends StatelessWidget {
  const _D16Growth({required this.growth});
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
                  style: _d16Text(size: 10, color: _d16BoneA(0.5), spacing: 1)),
              const Spacer(),
              Text('$pct%',
                  style: _d16Text(size: 11, color: _d16EmberA(0.9))),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return Stack(
                  children: [
                    Container(width: w, height: 3, color: _d16BoneA(0.1)),
                    Container(
                      width: w * growth.clamp(0.0, 1.0),
                      height: 3,
                      color: _d16EmberA(0.85),
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

class _D16StoreCard extends StatelessWidget {
  const _D16StoreCard({required this.item});
  final PetItem item;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: _d16Dim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.equipped ? _d16EmberA(0.45) : _d16BoneA(0.06),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.92,
            child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 8),
          Text(item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _d16Text(size: 11, weight: FontWeight.w300)),
          const SizedBox(height: 6),
          _status(item),
        ],
      ),
    );
  }

  Widget _status(PetItem it) {
    if (it.equipped) {
      return Text('착용중',
          style: _d16Text(size: 9, color: _d16EmberA(0.9), spacing: 0.8));
    }
    if (it.owned) {
      return Text('보유',
          style: _d16Text(size: 9, color: _d16BoneA(0.45), spacing: 0.8));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 6, color: _d16EmberA(0.7)),
        const SizedBox(width: 5),
        Text('${it.price}',
            style: _d16Text(size: 9, color: _d16BoneA(0.6), spacing: 0.5)),
      ],
    );
  }
}

// ================================================================ Memory Album
class _D16Album extends StatefulWidget {
  const _D16Album({required this.data});
  final AppData data;
  @override
  State<_D16Album> createState() => _D16AlbumState();
}

class _D16AlbumState extends State<_D16Album> {
  bool byDate = true;
  DoodleType? filter;

  @override
  Widget build(BuildContext context) {
    final all = widget.data.album;
    final items =
        all.where((d) => filter == null || d.type == filter).toList();
    final featured =
        all.firstWhere((d) => d.liked, orElse: () => all.first);
    return Scaffold(
      backgroundColor: _d16Ink,
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
                      Text('기록', style: _d16Eyebrow()),
                      const SizedBox(height: 5),
                      Text('낙서 사진첩',
                          style: _d16Text(
                              size: 20, weight: FontWeight.w300, spacing: 0.8)),
                    ],
                  ),
                  const Spacer(),
                  _D16SortToggle(
                    byDate: byDate,
                    onTap: () => setState(() => byDate = !byDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ---- one lit memory under the lamp
            SizedBox(
              height: 148,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _D16LampHalo(size: 220, intensity: 0.9),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _featured(featured),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // ---- type filters
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _D16FilterChip(
                    label: '전체',
                    selected: filter == null,
                    onTap: () => setState(() => filter = null),
                  ),
                  for (final t in DoodleType.values)
                    _D16FilterChip(
                      label: t.label,
                      selected: filter == t,
                      onTap: () => setState(() => filter = t),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // ---- the quiet log
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 3),
                  child: _D16Hair(),
                ),
                itemBuilder: (_, i) => _D16MemoryRow(doodle: items[i]),
              ),
            ),
            const _D16Nav(current: 1),
          ],
        ),
      ),
    );
  }

  Widget _featured(Doodle d) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _d16Bone.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _d16BoneA(0.09)),
      ),
      child: Row(
        children: [
          Opacity(opacity: 0.82, child: _d16Swatch(d, 60)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘 밤 켜 둔 기억', style: _d16Eyebrow()),
                const SizedBox(height: 8),
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d16Text(size: 17, weight: FontWeight.w300)),
                const SizedBox(height: 5),
                Text('${d.author} · ${d.at.month}/${d.at.day}',
                    style: _d16Text(size: 11, color: _d16BoneA(0.5))),
              ],
            ),
          ),
          if (d.liked)
            Icon(Icons.favorite, size: 15, color: _d16EmberA(0.9)),
        ],
      ),
    );
  }
}

class _D16SortToggle extends StatelessWidget {
  const _D16SortToggle({required this.byDate, required this.onTap});
  final bool byDate;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: on ? _d16EmberA(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(label,
              style: _d16Text(
                size: 10,
                color: on ? _d16Ember : _d16BoneA(0.42),
                spacing: 0.8,
              )),
        );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _d16BoneA(0.1)),
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

class _D16FilterChip extends StatelessWidget {
  const _D16FilterChip({
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
            color: selected ? _d16EmberA(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _d16EmberA(0.45) : _d16BoneA(0.1),
            ),
          ),
          child: Text(label,
              style: _d16Text(
                size: 11,
                color: selected ? _d16Ember : _d16BoneA(0.55),
                weight: FontWeight.w300,
                spacing: 0.6,
              )),
        ),
      ),
    );
  }
}

class _D16MemoryRow extends StatelessWidget {
  const _D16MemoryRow({required this.doodle});
  final Doodle doodle;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // subtle swatch — muted for the dark ground
          Opacity(opacity: 0.62, child: _d16Swatch(d, 46)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d16Text(size: 14, weight: FontWeight.w300)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(d.type.label,
                        style:
                            _d16Text(size: 10, color: _d16EmberA(0.8))),
                    const SizedBox(width: 8),
                    Text('·', style: _d16Text(size: 10, color: _d16BoneA(0.3))),
                    const SizedBox(width: 8),
                    Text('${d.author} · ${d.at.month}/${d.at.day}',
                        style: _d16Text(size: 10, color: _d16BoneA(0.5))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            d.liked ? Icons.favorite : Icons.favorite_border,
            size: 15,
            color: d.liked ? _d16EmberA(0.9) : _d16BoneA(0.22),
          ),
        ],
      ),
    );
  }
}

// ==================================================================== bottom nav
class _D16Nav extends StatelessWidget {
  const _D16Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      decoration: BoxDecoration(
        color: _d16Ink,
        border: Border(top: BorderSide(color: _d16BoneA(0.07))),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 8,
          child: active
              ? Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _d16EmberA(0.9),
                    shape: BoxShape.circle,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: _d16Text(
              size: 11,
              color: active ? _d16Bone : _d16BoneA(0.38),
              weight: active ? FontWeight.w400 : FontWeight.w300,
              spacing: 1,
            )),
      ],
    );
  }
}
