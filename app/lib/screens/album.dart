// 1e 낙서 사진첩 — 주간 스트립 + 인물 필터 + 낙서 타임라인.
// 디자인 원본: "Memory Pager 디자인.dc.html" #1e (390x844).

import 'package:flutter/material.dart';

import '../mock.dart';
import '../theme.dart';
import 'calendar.dart';
import 'diary.dart';
import 'viewer.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  // 0 = 모두, 1 = 나(지우), 2 = 상대(나무)
  int _filter = 0;
  bool _grid = false; // 상단 겹사진 아이콘: 타임라인 ↔ 격자 갤러리 토글

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paperCard,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: mock,
          builder: (context, _) {
            final items = mock.doodles
                .where((d) =>
                    _filter == 0 || (_filter == 1 ? d.fromMe : !d.fromMe))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('낙서 사진첩', style: sans(22, w: FontWeight.w800)),
                      Row(
                        children: [
                          _iconBtn(const _StackPhotosIcon(),
                              onTap: () => setState(() => _grid = !_grid)),
                          const SizedBox(width: 8),
                          _iconBtn(
                            const _CalendarIcon(),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const CalendarScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ---- 본문
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _weekStrip(),
                        const SizedBox(height: 14),
                        _personChips(),
                        const SizedBox(height: 14),
                        if (_grid) _photoGrid(items) else ..._timeline(items),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------ 헤더 버튼
  Widget _iconBtn(Widget icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: blushSoft,
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: icon,
      ),
    );
  }

  // ------------------------------------------------------------ 격자 갤러리
  Widget _photoGrid(List<Doodle> items) {
    if (items.isEmpty) return _moriBanner();
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final d in items)
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ViewerScreen(doodle: d)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: doodleImage(d),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------ 주간 스트립
  Widget _weekStrip() {
    Widget day(String label, Widget circle, {bool today = false}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: sans(11,
                w: today ? FontWeight.w800 : FontWeight.w700,
                c: today ? coral : muted),
          ),
          const SizedBox(height: 5),
          SizedBox(width: 40, height: 40, child: circle),
        ],
      );
    }

    Widget plain(Color bg, {String? mark, Color? markColor, double? fs}) {
      return Container(
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: mark == null
            ? null
            : Text(mark, style: hand(fs ?? 15, c: markColor ?? coral)),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        day(
          '월',
          ClipOval(
            child: Image.asset('assets/photos/photo_sky.png',
                width: 40, height: 40, fit: BoxFit.cover),
          ),
        ),
        day('화', plain(blushSoft, mark: '♥')),
        day('수', plain(chipBg)),
        day('목', plain(goldBg, mark: '글', markColor: goldText, fs: 14)),
        day('금', plain(chipBg)),
        day('토', plain(blushSoft, mark: '♥')),
        day(
          '오늘',
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: Image.asset('assets/photos/photo_field.png',
                    width: 40, height: 40, fit: BoxFit.cover),
              ),
              Positioned(
                left: -4,
                top: -4,
                right: -4,
                bottom: -4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: coral, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          today: true,
        ),
      ],
    );
  }

  // ------------------------------------------------------------ 인물 칩
  Widget _personChips() {
    Widget chip(String label, int value) {
      final active = _filter == value;
      return GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? ink : chipBg,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: sans(12.5,
                w: active ? FontWeight.w700 : FontWeight.w600,
                c: active ? Colors.white : brown),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('모두', 0),
        const SizedBox(width: 8),
        chip(mock.myName, 1),
        const SizedBox(width: 8),
        chip(mock.partnerName, 2),
      ],
    );
  }

  // ------------------------------------------------------------ 타임라인
  List<Widget> _timeline(List<Doodle> items) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final d = items[i];
      if (i > 0) children.add(const SizedBox(height: 14));
      children.add(_section(d));
      if (i == 0) {
        children.add(const SizedBox(height: 14));
        children.add(_moriBanner());
      }
    }
    if (items.isEmpty) children.add(_moriBanner());
    return children;
  }

  Widget _section(Doodle d) {
    final when = d.when == '방금 전' ? '오늘' : d.when;
    final dir = d.fromMe
        ? '${mock.myName} → ${mock.partnerName}'
        : '${mock.partnerName} → ${mock.myName}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: '$when ',
            style: sans(13, w: FontWeight.w800),
            children: [
              TextSpan(
                  text: '· $dir', style: sans(13, w: FontWeight.w600, c: muted)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ViewerScreen(doodle: d)),
          ),
          child: (d.asset != null || d.imageUrl != null)
              ? _photoCard(d)
              : _textCard(d),
        ),
      ],
    );
  }

  Widget _photoCard(Doodle d) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            doodleImage(d),
            if (d.caption != null)
              Positioned(
                left: 12,
                bottom: 8,
                child: Text(
                  d.caption!,
                  style: hand(19, c: Colors.white).copyWith(
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: .4),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _textCard(Doodle d) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: blushSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: -0.0349, // -2deg
        child: Text(d.text ?? '', style: hand(22, c: coral)),
      ),
    );
  }

  // ------------------------------------------------------------ 모리 앨범 배너
  Widget _moriBanner() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DiaryScreen()),
      ),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: blushSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: blush,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text('♥', style: hand(14, c: coral)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${mock.petName}가 '가을 데이트' 앨범을 만들었어요",
                  style: sans(13, w: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text('낙서 12개 · 눌러서 보기', style: sans(12, c: brownWarm)),
              ],
            ),
          ),
          Text('→', style: sans(13, c: brownWarm)),
        ],
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------- icons
// 모아보기 — 겹친 사진 두 장 (design svg 재현).
class _StackPhotosIcon extends StatelessWidget {
  const _StackPhotosIcon();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(17, 17),
      painter: _StackPhotosPainter(),
    );
  }
}

class _StackPhotosPainter extends CustomPainter {
  const _StackPhotosPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()
      ..color = coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 뒤 사진
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(8 * s, 4 * s, 13 * s, 13 * s), Radius.circular(3 * s)),
      stroke,
    );
    // 앞 사진 (채움 + 테두리)
    final front = RRect.fromRectAndRadius(
        Rect.fromLTWH(3 * s, 8 * s, 13 * s, 13 * s), Radius.circular(3 * s));
    canvas.drawRRect(front, Paint()..color = blushSoft);
    canvas.drawRRect(front, stroke);
    // 해 + 산
    canvas.drawCircle(
        Offset(7.5 * s, 12.5 * s), 1.3 * s, Paint()..color = coral);
    final path = Path()
      ..moveTo(5 * s, 18 * s)
      ..lineTo(8.5 * s, 14.8 * s)
      ..lineTo(11 * s, 17 * s)
      ..lineTo(13 * s, 15.4 * s);
    canvas.drawPath(path, stroke..strokeWidth = 1.8 * s);
  }

  @override
  bool shouldRepaint(covariant _StackPhotosPainter oldDelegate) => false;
}

// 달력 아이콘 (design svg 재현).
class _CalendarIcon extends StatelessWidget {
  const _CalendarIcon();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(17, 17),
      painter: _CalendarPainter(),
    );
  }
}

class _CalendarPainter extends CustomPainter {
  const _CalendarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()
      ..color = coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(4 * s, 5 * s, 16 * s, 15 * s), Radius.circular(3 * s)),
      stroke,
    );
    canvas.drawLine(Offset(4 * s, 10 * s), Offset(20 * s, 10 * s), stroke);
    canvas.drawLine(Offset(9 * s, 3.5 * s), Offset(9 * s, 7 * s), stroke);
    canvas.drawLine(Offset(15 * s, 3.5 * s), Offset(15 * s, 7 * s), stroke);
  }

  @override
  bool shouldRepaint(covariant _CalendarPainter oldDelegate) => false;
}
