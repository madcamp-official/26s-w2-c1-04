// design_08_memory_bento — "Memory Bento".
//
// The album as an asymmetric bento grid: a big photo, a small doodle, a mood
// chip and a voice-note tile auto-arrange into a clean modular mosaic. Each day
// compacts into a single bento tile; pinch to zoom out across months and the
// grid reflows fluidly, long-press pins a favorite memory to a larger cell.
//
// Off-white canvas, ink type, one soft accent per tile type (blush / sky /
// sage / amber). Clean geometric sans, tight all-caps tile labels, confident
// numerals. Fully self-contained; everything private except [Design08].

import 'dart:math' show max, min;
import 'package:flutter/material.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

class Design08 extends DesignVariant {
  @override
  String get id => '08';
  @override
  String get name => 'Memory Bento';
  @override
  String get concept =>
      '앨범을 비대칭 벤토 그리드로 — 큰 사진·작은 낙서·무드칩·보이스 타일이 모듈 모자이크로 자동 배치.';
  @override
  String get signature =>
      '하루가 벤토 타일 한 칸으로 압축 · 핀치로 달을 넘나들면 그리드가 유려하게 리플로우 · 길게 눌러 큰 칸에 고정.';
  @override
  String get inspiration =>
      'Bento / modular grid trend (Apple keynote bento, Vercel/Linear cards) + Japanese lunchbox layout.';
  @override
  Color get accent => _D08.blush;
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    return switch (screen) {
      HeroScreen.drawSend => _D08DrawSend(data: data),
      HeroScreen.petHome => _D08PetHome(data: data),
      HeroScreen.memoryAlbum => _D08Album(data: data),
    };
  }
}

// ============================================================ design tokens
class _D08 {
  static const canvas = Color(0xFFFAF9F6);
  static const panel = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1C1C1E);
  static const inkSoft = Color(0xFF8A8781);
  static const line = Color(0xFFEBE7DF);

  // one soft accent per tile type
  static const blush = Color(0xFFE79A92);
  static const blushBg = Color(0xFFFBEAE6);
  static const sky = Color(0xFF8FB4E0);
  static const skyBg = Color(0xFFE7F0FA);
  static const sage = Color(0xFF93C2A2);
  static const sageBg = Color(0xFFE8F2EB);
  static const amber = Color(0xFFE7BB77);

  static const double radius = 22;
  static const double gap = 10;

  static Color accentFor(DoodleType t) => switch (t) {
        DoodleType.photo => sky,
        DoodleType.text => amber,
        DoodleType.drawing => sage,
      };
  static const List<BoxShadow> lift = [
    BoxShadow(color: Color(0x0F1C1C1E), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static TextStyle label([Color c = inkSoft]) => TextStyle(
        fontSize: 10,
        height: 1.0,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.8,
        color: c,
      );

  static const TextStyle numeral = TextStyle(
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -0.5,
    height: 1.0,
  );
}

// small reusable bento panel
class _D08Panel extends StatelessWidget {
  const _D08Panel({
    required this.child,
    this.fill = _D08.panel,
    this.border = _D08.line,
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final Color fill;
  final Color border;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(_D08.radius),
        border: Border.all(color: border),
        boxShadow: _D08.lift,
      ),
      child: child,
    );
  }
}

class _D08TileLabel extends StatelessWidget {
  const _D08TileLabel(this.text, {this.dot, this.color = _D08.inkSoft});
  final String text;
  final Color? dot;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot != null) ...[
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 7),
        ],
        Text(text, style: _D08.label(color)),
      ],
    );
  }
}

// dotted "paper" backdrop for the canvas
class _D08DotsPainter extends CustomPainter {
  const _D08DotsPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const step = 22.0;
    for (double y = step; y < size.height; y += step) {
      for (double x = step; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _D08DotsPainter oldDelegate) => oldDelegate.color != color;
}

// ============================================================ Draw & Send
class _D08DrawSend extends StatefulWidget {
  const _D08DrawSend({required this.data});
  final AppData data;
  @override
  State<_D08DrawSend> createState() => _D08DrawSendState();
}

class _D08DrawSendState extends State<_D08DrawSend> {
  int pen = 1;
  int thick = 2; // index into _sizes
  SendMode mode = SendMode.normal;

  static const _sizes = [2.0, 4.0, 7.0, 11.0, 16.0];

  @override
  Widget build(BuildContext context) {
    final couple = widget.data.couple;
    final penColor = demoPenColors[pen];
    return Scaffold(
      backgroundColor: _D08.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // ---- top bar
              Row(
                children: [
                  _squareBtn(Icons.arrow_back_rounded, () {}),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _D08Panel(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: _D08.blushBg, shape: BoxShape.circle),
                            child: const Text('🐱', style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _D08TileLabel('TO'),
                              const SizedBox(height: 4),
                              Text('${couple.partnerNickname}에게',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _D08.ink)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: _D08.ink,
                        borderRadius: BorderRadius.circular(_D08.radius),
                        boxShadow: _D08.lift,
                      ),
                      child: const Row(
                        children: [
                          Text('보내기',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                          SizedBox(width: 6),
                          Icon(Icons.north_east_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ---- canvas bento tile
              Expanded(
                child: _D08Panel(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_D08.radius),
                    child: Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: const _D08DotsPainter(Color(0x14000000)))),
                        Positioned(
                          left: 16,
                          top: 14,
                          child: _D08TileLabel('CANVAS · 오늘의 낙서', dot: penColor),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('✏️', style: TextStyle(fontSize: 46, color: _D08.ink.withValues(alpha: 0.25))),
                              const SizedBox(height: 6),
                              Text('한 칸의 하루를 그려요',
                                  style: TextStyle(fontSize: 12.5, color: _D08.inkSoft, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        // live stroke preview
                        Positioned(
                          left: 16,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: _D08.canvas,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _D08.line),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: _sizes[thick] + 6,
                                  height: _sizes[thick] + 6,
                                  decoration: BoxDecoration(color: penColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 44,
                                  height: _sizes[thick],
                                  decoration:
                                      BoxDecoration(color: penColor, borderRadius: BorderRadius.circular(20)),
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
              const SizedBox(height: 12),
              // ---- pens + thickness bento row
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: _D08Panel(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _D08TileLabel('PEN'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (int i = 0; i < demoPenColors.length; i++)
                                GestureDetector(
                                  onTap: () => setState(() => pen = i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: demoPenColors[i],
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                        color: pen == i ? _D08.ink : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _D08Panel(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _D08TileLabel('SIZE'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (int i = 0; i < _sizes.length; i++)
                                GestureDetector(
                                  onTap: () => setState(() => thick = i),
                                  child: Container(
                                    width: 22,
                                    height: 30,
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: _sizes[i] + 2,
                                      height: _sizes[i] + 2,
                                      decoration: BoxDecoration(
                                        color: thick == i ? _D08.ink : _D08.inkSoft.withValues(alpha: 0.35),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ---- mode toggle bento
              _D08Panel(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        for (final m in SendMode.values)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => mode = m),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: EdgeInsets.only(right: m == SendMode.normal ? 8 : 0),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: mode == m ? _D08.ink : _D08.canvas,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: mode == m ? _D08.ink : _D08.line),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(m == SendMode.normal ? Icons.push_pin_rounded : Icons.timer_rounded,
                                        size: 15, color: mode == m ? Colors.white : _D08.inkSoft),
                                    const SizedBox(width: 6),
                                    Text(m.label,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13.5,
                                            color: mode == m ? Colors.white : _D08.ink)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(mode.description,
                        style: const TextStyle(fontSize: 12, color: _D08.inkSoft, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // ---- bottom actions bento row
              Row(
                children: [
                  _action(Icons.photo_library_rounded, '갤러리', _D08.sageBg, _D08.sage),
                  const SizedBox(width: 10),
                  _action(Icons.photo_camera_rounded, '사진', _D08.skyBg, _D08.sky),
                  const SizedBox(width: 10),
                  _action(Icons.touch_app_rounded, '찌르기', _D08.blushBg, _D08.blush),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _squareBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _D08.panel,
            borderRadius: BorderRadius.circular(_D08.radius),
            border: Border.all(color: _D08.line),
            boxShadow: _D08.lift,
          ),
          child: Icon(icon, color: _D08.ink, size: 22),
        ),
      );

  Widget _action(IconData icon, String label, Color bg, Color fg) => Expanded(
        child: GestureDetector(
          onTap: () {},
          child: _D08Panel(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, color: fg, size: 20),
                ),
                const SizedBox(height: 8),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _D08.ink)),
              ],
            ),
          ),
        ),
      );
}

// ============================================================ Pet Home
class _D08PetHome extends StatefulWidget {
  const _D08PetHome({required this.data});
  final AppData data;
  @override
  State<_D08PetHome> createState() => _D08PetHomeState();
}

class _D08PetHomeState extends State<_D08PetHome> {
  bool patted = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.data.pet;
    final equipped = pet.store.where((e) => e.equipped).toList();
    return Scaffold(
      backgroundColor: _D08.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // ---- header bento row
              Row(
                children: [
                  Expanded(
                    child: _D08Panel(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _D08TileLabel('OUR PET', dot: _D08.blush),
                              const SizedBox(height: 6),
                              Text(pet.name,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _D08.ink)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: _D08.blushBg, borderRadius: BorderRadius.circular(11)),
                            child: Text('Lv.${pet.level}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _D08.blush)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _D08Panel(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('${pet.coins}', style: _D08.numeral.copyWith(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('COINS', style: _D08.label()),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ---- big pet bento tile
              Expanded(
                child: _D08Panel(
                  fill: _D08.blushBg,
                  border: _D08.blushBg,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      // equipped items strip
                      Row(
                        children: [
                          _D08TileLabel('EQUIPPED', color: _D08.blush.withValues(alpha: 0.9)),
                          const SizedBox(width: 8),
                          for (final it in equipped)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: _D08.blush.withValues(alpha: 0.4)),
                                ),
                                child: Text(it.emoji, style: const TextStyle(fontSize: 15)),
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (c, a) =>
                                    FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
                                child: patted
                                    ? Container(
                                        key: const ValueKey('speech'),
                                        margin: const EdgeInsets.only(bottom: 14),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: _D08.lift,
                                        ),
                                        child: Text(pet.speech,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700, fontSize: 13.5, color: _D08.ink)),
                                      )
                                    : const SizedBox(height: 8, key: ValueKey('nospeech')),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => patted = !patted),
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 180),
                                  scale: patted ? 1.06 : 1.0,
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: _D08.lift,
                                    ),
                                    child: Text(pet.moodEmoji, style: const TextStyle(fontSize: 78)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.touch_app_rounded, size: 15, color: _D08.blush),
                                    const SizedBox(width: 6),
                                    Text(patted ? '몽이가 좋아해요' : '쓰다듬어 보세요',
                                        style: const TextStyle(
                                            fontSize: 12, fontWeight: FontWeight.w700, color: _D08.ink)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ---- growth gauge bento
              _D08Panel(
                fill: _D08.sageBg,
                border: _D08.sageBg,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _D08TileLabel('GROWTH', color: _D08.sage),
                        const Spacer(),
                        Text('${(pet.growth * 100).round()}%',
                            style: _D08.numeral.copyWith(fontSize: 15, color: _D08.sage)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Container(height: 12, color: Colors.white),
                          FractionallySizedBox(
                            widthFactor: pet.growth,
                            child: Container(height: 12, color: _D08.sage),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Lv.${pet.level} → Lv.${pet.level + 1} 까지 성장 중',
                        style: const TextStyle(fontSize: 11.5, color: _D08.inkSoft, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ---- store row
              Row(
                children: [
                  _D08TileLabel('STORE'),
                  const Spacer(),
                  Text('보유중 · 착용중', style: _D08.label()),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: pet.store.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _storeTile(pet.store[i]),
                ),
              ),
              const SizedBox(height: 10),
              const _D08Nav(current: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storeTile(PetItem it) {
    final selected = it.equipped;
    return Container(
      width: 84,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _D08.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? _D08.ink : _D08.line, width: selected ? 2 : 1),
        boxShadow: _D08.lift,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(it.emoji, style: const TextStyle(fontSize: 26)),
              if (it.equipped)
                const Icon(Icons.check_circle_rounded, size: 16, color: _D08.ink)
              else if (it.owned)
                const Icon(Icons.check_circle_outline_rounded, size: 16, color: _D08.inkSoft),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(it.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _D08.ink)),
              const SizedBox(height: 2),
              Text(
                it.equipped ? '착용중' : (it.owned ? '보유' : '🪙 ${it.price}'),
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: it.owned ? _D08.inkSoft : _D08.amber),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================ Memory Album
class _D08Placed {
  const _D08Placed(this.d, this.col, this.row, this.cw, this.ch);
  final Doodle d;
  final int col, row, cw, ch;
}

class _D08Album extends StatefulWidget {
  const _D08Album({required this.data});
  final AppData data;
  @override
  State<_D08Album> createState() => _D08AlbumState();
}

class _D08AlbumState extends State<_D08Album> {
  bool byDate = true;
  DoodleType? filter;
  int cols = 3; // 2..4 — pinch to reflow
  String? pinnedId = 'd1';

  // pinch handling (one step per gesture)
  bool _handled = false;

  void _zoomIn() => setState(() => cols = max(2, cols - 1));
  void _zoomOut() => setState(() => cols = min(4, cols + 1));

  List<_D08Placed> _pack(List<Doodle> items) {
    final occ = <List<bool>>[];
    void ensure(int r) {
      while (occ.length <= r) {
        occ.add(List<bool>.filled(cols, false));
      }
    }

    bool fits(int r, int c, int cw, int ch) {
      if (c + cw > cols) return false;
      for (int y = r; y < r + ch; y++) {
        ensure(y);
        for (int x = c; x < c + cw; x++) {
          if (occ[y][x]) return false;
        }
      }
      return true;
    }

    void mark(int r, int c, int cw, int ch) {
      for (int y = r; y < r + ch; y++) {
        ensure(y);
        for (int x = c; x < c + cw; x++) {
          occ[y][x] = true;
        }
      }
    }

    final placed = <_D08Placed>[];
    for (final d in items) {
      int cw = d.liked ? 2 : 1;
      int ch = d.type == DoodleType.photo ? 2 : 1;
      if (d.id == pinnedId) {
        cw = 2;
        ch = 2;
      }
      cw = min(cw, cols);
      int r = 0;
      bool done = false;
      while (!done) {
        for (int c = 0; c <= cols - cw; c++) {
          if (fits(r, c, cw, ch)) {
            mark(r, c, cw, ch);
            placed.add(_D08Placed(d, c, r, cw, ch));
            done = true;
            break;
          }
        }
        if (!done) r++;
      }
    }
    return placed;
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.data.album;
    final items = all.where((d) => filter == null || d.type == filter).toList()
      ..sort((a, b) {
        if (byDate) return b.at.compareTo(a.at); // newest first
        final t = a.type.index.compareTo(b.type.index); // group by type
        return t != 0 ? t : b.at.compareTo(a.at);
      });

    return Scaffold(
      backgroundColor: _D08.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // ---- header
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _D08TileLabel('BENTO ALBUM', dot: _D08.blush),
                      const SizedBox(height: 6),
                      const Text('낙서 사진첩',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _D08.ink)),
                    ],
                  ),
                  const Spacer(),
                  // sort toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _D08.panel,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _D08.line),
                    ),
                    child: Row(
                      children: [
                        _sortSeg('날짜별', byDate, () => setState(() => byDate = true)),
                        _sortSeg('유형별', !byDate, () => setState(() => byDate = false)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ---- type filters + zoom
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('전체', null),
                          for (final t in DoodleType.values) _filterChip(t.label, t),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // zoom stepper
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    decoration: BoxDecoration(
                      color: _D08.panel,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: _D08.line),
                    ),
                    child: Row(
                      children: [
                        _zoomBtn(Icons.zoom_in_rounded, cols > 2 ? _zoomIn : null),
                        Container(
                          width: 34,
                          alignment: Alignment.center,
                          child: Text('$cols열',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _D08.ink)),
                        ),
                        _zoomBtn(Icons.zoom_out_rounded, cols < 4 ? _zoomOut : null),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.pinch_rounded, size: 13, color: _D08.inkSoft),
                  const SizedBox(width: 5),
                  Text('핀치하여 달 전체 보기 · 길게 눌러 큰 칸에 고정',
                      style: TextStyle(fontSize: 11, color: _D08.inkSoft, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              // ---- the bento mosaic (fluid reflow)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final placed = _pack(items);
                    final maxRow = max(1, placed.fold<int>(0, (m, p) => max(m, p.row + p.ch)));
                    const gap = _D08.gap;
                    final cellW = (box.maxWidth - gap * (cols - 1)) / cols;
                    double rowUnit = cellW;
                    double totalH = maxRow * rowUnit + (maxRow - 1) * gap;
                    if (totalH > box.maxHeight) {
                      rowUnit = (box.maxHeight - (maxRow - 1) * gap) / maxRow;
                      totalH = box.maxHeight;
                    }
                    return GestureDetector(
                      onScaleStart: (_) => _handled = false,
                      onScaleUpdate: (d) {
                        if (_handled || d.pointerCount < 2) return;
                        if (d.scale > 1.22) {
                          _handled = true;
                          _zoomIn();
                        } else if (d.scale < 0.82) {
                          _handled = true;
                          _zoomOut();
                        }
                      },
                      child: SizedBox(
                        width: box.maxWidth,
                        height: box.maxHeight,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: box.maxWidth,
                            height: totalH,
                            child: Stack(
                              children: [
                                for (final p in placed)
                                  AnimatedPositioned(
                                    key: ValueKey(p.d.id),
                                    duration: const Duration(milliseconds: 360),
                                    curve: Curves.easeOutCubic,
                                    left: p.col * (cellW + gap),
                                    top: p.row * (rowUnit + gap),
                                    width: p.cw * cellW + (p.cw - 1) * gap,
                                    height: p.ch * rowUnit + (p.ch - 1) * gap,
                                    child: _AlbumTile(
                                      d: p.d,
                                      pinned: p.d.id == pinnedId,
                                      big: p.cw >= 2 && p.ch >= 2,
                                      onLongPress: () => setState(
                                          () => pinnedId = pinnedId == p.d.id ? null : p.d.id),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const _D08Nav(current: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortSeg(String label, bool sel, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? _D08.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: sel ? Colors.white : _D08.inkSoft)),
        ),
      );

  Widget _filterChip(String label, DoodleType? t) {
    final sel = filter == t;
    final c = t == null ? _D08.ink : _D08.accentFor(t);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => filter = t),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? c : _D08.panel,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: sel ? c : _D08.line),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : _D08.ink)),
        ),
      ),
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Icon(icon, size: 19, color: onTap == null ? _D08.line : _D08.ink),
        ),
      );
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({
    required this.d,
    required this.pinned,
    required this.big,
    required this.onLongPress,
  });
  final Doodle d;
  final bool pinned;
  final bool big;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final accent = _D08.accentFor(d.type);
    return GestureDetector(
      onLongPress: onLongPress,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final showCaption = h > 96 && w > 96;
          final double emojiSize = big ? 52.0 : (min(w, h) * 0.42).clamp(20.0, 44.0).toDouble();
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: d.swatch,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: pinned ? Border.all(color: _D08.ink, width: 2.5) : null,
              boxShadow: _D08.lift,
            ),
            child: Stack(
              children: [
                // bottom scrim for legibility
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.28)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(d.type.icon, size: 12, color: accent),
                          ),
                          const Spacer(),
                          if (pinned)
                            const Icon(Icons.push_pin_rounded, size: 15, color: Colors.white)
                          else if (d.liked)
                            const Icon(Icons.favorite_rounded, size: 15, color: Colors.white),
                        ],
                      ),
                      const Spacer(),
                      if (d.type == DoodleType.text && showCaption)
                        Text('“${d.caption}”',
                            maxLines: big ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: big ? 16 : 13,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white))
                      else
                        Text(d.emoji, style: TextStyle(fontSize: emojiSize)),
                      const Spacer(),
                      if (showCaption && d.type != DoodleType.text)
                        Text(d.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: big ? 14 : 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      if (showCaption) const SizedBox(height: 2),
                      if (showCaption)
                        Text('${d.author} · ${d.at.month}/${d.at.day}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================ bottom nav
class _D08Nav extends StatelessWidget {
  const _D08Nav({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.pets_rounded, '펫키우기'),
      (Icons.grid_view_rounded, '사진첩'),
      (Icons.brush_rounded, '소통'),
    ];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _D08.panel,
        borderRadius: BorderRadius.circular(_D08.radius),
        border: Border.all(color: _D08.line),
        boxShadow: _D08.lift,
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: i == current ? _D08.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[i].$1, size: 18, color: i == current ? Colors.white : _D08.inkSoft),
                    if (i == current) ...[
                      const SizedBox(width: 7),
                      Text(items[i].$2,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
