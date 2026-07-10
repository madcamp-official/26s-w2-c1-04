// design_18_pale_index — "Pale Index".
//
// The calm-tech grayscale sibling of Quiet Signal. Warm paper drained almost to
// neutral; memories filed down a single thin time-spine like plain library index
// cards, nothing competing for the eye. Plain grotesque, sentence-case,
// near-uniform weight — the most drained voice of the family.
//
// The ONE quiet signature: the only moving OR coloured thing is a hairline slate
// underline that draws itself left-to-right under a memory the moment you open
// it — a quiet "read" tick. No other motion, no other colour in the chrome.
//
// Self-contained: no external packages, no assets, no network, no Random,
// no DateTime.now(). Content imagery is emoji + softened swatch from demo data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ---------------------------------------------------------------- palette
const Color _d18Paper = Color(0xFFF2F2F0); // ground
const Color _d18Dim = Color(0xFFE9E9E6); // recessed panels
const Color _d18Card = Color(0xFFFAFAF9); // lifted index card
const Color _d18Ink = Color(0xFF26262A); // graphite
const Color _d18Slate = Color(0xFF7C828B); // faint accent — UNDERLINE ONLY

Color _d18InkA(double a) => _d18Ink.withOpacity(a);

// Drain a content swatch toward neutral so nothing shouts.
Color _d18Soften(Color c) => Color.lerp(c, _d18Dim, 0.6)!;

// Plain grotesque voice: sentence-case, near-uniform weight, lots of air.
TextStyle _d18Text({
  double size = 14,
  Color color = _d18Ink,
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

// small quiet section label
TextStyle _d18Label() =>
    _d18Text(size: 11, color: _d18InkA(0.45), weight: FontWeight.w500, spacing: 0.6);

class Design18 extends DesignVariant {
  @override
  String get id => '18';
  @override
  String get name => 'Pale Index';
  @override
  String get concept =>
      '웜페이퍼를 거의 중립까지 뺀 그레이스케일 자매 — 기억을 하나의 얇은 시간 척추를 따라 색인 카드처럼 정리한다. 한 번에 한 장만 켜진다.';
  @override
  String get signature =>
      '움직이거나 색이 있는 유일한 것: 기억을 여는 순간 그 캡션 아래로 왼쪽에서 오른쪽으로 스스로 그어지는 헤어라인 슬레이트 밑줄 — 조용한 "읽음" 표시. 그 외엔 어떤 모션도, 어떤 색도 없다.';
  @override
  String get inspiration =>
      'Calm-tech grayscale · library index cards · single time-spine timeline · a self-drawing read tick';
  @override
  Color get accent => _d18Slate;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d18Text(),
      child: switch (screen) {
        HeroScreen.drawSend => _D18DrawSend(data: data),
        HeroScreen.petHome => _D18PetHome(data: data),
        HeroScreen.memoryAlbum => _D18Album(data: data),
      },
    );
  }
}

// ============================================================ read underline
// The sole signature: a slate hairline that draws itself left-to-right the
// moment a memory is opened. It is the only motion and the only colour in the
// chrome — everything else is graphite on paper.
class _D18ReadUnderline extends StatefulWidget {
  const _D18ReadUnderline({
    required this.active,
    this.height = 1.5,
    this.color = _d18Slate,
  });
  final bool active;
  final double height;
  final Color color;
  @override
  State<_D18ReadUnderline> createState() => _D18ReadUnderlineState();
}

class _D18ReadUnderlineState extends State<_D18ReadUnderline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    if (widget.active) _c.forward();
  }

  @override
  void didUpdateWidget(covariant _D18ReadUnderline old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _c.forward();
    } else if (!widget.active && old.active) {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        return SizedBox(
          width: double.infinity,
          height: widget.height,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _a.value.clamp(0.0, 1.0),
              child: Container(
                height: widget.height,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

// a plain hairline rule
class _D18Hair extends StatelessWidget {
  const _D18Hair({this.opacity = 0.10});
  final double opacity;
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _d18InkA(opacity));
}

// ================================================================ Draw & Send
class _D18DrawSend extends StatefulWidget {
  const _D18DrawSend({required this.data});
  final AppData data;
  @override
  State<_D18DrawSend> createState() => _D18DrawSendState();
}

class _D18DrawSendState extends State<_D18DrawSend> {
  int pen = 0;
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    final ink = demoPenColors[pen];
    return Scaffold(
      backgroundColor: _d18Paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- top bar: back / recipient / send
              Row(
                children: [
                  _D18IconTap(
                    icon: Icons.arrow_back,
                    onTap: () => HapticFeedback.selectionClick(),
                  ),
                  const Spacer(),
                  // recipient — the read underline draws itself on open
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('받는 사람', style: _d18Label()),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 132,
                        child: Column(
                          children: [
                            Text(couple.partnerNickname,
                                textAlign: TextAlign.center,
                                style: _d18Text(
                                    size: 17, weight: FontWeight.w600, spacing: 0.2)),
                            const SizedBox(height: 6),
                            const _D18ReadUnderline(active: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _D18SendButton(onTap: () => HapticFeedback.selectionClick()),
                ],
              ),
              const SizedBox(height: 18),
              // ---- the canvas: a quiet ruled index sheet
              Expanded(child: _canvas(ink)),
              const SizedBox(height: 22),
              // ---- pen colours
              Text('펜', style: _d18Label()),
              const SizedBox(height: 12),
              _penRow(),
              const SizedBox(height: 20),
              // ---- thickness
              Row(
                children: [
                  Text('굵기', style: _d18Label()),
                  const Spacer(),
                  Text('${thickness.round()} px',
                      style: _d18Text(size: 11, color: _d18InkA(0.55))),
                ],
              ),
              const SizedBox(height: 10),
              _D18Thickness(
                value: thickness,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => thickness = v);
                },
              ),
              const SizedBox(height: 20),
              const _D18Hair(),
              const SizedBox(height: 16),
              // ---- mode toggle + description
              _D18Segment(
                labels: [SendMode.normal.label, SendMode.disappearing.label],
                index: mode.index,
                onTap: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => mode = SendMode.values[i]);
                },
                expand: true,
              ),
              const SizedBox(height: 10),
              Text(mode.description,
                  style: _d18Text(size: 12, color: _d18InkA(0.5))),
              const SizedBox(height: 18),
              // ---- quiet actions
              _bottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvas(Color ink) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _d18Card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _d18InkA(0.12)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _D18RulePainter())),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('여기에 오늘의 낙서',
                    style: _d18Text(size: 15, color: _d18InkA(0.32))),
                const SizedBox(height: 20),
                // a single stroke preview of the chosen ink + thickness
                Container(
                  width: 120,
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
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: demoPenColors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: pen == i ? _d18Ink : _d18InkA(0.14),
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

  Widget _bottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _D18Action(
            icon: Icons.photo_library_outlined,
            label: '갤러리',
            onTap: () => HapticFeedback.selectionClick()),
        _D18Action(
            icon: Icons.photo_camera_outlined,
            label: '사진',
            onTap: () => HapticFeedback.selectionClick()),
        _D18Action(
            icon: Icons.notifications_none_rounded,
            label: '찌르기',
            onTap: () => HapticFeedback.selectionClick()),
      ],
    );
  }
}

class _D18RulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _d18InkA(0.05)
      ..strokeWidth = 1;
    const gap = 30.0;
    for (double y = gap; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _D18IconTap extends StatelessWidget {
  const _D18IconTap({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: _d18InkA(0.7)),
      ),
    );
  }
}

class _D18SendButton extends StatelessWidget {
  const _D18SendButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _d18Ink,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('보내기',
            style: _d18Text(
                size: 13, color: _d18Paper, weight: FontWeight.w500, spacing: 0.3)),
      ),
    );
  }
}

// minimal thickness slider — graphite only, hairline track
class _D18Thickness extends StatelessWidget {
  const _D18Thickness({required this.value, required this.onChanged});
  final double value;
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
                Container(width: w, height: 1, color: _d18InkA(0.14)),
                Container(width: t * w, height: 1.5, color: _d18InkA(0.5)),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 3,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _d18Ink,
                      borderRadius: BorderRadius.circular(1),
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

// two-item segmented control (also used for album sort)
class _D18Segment extends StatelessWidget {
  const _D18Segment({
    required this.labels,
    required this.index,
    required this.onTap,
    this.expand = false,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    Widget seg(int i) {
      final on = i == index;
      final child = Container(
        padding: EdgeInsets.symmetric(
            horizontal: expand ? 0 : 12, vertical: expand ? 10 : 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? _d18Ink : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(labels[i],
            style: _d18Text(
              size: expand ? 13 : 11,
              color: on ? _d18Paper : _d18InkA(0.5),
              weight: on ? FontWeight.w500 : FontWeight.w400,
              spacing: 0.3,
            )),
      );
      final tap = GestureDetector(
        onTap: () => onTap(i),
        behavior: HitTestBehavior.opaque,
        child: child,
      );
      return expand ? Expanded(child: tap) : tap;
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _d18Dim,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (int i = 0; i < labels.length; i++) ...[
            seg(i),
            if (i != labels.length - 1) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }
}

class _D18Action extends StatelessWidget {
  const _D18Action(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
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
              color: _d18Dim,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _d18InkA(0.08)),
            ),
            child: Icon(icon, size: 22, color: _d18InkA(0.72)),
          ),
          const SizedBox(height: 8),
          Text(label, style: _d18Text(size: 11, color: _d18InkA(0.6))),
        ],
      ),
    );
  }
}

// ==================================================================== Pet Home
class _D18PetHome extends StatefulWidget {
  const _D18PetHome({required this.data});
  final AppData data;
  @override
  State<_D18PetHome> createState() => _D18PetHomeState();
}

class _D18PetHomeState extends State<_D18PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    return Scaffold(
      backgroundColor: _d18Paper,
      body: SafeArea(
        child: Column(
          children: [
            // ---- top bar: name · Lv / coins
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('우리 펫', style: _d18Label()),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(pet.name,
                              style: _d18Text(
                                  size: 20, weight: FontWeight.w600, spacing: 0.2)),
                          const SizedBox(width: 8),
                          Text('Lv.${pet.level}',
                              style: _d18Text(size: 12, color: _d18InkA(0.5))),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  _D18Coins(coins: pet.coins),
                ],
              ),
            ),
            // ---- the one lit subject: the pet on an index card
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // speech slip revealed on pat — read underline draws itself
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: patted
                          ? _D18SpeechSlip(text: pet.speech)
                          : const SizedBox(height: 46, key: ValueKey('empty')),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => patted = !patted);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 172,
                        height: 172,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _d18Card,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _d18InkA(0.12)),
                        ),
                        child: Text(pet.moodEmoji,
                            style: const TextStyle(fontSize: 82)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (equipped.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('착용', style: _d18Label()),
                          const SizedBox(width: 10),
                          for (final e in equipped) ...[
                            Text(e.emoji, style: const TextStyle(fontSize: 17)),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text('쓰다듬어 보세요',
                        style: _d18Text(size: 12, color: _d18InkA(0.4))),
                    const SizedBox(height: 26),
                    _D18Growth(growth: pet.growth),
                  ],
                ),
              ),
            ),
            // ---- store
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: Row(
                children: [
                  Text('스토어', style: _d18Label()),
                  const Spacer(),
                  Text('전체보기',
                      style: _d18Text(size: 11, color: _d18InkA(0.4))),
                ],
              ),
            ),
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: pet.store.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _D18StoreCard(
                  item: pet.store[i],
                  onTap: () => HapticFeedback.selectionClick(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _D18Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

class _D18Coins extends StatelessWidget {
  const _D18Coins({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _d18Dim,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _d18InkA(0.4), width: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          Text('$coins',
              style: _d18Text(size: 13, weight: FontWeight.w500, spacing: 0.2)),
        ],
      ),
    );
  }
}

class _D18SpeechSlip extends StatelessWidget {
  const _D18SpeechSlip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('speech'),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _d18Card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _d18InkA(0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              textAlign: TextAlign.center,
              style: _d18Text(size: 13, weight: FontWeight.w500)),
          const SizedBox(height: 6),
          const SizedBox(width: 140, child: _D18ReadUnderline(active: true)),
        ],
      ),
    );
  }
}

class _D18Growth extends StatelessWidget {
  const _D18Growth({required this.growth});
  final double growth;
  @override
  Widget build(BuildContext context) {
    final pct = (growth * 100).round();
    return SizedBox(
      width: 230,
      child: Column(
        children: [
          Row(
            children: [
              Text('다음 레벨',
                  style: _d18Text(size: 11, color: _d18InkA(0.5))),
              const Spacer(),
              Text('$pct%', style: _d18Text(size: 11, color: _d18InkA(0.55))),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return Stack(
                children: [
                  Container(width: w, height: 3, color: _d18InkA(0.10)),
                  Container(
                      width: w * growth.clamp(0.0, 1.0),
                      height: 3,
                      color: _d18Ink),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _D18StoreCard extends StatelessWidget {
  const _D18StoreCard({required this.item, required this.onTap});
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
          color: _d18Card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: item.equipped ? _d18InkA(0.55) : _d18InkA(0.10),
            width: item.equipped ? 1.4 : 1,
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
                style: _d18Text(size: 11)),
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
          style: _d18Text(size: 10, color: _d18Ink, weight: FontWeight.w500));
    }
    if (it.owned) {
      return Text('보유', style: _d18Text(size: 10, color: _d18InkA(0.45)));
    }
    return Text('◦ ${it.price}',
        style: _d18Text(size: 10, color: _d18InkA(0.6)));
  }
}

// ================================================================ Memory Album
class _D18Album extends StatefulWidget {
  const _D18Album({required this.data});
  final AppData data;
  @override
  State<_D18Album> createState() => _D18AlbumState();
}

class _D18AlbumState extends State<_D18Album> {
  bool byDate = true;
  DoodleType? filter;
  late String selectedId = widget.data.album.first.id;

  @override
  Widget build(BuildContext context) {
    final items =
        widget.data.album.where((d) => filter == null || d.type == filter).toList();
    // keep exactly one card lit at a time
    final effectiveSelected = items.any((d) => d.id == selectedId)
        ? selectedId
        : (items.isNotEmpty ? items.first.id : '');

    return Scaffold(
      backgroundColor: _d18Paper,
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
                      Text('기록', style: _d18Label()),
                      const SizedBox(height: 4),
                      Text('낙서 사진첩',
                          style: _d18Text(
                              size: 20, weight: FontWeight.w600, spacing: 0.2)),
                    ],
                  ),
                  const Spacer(),
                  _D18Segment(
                    labels: const ['날짜별', '유형별'],
                    index: byDate ? 0 : 1,
                    onTap: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => byDate = i == 0);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ---- type filters
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _D18FilterChip(
                    label: '전체',
                    selected: filter == null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => filter = null);
                    },
                  ),
                  for (final t in DoodleType.values)
                    _D18FilterChip(
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
            const SizedBox(height: 8),
            // ---- the time-spine: memories filed down one thin line
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final d = items[i];
                  return _D18SpineRow(
                    key: ValueKey(d.id),
                    doodle: d,
                    selected: d.id == effectiveSelected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => selectedId = d.id);
                    },
                  );
                },
              ),
            ),
            const _D18Nav(current: 1),
          ],
        ),
      ),
    );
  }
}

class _D18FilterChip extends StatelessWidget {
  const _D18FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? _d18Dim : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: selected ? _d18InkA(0.5) : _d18InkA(0.14),
            ),
          ),
          child: Text(label,
              style: _d18Text(
                size: 11,
                color: selected ? _d18Ink : _d18InkA(0.5),
                weight: selected ? FontWeight.w500 : FontWeight.w400,
                spacing: 0.3,
              )),
        ),
      ),
    );
  }
}

// one memory filed on the time-spine; the lit one draws its read underline
class _D18SpineRow extends StatelessWidget {
  const _D18SpineRow({
    super.key,
    required this.doodle,
    required this.selected,
    required this.onTap,
  });
  final Doodle doodle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- the spine gutter: continuous hairline + a node
            SizedBox(
              width: 26,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // continuous vertical time-spine, full row height
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 12.5,
                    child: SizedBox(
                      width: 1,
                      child: ColoredBox(color: _d18InkA(0.12)),
                    ),
                  ),
                  // node — filled when lit, hollow otherwise
                  Container(
                    width: selected ? 9 : 7,
                    height: selected ? 9 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? _d18Ink : _d18Paper,
                      border: Border.all(
                        color: selected ? _d18Ink : _d18InkA(0.3),
                        width: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ---- the index card content
            Expanded(
              child: Opacity(
                opacity: selected ? 1 : 0.6,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? _d18Card : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: selected ? _d18InkA(0.12) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // softened swatch + emoji
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              _d18Soften(d.swatch.first),
                              _d18Soften(d.swatch.last),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: _d18InkA(0.08)),
                        ),
                        child: Text(d.emoji, style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _d18Text(
                                    size: 15,
                                    weight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    spacing: 0.1)),
                            const SizedBox(height: 6),
                            // THE SIGNATURE — read underline draws on open
                            _D18ReadUnderline(active: selected),
                            const SizedBox(height: 6),
                            Text(
                              '${d.type.label} · ${d.author} · ${d.at.month}/${d.at.day}',
                              style: _d18Text(size: 11, color: _d18InkA(0.5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // liked — graphite only, never coloured
                      Icon(
                        d.liked ? Icons.favorite : Icons.favorite_border,
                        size: 15,
                        color: d.liked ? _d18InkA(0.7) : _d18InkA(0.25),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================== bottom nav
class _D18Nav extends StatelessWidget {
  const _D18Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      decoration: BoxDecoration(
        color: _d18Paper,
        border: Border(top: BorderSide(color: _d18InkA(0.10))),
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
          SizedBox(
            height: 6,
            child: active
                ? Container(
                    width: 5,
                    height: 5,
                    decoration:
                        const BoxDecoration(color: _d18Ink, shape: BoxShape.circle),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(label,
              style: _d18Text(
                size: 12,
                color: active ? _d18Ink : _d18InkA(0.4),
                weight: active ? FontWeight.w600 : FontWeight.w400,
                spacing: 0.3,
              )),
        ],
      ),
    );
  }
}
