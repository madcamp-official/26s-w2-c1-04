// design_15_dateline — "Dateline".
//
// A quiet couple's gazette: the day's memory set as a calm newspaper — a thin
// running masthead over one single lead-story column. The only ink-only sibling
// of Quiet Signal: pure two-tone, no chroma anywhere, warmth carried entirely by
// the warm newsprint. The lone typographic mark is a single hairline column rule
// paired with a small-caps dateline stamp ( · 화요일 · 07.10 · ) setting each
// screen. Memory imagery prints as a warm duotone ink plate, the way a paper
// prints a photograph.
//
// Self-contained: Material/widgets only, no packages, no assets, no network,
// no Random, no DateTime.now(). Imagery = duotone(swatch) + emoji from demo data.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

// ---------------------------------------------------------------- palette (ink-only)
const Color _d15News = Color(0xFFEFEBE3); // ground · newsprint
const Color _d15Dim = Color(0xFFE5E0D5); // dim · pressed / secondary paper
const Color _d15Ink = Color(0xFF262523); // press-black
const Color _d15Card = Color(0xFFF4F0E8); // slightly brighter leaf for plates

Color _d15InkA(double a) => _d15Ink.withOpacity(a);

// ---------------------------------------------------------------- type
// Condensed news slab for the masthead / headlines.
TextStyle _d15Slab({
  double size = 24,
  Color color = _d15Ink,
  FontWeight weight = FontWeight.w800,
  double spacing = -0.3,
  double height = 1.02,
}) =>
    TextStyle(
      fontFamily: 'serif',
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

// Small-caps mono dateline / eyebrows / bylines.
TextStyle _d15Stamp({
  double size = 10,
  Color color = _d15Ink,
  FontWeight weight = FontWeight.w600,
  double spacing = 2.4,
}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: 1.3,
    );

// Quiet sans body.
TextStyle _d15Body({
  double size = 14,
  Color color = _d15Ink,
  FontWeight weight = FontWeight.w400,
  double spacing = 0.2,
  double height = 1.5,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

// ---------------------------------------------------------------- helpers
const List<String> _d15Weekday = ['', '월', '화', '수', '목', '금', '토', '일'];

// The dateline stamp — the lone typographic mark.  · 화요일 · 07.10 ·
String _d15Dateline(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '· ${_d15Weekday[d.weekday]}요일 · $mm.$dd ·';
}

// "Today" = the most recent memory's date (deterministic; no DateTime.now()).
DateTime _d15Today(AppData data) {
  var t = data.album.first.at;
  for (final d in data.album) {
    if (d.at.isAfter(t)) t = d.at;
  }
  return t;
}

// Print a swatch colour as a warm duotone ink tone (paper → press-black).
Color _d15Tone(Color c) {
  final l = c.computeLuminance();
  final ink = (0.50 - l * 0.40).clamp(0.06, 0.50).toDouble();
  return Color.lerp(_d15News, _d15Ink, ink)!;
}

// ============================================================================
class Design15 extends DesignVariant {
  @override
  String get id => '15';
  @override
  String get name => 'Dateline';
  @override
  String get concept =>
      '조용한 커플 가제트 — 하루의 기억을 차분한 신문 한 장으로. 얇은 러닝 마스트헤드 아래 단 하나의 리드 칼럼. 유일한 잉크-온리 형제, 온기는 오직 종이가 낸다.';
  @override
  String get signature =>
      '하나의 헤어라인 칼럼 룰과 작은 소문자 데이트라인 스탬프( · 화요일 · 07.10 · )가 매 화면을 조판한다 — 색은 어디에도 없고, 이것이 유일한 타이포 표식이다.';
  @override
  String get inspiration =>
      'Two-tone letterpress newsprint · masthead + single lead column · duotone photo plates';
  @override
  Color get accent => _d15Ink; // ink-only: the chip carries press-black, no chroma
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return DefaultTextStyle(
      style: _d15Body(),
      child: switch (screen) {
        HeroScreen.drawSend => _D15DrawSend(data: data),
        HeroScreen.petHome => _D15PetHome(data: data),
        HeroScreen.memoryAlbum => _D15Album(data: data),
      },
    );
  }
}

// ============================================================ shared chrome
// The thin running masthead: wordmark flanked by hairlines, then a
// section | dateline-stamp | edition strip, closed by the masthead rule.
class _D15Masthead extends StatelessWidget {
  const _D15Masthead({
    required this.section,
    required this.edition,
    required this.date,
    this.trailing,
  });
  final String section;
  final int edition;
  final DateTime date;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Column(
        children: [
          // running row: leading · (air) · trailing
          SizedBox(
            height: 26,
            child: Row(
              children: [
                const _D15Back(),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: 10),
          // wordmark flanked by hairlines
          Row(
            children: [
              Expanded(child: Container(height: 1, color: _d15InkA(0.30))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('DATELINE',
                    style: _d15Slab(
                        size: 30, weight: FontWeight.w900, spacing: 1.5)),
              ),
              Expanded(child: Container(height: 1, color: _d15InkA(0.30))),
            ],
          ),
          const SizedBox(height: 10),
          // section | dateline stamp | edition
          Row(
            children: [
              Expanded(
                child: Text(section.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d15Stamp(size: 9, color: _d15InkA(0.6))),
              ),
              Text(_d15Dateline(date),
                  style: _d15Stamp(size: 10, spacing: 2.2)),
              Expanded(
                child: Text('제 $edition 호',
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d15Stamp(size: 9, color: _d15InkA(0.6))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // the masthead rule — the one strong horizontal line
          Container(height: 1.4, color: _d15InkA(0.85)),
        ],
      ),
    );
  }
}

class _D15Back extends StatelessWidget {
  const _D15Back();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      behavior: HitTestBehavior.opaque,
      child: Icon(Icons.arrow_back, size: 20, color: _d15InkA(0.75)),
    );
  }
}

// The single lead-story column: one hairline column rule down the left.
class _D15Story extends StatelessWidget {
  const _D15Story({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: _d15InkA(0.32), width: 1)),
        ),
        padding: const EdgeInsets.only(left: 16),
        child: child,
      ),
    );
  }
}

class _D15Hair extends StatelessWidget {
  const _D15Hair();
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: _d15InkA(0.14));
}

// Small spaced section eyebrow, e.g. "오늘의 편지 · LETTERS".
class _D15Eyebrow extends StatelessWidget {
  const _D15Eyebrow(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: _d15Stamp(size: 9, color: _d15InkA(0.55), spacing: 2.6));
}

// A duotone ink plate — a memory printed the way a paper prints a photo.
class _D15Plate extends StatelessWidget {
  const _D15Plate({
    required this.doodle,
    required this.size,
    this.emojiSize = 26,
  });
  final Doodle doodle;
  final double size;
  final double emojiSize;
  @override
  Widget build(BuildContext context) {
    final tones = doodle.swatch.map(_d15Tone).toList();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d15InkA(0.22)),
        gradient: LinearGradient(
          colors: tones,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(doodle.emoji, style: TextStyle(fontSize: emojiSize)),
    );
  }
}

// Bottom nav — labels underlined by a short ink stamp when active.
class _D15Nav extends StatelessWidget {
  const _D15Nav({required this.current});
  final int current;
  @override
  Widget build(BuildContext context) {
    const labels = ['펫키우기', '사진첩', '소통'];
    return Container(
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: _d15InkA(0.85), width: 1.2))),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => HapticFeedback.selectionClick(),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 4,
                    child: i == current
                        ? Container(
                            width: 18,
                            height: 3,
                            color: _d15Ink,
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 7),
                  Text(labels[i],
                      style: _d15Stamp(
                        size: 11,
                        color: i == current ? _d15Ink : _d15InkA(0.4),
                        weight:
                            i == current ? FontWeight.w700 : FontWeight.w500,
                        spacing: 1.6,
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ================================================================== Draw & Send
class _D15DrawSend extends StatefulWidget {
  const _D15DrawSend({required this.data});
  final AppData data;
  @override
  State<_D15DrawSend> createState() => _D15DrawSendState();
}

class _D15DrawSendState extends State<_D15DrawSend> {
  int pen = 0;
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    return Scaffold(
      backgroundColor: _d15News,
      body: SafeArea(
        child: Column(
          children: [
            _D15Masthead(
              section: 'TO · ${couple.partnerNickname}',
              edition: couple.streakDays,
              date: _d15Today(widget.data),
              trailing: _D15SendButton(
                onTap: () => HapticFeedback.mediumImpact(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _D15Story(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // lead headline: the addressed edition
                    const _D15Eyebrow('오늘의 편지 · LETTERS'),
                    const SizedBox(height: 8),
                    Text('${couple.partnerNickname}에게 부치는 한 조각',
                        style: _d15Slab(size: 23, weight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('오늘을 적어 마감 전에 부치세요.',
                        style: _d15Body(size: 12, color: _d15InkA(0.55))),
                    const SizedBox(height: 14),
                    // the composing plate (canvas)
                    Expanded(child: _canvas()),
                    const SizedBox(height: 18),
                    // ink palette
                    Row(
                      children: [
                        const _D15Eyebrow('잉크 · INK'),
                        const Spacer(),
                        _penRow(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // weight
                    Row(
                      children: [
                        const _D15Eyebrow('굵기 · WEIGHT'),
                        const Spacer(),
                        Text('${thickness.round()} pt',
                            style: _d15Stamp(size: 10, color: _d15InkA(0.6))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _D15Thickness(
                      value: thickness,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => thickness = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    const _D15Hair(),
                    const SizedBox(height: 14),
                    // publishing mode
                    const _D15Eyebrow('발행 방식 · ISSUE'),
                    const SizedBox(height: 10),
                    _modeTabs(),
                    const SizedBox(height: 8),
                    Text(mode.description,
                        style: _d15Body(size: 12, color: _d15InkA(0.55))),
                    const SizedBox(height: 16),
                    // desk actions
                    _actions(),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _canvas() {
    final ink = demoPenColors[pen];
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 150),
      decoration: BoxDecoration(
        color: _d15Card,
        border: Border.all(color: _d15InkA(0.22)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _D15RulePainter())),
          const Positioned(
            top: 12,
            left: 14,
            child: _D15Eyebrow('· 칼럼 · 오늘'),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('여기에 오늘을 적어요',
                    style: _d15Body(size: 14, color: _d15InkA(0.38))),
                const SizedBox(height: 16),
                // stroke preview — the one bit of real ink on the page
                Container(
                  width: 120,
                  height: thickness.clamp(2.0, 20.0),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < demoPenColors.length; i++) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => pen = i);
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: demoPenColors[i],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: pen == i ? _d15Ink : _d15InkA(0.2),
                      width: pen == i ? 1.6 : 1,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 3,
                  child: pen == i
                      ? Container(width: 12, height: 3, color: _d15Ink)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (i != demoPenColors.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _modeTabs() {
    return Row(
      children: [
        for (final m in SendMode.values) ...[
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => mode = m);
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.label,
                    style: _d15Slab(
                      size: 17,
                      color: mode == m ? _d15Ink : _d15InkA(0.4),
                      weight:
                          mode == m ? FontWeight.w800 : FontWeight.w600,
                    )),
                const SizedBox(height: 6),
                Container(
                  height: 2,
                  width: 52,
                  color: mode == m ? _d15Ink : _d15InkA(0.1),
                ),
              ],
            ),
          ),
          if (m != SendMode.values.last) const SizedBox(width: 18),
        ],
      ],
    );
  }

  Widget _actions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _D15Action(glyph: '🖼', label: '갤러리'),
        _D15Action(glyph: '📷', label: '사진'),
        _D15Action(glyph: '🔔', label: '찌르기', emphatic: true),
      ],
    );
  }
}

class _D15RulePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _d15InkA(0.05)
      ..strokeWidth = 1;
    const gap = 28.0;
    for (double y = gap; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _D15SendButton extends StatelessWidget {
  const _D15SendButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _d15Ink,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text('부치기',
            style: _d15Stamp(
                size: 10, color: _d15News, weight: FontWeight.w700, spacing: 2)),
      ),
    );
  }
}

class _D15Thickness extends StatelessWidget {
  const _D15Thickness({required this.value, required this.onChanged});
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
            height: 28,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(width: w, height: 1, color: _d15InkA(0.16)),
                Container(width: t * w, height: 2, color: _d15Ink),
                Align(
                  alignment: Alignment(-1 + 2 * t, 0),
                  child: Container(
                    width: 4,
                    height: 22,
                    color: _d15Ink,
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

class _D15Action extends StatelessWidget {
  const _D15Action({
    required this.glyph,
    required this.label,
    this.emphatic = false,
  });
  final String glyph;
  final String label;
  final bool emphatic;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => emphatic
          ? HapticFeedback.heavyImpact()
          : HapticFeedback.selectionClick(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: emphatic ? _d15Ink : _d15Dim,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: _d15InkA(emphatic ? 0.85 : 0.16)),
            ),
            child: Text(glyph, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: _d15Stamp(
                  size: 9,
                  color: emphatic ? _d15Ink : _d15InkA(0.65),
                  weight: emphatic ? FontWeight.w700 : FontWeight.w600,
                  spacing: 1.6)),
        ],
      ),
    );
  }
}

// ==================================================================== Pet Home
class _D15PetHome extends StatefulWidget {
  const _D15PetHome({required this.data});
  final AppData data;
  @override
  State<_D15PetHome> createState() => _D15PetHomeState();
}

class _D15PetHomeState extends State<_D15PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((i) => i.equipped).toList();
    return Scaffold(
      backgroundColor: _d15News,
      body: SafeArea(
        child: Column(
          children: [
            _D15Masthead(
              section: '우리 펫 · THE PET',
              edition: widget.data.couple.streakDays,
              date: _d15Today(widget.data),
              trailing: _D15Coins(coins: pet.coins),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _D15Story(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // lead headline
                    const _D15Eyebrow('오늘의 주인공 · FEATURE'),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(pet.name,
                            style: _d15Slab(size: 26, weight: FontWeight.w800)),
                        const SizedBox(width: 10),
                        Text('Lv.${pet.level}',
                            style: _d15Stamp(size: 11, color: _d15InkA(0.6))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('둘이 함께 키우는 오늘자 표지 모델.',
                        style: _d15Body(size: 12, color: _d15InkA(0.55))),
                    // portrait + pull-quote
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
                                  ? _D15Quote(text: pet.speech, who: pet.name)
                                  : const SizedBox(
                                      height: 52, key: ValueKey('empty')),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => patted = !patted);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 132,
                                height: 132,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _d15Card,
                                  border: Border.all(color: _d15InkA(0.22)),
                                ),
                                child: Text(pet.moodEmoji,
                                    style: const TextStyle(fontSize: 72)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (equipped.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('착용',
                                      style: _d15Stamp(
                                          size: 8, color: _d15InkA(0.5))),
                                  const SizedBox(width: 8),
                                  for (final e in equipped) ...[
                                    Text(e.emoji,
                                        style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                  ],
                                ],
                              ),
                            const SizedBox(height: 8),
                            Text('쓰다듬어 한마디 듣기',
                                style: _d15Body(
                                    size: 12, color: _d15InkA(0.45))),
                          ],
                        ),
                      ),
                    ),
                    _D15Growth(growth: pet.growth),
                    const SizedBox(height: 16),
                    const _D15Hair(),
                    const SizedBox(height: 12),
                    // store
                    Row(
                      children: [
                        const _D15Eyebrow('스토어 · STORE'),
                        const Spacer(),
                        Text('전체보기',
                            style:
                                _d15Stamp(size: 8, color: _d15InkA(0.45))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: pet.store.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) =>
                            _D15StoreCard(item: pet.store[i]),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            const _D15Nav(current: 0),
          ],
        ),
      ),
    );
  }
}

class _D15Coins extends StatelessWidget {
  const _D15Coins({required this.coins});
  final int coins;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _d15InkA(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 7),
          Text('$coins 코인',
              style: _d15Stamp(size: 10, weight: FontWeight.w700, spacing: 1)),
        ],
      ),
    );
  }
}

// A newspaper pull-quote for the pet's line, revealed on a pat.
class _D15Quote extends StatelessWidget {
  const _D15Quote({required this.text, required this.who});
  final String text;
  final String who;
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('quote'),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: _d15Ink, width: 2),
          right: BorderSide(color: _d15InkA(0.14), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('“$text”',
              textAlign: TextAlign.left,
              style: _d15Slab(
                  size: 15, weight: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 6),
          Text('— $who',
              style: _d15Stamp(size: 8, color: _d15InkA(0.55))),
        ],
      ),
    );
  }
}

class _D15Growth extends StatelessWidget {
  const _D15Growth({required this.growth});
  final double growth;
  @override
  Widget build(BuildContext context) {
    final pct = (growth * 100).round();
    return Column(
      children: [
        Row(
          children: [
            Text('다음 호까지',
                style: _d15Stamp(size: 8, color: _d15InkA(0.5), spacing: 1.6)),
            const Spacer(),
            Text('$pct%',
                style: _d15Stamp(size: 9, color: _d15InkA(0.7))),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return Stack(
              children: [
                Container(width: w, height: 3, color: _d15InkA(0.12)),
                Container(
                  width: w * growth.clamp(0.0, 1.0),
                  height: 3,
                  color: _d15Ink,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _D15StoreCard extends StatelessWidget {
  const _D15StoreCard({required this.item});
  final PetItem item;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.selectionClick(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: item.equipped ? _d15Dim : _d15Card,
          border: Border.all(
            color: item.equipped ? _d15InkA(0.8) : _d15InkA(0.16),
            width: item.equipped ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _d15Body(size: 11, weight: FontWeight.w500)),
            const SizedBox(height: 6),
            _status(item),
          ],
        ),
      ),
    );
  }

  Widget _status(PetItem it) {
    if (it.equipped) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 3, color: _d15Ink),
          const SizedBox(width: 5),
          Text('착용중', style: _d15Stamp(size: 8, spacing: 1)),
        ],
      );
    }
    if (it.owned) {
      return Text('보유', style: _d15Stamp(size: 8, color: _d15InkA(0.5)));
    }
    return Text('${it.price} 코인',
        style: _d15Stamp(size: 8, color: _d15InkA(0.6), spacing: 0.6));
  }
}

// ================================================================ Memory Album
class _D15Album extends StatefulWidget {
  const _D15Album({required this.data});
  final AppData data;
  @override
  State<_D15Album> createState() => _D15AlbumState();
}

class _D15AlbumState extends State<_D15Album> {
  bool byDate = true;
  DoodleType? filter;

  List<Doodle> get _items {
    final list = widget.data.album
        .where((d) => filter == null || d.type == filter)
        .toList();
    if (byDate) {
      list.sort((a, b) => b.at.compareTo(a.at));
    } else {
      list.sort((a, b) {
        final t = a.type.index.compareTo(b.type.index);
        return t != 0 ? t : b.at.compareTo(a.at);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final lead = items.isNotEmpty ? items.first : null;
    final briefs = items.length > 1 ? items.sublist(1) : const <Doodle>[];
    return Scaffold(
      backgroundColor: _d15News,
      body: SafeArea(
        child: Column(
          children: [
            _D15Masthead(
              section: '기록 · ARCHIVE',
              edition: widget.data.couple.streakDays,
              date: _d15Today(widget.data),
              trailing: _D15SortToggle(
                byDate: byDate,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => byDate = !byDate);
                },
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _D15Story(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // type filters
                    SizedBox(
                      height: 30,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        children: [
                          _D15FilterChip(
                            label: '전체',
                            selected: filter == null,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => filter = null);
                            },
                          ),
                          for (final t in DoodleType.values)
                            _D15FilterChip(
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
                    const SizedBox(height: 14),
                    // the log of briefs (lead runs at the top of the list)
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Text('아직 실린 기억이 없어요',
                                  style: _d15Body(
                                      size: 13, color: _d15InkA(0.5))))
                          : ListView(
                              padding: const EdgeInsets.only(bottom: 12),
                              children: [
                                if (lead != null) _D15Lead(doodle: lead),
                                if (briefs.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(height: 1.2, color: _d15InkA(0.4)),
                                  const SizedBox(height: 2),
                                ],
                                for (int i = 0; i < briefs.length; i++) ...[
                                  _D15Brief(doodle: briefs[i]),
                                  if (i != briefs.length - 1) const _D15Hair(),
                                ],
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const _D15Nav(current: 1),
          ],
        ),
      ),
    );
  }
}

class _D15SortToggle extends StatelessWidget {
  const _D15SortToggle({required this.byDate, required this.onTap});
  final bool byDate;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          color: on ? _d15Ink : Colors.transparent,
          child: Text(label,
              style: _d15Stamp(
                size: 8,
                color: on ? _d15News : _d15InkA(0.45),
                spacing: 1.2,
              )),
        );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: _d15InkA(0.5))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg('날짜별', byDate),
            Container(width: 1, height: 20, color: _d15InkA(0.5)),
            seg('유형별', !byDate),
          ],
        ),
      ),
    );
  }
}

class _D15FilterChip extends StatelessWidget {
  const _D15FilterChip({
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
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? _d15Ink : Colors.transparent,
            border: Border.all(color: _d15InkA(selected ? 0.85 : 0.28)),
          ),
          child: Text(label,
              style: _d15Stamp(
                size: 9,
                color: selected ? _d15News : _d15InkA(0.6),
                weight: selected ? FontWeight.w700 : FontWeight.w500,
                spacing: 1.4,
              )),
        ),
      ),
    );
  }
}

// The front-page lead: a wide duotone plate with headline + byline.
class _D15Lead extends StatelessWidget {
  const _D15Lead({required this.doodle});
  final Doodle doodle;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _D15Eyebrow('오늘의 머리기사 · LEAD'),
            const Spacer(),
            Text(d.liked ? '♥' : '♡',
                style: TextStyle(
                    fontSize: 14,
                    color: d.liked ? _d15Ink : _d15InkA(0.3))),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, c) => Container(
            width: c.maxWidth,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: _d15InkA(0.22)),
              gradient: LinearGradient(
                colors: d.swatch.map(_d15Tone).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(d.emoji, style: const TextStyle(fontSize: 52)),
          ),
        ),
        const SizedBox(height: 10),
        Text(d.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _d15Slab(size: 22, weight: FontWeight.w800, height: 1.12)),
        const SizedBox(height: 6),
        Text('${d.author} 기자  ·  ${d.type.label}  ·  ${d.at.month}.${d.at.day}',
            style: _d15Stamp(size: 9, color: _d15InkA(0.55), spacing: 1)),
      ],
    );
  }
}

// A single brief in the column.
class _D15Brief extends StatelessWidget {
  const _D15Brief({required this.doodle});
  final Doodle doodle;
  @override
  Widget build(BuildContext context) {
    final d = doodle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _D15Plate(doodle: d, size: 48, emojiSize: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _d15Slab(size: 16, weight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('${d.author}  ·  ${d.type.label}  ·  ${d.at.month}.${d.at.day}',
                    style: _d15Stamp(size: 8, color: _d15InkA(0.5), spacing: 1)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(d.liked ? '♥' : '♡',
              style: TextStyle(
                  fontSize: 14, color: d.liked ? _d15Ink : _d15InkA(0.22))),
        ],
      ),
    );
  }
}
