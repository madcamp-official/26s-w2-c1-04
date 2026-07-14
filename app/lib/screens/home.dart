// 홈 (design 1c) — 펫 + 오늘의 질문 + 찌르기.
// Header: roomColor + 펫, Body: CTA / 오늘의 질문 / 새 낙서.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../mock.dart';
import '../pet.dart';
import '../theme.dart';
import 'draw_canvas.dart';
import 'report.dart';
import 'settings.dart';
import 'surprise.dart';
import 'viewer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pats = 0;

  void _onPat() {
    mock.pat();
    _pats += 1;
    if (_pats % 5 == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SurpriseScreen()),
      );
    }
  }

  Future<void> _openAnswerDialog() async {
    final ctrl = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('오늘의 질문', style: sans(15, w: FontWeight.w800, c: coral)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mock.question,
                style: sans(14.5, w: FontWeight.w700, h: 1.45)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => Navigator.of(ctx).pop(ctrl.text.trim()),
              style: sans(14),
              decoration: InputDecoration(
                hintText: '내 답변을 남겨보세요…',
                hintStyle: sans(13.5, c: muted),
                filled: true,
                fillColor: paper,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소', style: sans(13.5, w: FontWeight.w600, c: muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text('남기기', style: sans(13.5, w: FontWeight.w800, c: coral)),
          ),
        ],
      ),
    );
    if (v != null && v.isNotEmpty) mock.answer(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paperCard,
      body: ListenableBuilder(
        listenable: mock,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ctaRow(context),
                      const SizedBox(height: 14),
                      _questionCard(),
                      const SizedBox(height: 14),
                      if (mock.latestFromPartner != null)
                        _newDoodleCard(context, mock.latestFromPartner!),
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

  // ------------------------------------------------------------- (A) header
  Widget _header(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: mock.roomColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mock.groupName,
                          style: sans(18, w: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('함께한 지 D+${mock.dDay}',
                          style:
                              sans(12.5, w: FontWeight.w600, c: brownWarm)),
                    ],
                  ),
                  const Spacer(),
                  _headerIconBtn(
                    child: const _BarChartIcon(),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _headerIconBtn(
                    child: const _GearIcon(),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(mock.petBubble, style: hand(17, c: inkSoft)),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _onPat,
                    child: PetFace(size: mock.petSize),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: coral,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(mock.levelLabel,
                            style: sans(12,
                                w: FontWeight.w800, c: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      Text(mock.petName,
                          style: sans(13, w: FontWeight.w700, c: inkSoft)),
                      const SizedBox(width: 8),
                      Text('쓰다듬어 주세요', style: sans(12, c: brownWarm)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerIconBtn({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  // ------------------------------------------------------------- (B) CTA
  Widget _ctaRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DrawCanvasScreen()),
            ),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: coral,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: coral.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _ScribbleIcon(color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('낙서 보내기',
                      style: sans(15, w: FontWeight.w700, c: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: mock.poke,
          child: Container(
            width: 110,
            height: 64,
            decoration: BoxDecoration(
              color: blushSoft,
              border: Border.all(color: myPinkBg, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('콕 찌르기', style: sans(15, w: FontWeight.w800, c: coral)),
                const SizedBox(height: 2),
                Text('오늘 ${mock.pokesToday}번',
                    style: sans(11, c: brownWarm)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------ (C) 오늘의 질문
  Widget _questionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line, width: 1.5),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('오늘의 질문',
                  style: sans(12, w: FontWeight.w800, c: coral, ls: 1)),
              const Spacer(),
              if (mock.partnerAnswered)
                Text('${mock.partnerName}님 답변 완료',
                    style: sans(11.5, c: muted)),
            ],
          ),
          const SizedBox(height: 10),
          Text(mock.question, style: sans(16, w: FontWeight.w700, h: 1.45)),
          const SizedBox(height: 10),
          if (mock.myAnswer == null)
            GestureDetector(
              onTap: _openAnswerDialog,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: paper,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text('내 답변을 남겨보세요…', style: sans(13.5, c: muted)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: blushSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(mock.myAnswer!, style: hand(19)),
            ),
          // 내가 답한 뒤에만 상대 답변이 공개된다(#6). 서버가 partnerAnswer 를 채워줌.
          if (mock.myAnswer != null) ...[
            const SizedBox(height: 10),
            if (mock.partnerAnswer != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: paper,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${mock.partnerName}님의 답변',
                        style: sans(11, w: FontWeight.w800, c: coral, ls: .5)),
                    const SizedBox(height: 4),
                    Text(mock.partnerAnswer!, style: hand(19)),
                  ],
                ),
              )
            else
              Text(
                mock.partnerAnswered
                    ? '${mock.partnerName}님도 답했어요'
                    : '${mock.partnerName}님이 답하면 여기서 볼 수 있어요',
                style: sans(12.5, c: muted),
              ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------ (D) 새 낙서
  Widget _newDoodleCard(BuildContext context, Doodle d) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ViewerScreen(doodle: d)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line, width: 1.5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            _doodleThumb(d),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${mock.partnerNick}님의 새 낙서',
                      style: sans(14, w: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    d.caption ?? d.text ?? '',
                    style: hand(16, c: brown),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(d.when, style: sans(11.5, c: muted)),
          ],
        ),
      ),
    );
  }

  Widget _doodleThumb(Doodle d) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (d.type == DoodleType.text)
              Container(
                color: blushSoft,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(4),
                child: Text(
                  d.text ?? '',
                  style: hand(12, c: brown),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              doodleImage(d),
            Positioned(
              right: 4,
              bottom: 4,
              child: Text(
                '♥',
                style: hand(14, c: Colors.white).copyWith(
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
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
}

// ------------------------------------------------------------------- icons

/// 낙서 스트로크 아이콘 — design path: M4 17 Q8 8 12 13 T20 7.
class _ScribbleIcon extends StatelessWidget {
  const _ScribbleIcon({required this.color, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ScribblePainter(color),
    );
  }
}

class _ScribblePainter extends CustomPainter {
  const _ScribblePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;
    // M4 17 Q8 8 12 13 T20 7 (T = 이전 제어점 반사 → (16,18))
    canvas.drawPath(
      Path()
        ..moveTo(4 * s, 17 * s)
        ..quadraticBezierTo(8 * s, 8 * s, 12 * s, 13 * s)
        ..quadraticBezierTo(16 * s, 18 * s, 20 * s, 7 * s),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _ScribblePainter old) => old.color != color;
}

/// 막대 그래프 아이콘 (레포트) — rect 3개.
class _BarChartIcon extends StatelessWidget {
  const _BarChartIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(17, 17),
      painter: _BarChartPainter(),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final p = Paint()..color = ink;
    RRect bar(double x, double y, double h) => RRect.fromRectAndRadius(
          Rect.fromLTWH(x * s, y * s, 4 * s, h * s),
          Radius.circular(1.5 * s),
        );
    canvas.drawRRect(bar(4, 12, 8), p);
    canvas.drawRRect(bar(10, 6, 14), p);
    canvas.drawRRect(bar(16, 10, 10), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// 설정 톱니(기어) 아이콘 — 짧고 굵은 톱니 8개 + 몸통 링 + 가운데 구멍.
/// (예전 '해' 아이콘은 광선처럼 보여 설정으로 안 읽혔다.)
class _GearIcon extends StatelessWidget {
  const _GearIcon();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(17, 17),
      painter: _GearPainter(),
    );
  }
}

class _GearPainter extends CustomPainter {
  const _GearPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final c = Offset(12 * s, 12 * s);
    // 톱니: 짧고 굵게(광선처럼 길고 얇지 않게) — 기어로 읽히게 한다.
    final teeth = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final dx = math.cos(a), dy = math.sin(a);
      canvas.drawLine(
        Offset(c.dx + dx * 6.5 * s, c.dy + dy * 6.5 * s),
        Offset(c.dx + dx * 9.5 * s, c.dy + dy * 9.5 * s),
        teeth,
      );
    }
    // 몸통 링 + 가운데 구멍
    final body = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s;
    canvas.drawCircle(c, 6 * s, body);
    canvas.drawCircle(c, 2.4 * s, body);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
