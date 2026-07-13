// 4b 받은 낙서 뷰어 — full-bleed. 실시간(ephemeral) 모드는 5초 카운트 후 사라진다.

import 'package:flutter/material.dart';

import '../mock.dart';
import '../theme.dart';
import 'draw_canvas.dart';

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key, required this.doodle});

  final Doodle doodle;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late final bool _showCountdown;
  int _count = 5;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _showCountdown = widget.doodle.ephemeral && !widget.doodle.viewed;
    if (widget.doodle.ephemeral) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mock.markViewed(widget.doodle);
      });
    }
    if (_showCountdown) _tick();
  }

  void _tick() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted || _closing) return;
      setState(() => _count -= 1);
      if (_count <= 0) {
        _closing = true;
        mock.doodles.remove(widget.doodle);
        mock.markViewed(widget.doodle); // notifyListeners
        if (mounted) Navigator.of(context).pop();
      } else {
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doodle;
    return Scaffold(
      backgroundColor: ink,
      body: ListenableBuilder(
        listenable: mock,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ---- 배경: 사진/그림(asset 또는 network) 또는 텍스트 낙서
              if (d.type != DoodleType.text &&
                  (d.asset != null || d.imageUrl != null))
                doodleImage(d)
              else
                Container(
                  color: blushSoft,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    d.text ?? '',
                    style: hand(34),
                    textAlign: TextAlign.center,
                  ),
                ),

              // ---- 위/아래 그라데이션
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 150,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [overlay(.6), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 190,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, overlay(.65)],
                    ),
                  ),
                ),
              ),

              // ---- 손글씨 캡션 (Gaegu, -6deg)
              if (d.caption != null)
                Positioned(
                  top: 400,
                  left: 26,
                  child: Transform.rotate(
                    angle: -0.10471975511965977, // -6deg
                    child: Text(
                      d.caption!,
                      style: hand(
                        38,
                        w: FontWeight.w700,
                        c: coralHot,
                      ).copyWith(
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            color: Colors.black.withValues(alpha: .2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ---- 컨트롤 레이어
              SafeArea(
                child: Stack(
                  children: [
                    // 상단 바
                    Positioned(
                      top: 12,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
                            decoration: BoxDecoration(
                              color: overlay(.5),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: partnerBlueBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    mock.partnerName.isNotEmpty
                                        ? mock.partnerName.substring(0, 1)
                                        : '나',
                                    style: sans(11,
                                        w: FontWeight.w800, c: partnerBlue),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      mock.partnerNick,
                                      style: sans(13,
                                          w: FontWeight.w800,
                                          c: Colors.white),
                                    ),
                                    Text(
                                      d.when,
                                      style: sans(11,
                                          c: Colors.white
                                              .withValues(alpha: .75)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: overlay(.5),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '✕',
                                style: sans(15,
                                    w: FontWeight.w700, c: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 실시간 모드 5초 카운트 (점선 원)
                    if (_showCountdown)
                      Positioned(
                        top: 66,
                        right: 20,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: overlay(.5),
                            shape: BoxShape.circle,
                          ),
                          child: CustomPaint(
                            painter: _DashedCirclePainter(),
                            child: Center(
                              child: Text(
                                '$_count',
                                style: sans(16,
                                    w: FontWeight.w800, c: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 하단 액션 줄
                    Positioned(
                      bottom: 34,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DrawCanvasScreen(replyTo: d),
                                  ),
                                );
                              },
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: coral,
                                  borderRadius: BorderRadius.circular(99),
                                  boxShadow: [
                                    BoxShadow(
                                      offset: const Offset(0, 6),
                                      blurRadius: 16,
                                      color:
                                          Colors.black.withValues(alpha: .3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CustomPaint(
                                      size: Size(19, 19),
                                      painter:
                                          _ScribblePainter(Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '답장 낙서하기',
                                      style: sans(15,
                                          w: FontWeight.w800,
                                          c: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _roundAction(
                            child: Text(
                              '♥',
                              style: sans(19, c: coral),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _roundAction(
                            onTap: mock.poke,
                            child: const CustomPaint(
                              size: Size(19, 19),
                              painter: _PokePainter(coral),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _roundAction({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 6),
              blurRadius: 16,
              color: Colors.black.withValues(alpha: .25),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// 2.5px 흰 점선 원 (실시간 카운트 배지 테두리).
class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(
        1.25, 1.25, size.width - 2.5, size.height - 2.5);
    const dashCount = 9;
    const sweepAll = 2 * 3.141592653589793 / dashCount;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, i * sweepAll, sweepAll * .55, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) => false;
}

/// 낙서(스크리블) 아이콘 — design SVG: M4 17 Q8 8 12 13 T20 7.
class _ScribblePainter extends CustomPainter {
  const _ScribblePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(4 * s, 17 * s)
      ..quadraticBezierTo(8 * s, 8 * s, 12 * s, 13 * s)
      ..quadraticBezierTo(16 * s, 18 * s, 20 * s, 7 * s);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScribblePainter old) => old.color != color;
}

/// 콕 찌르기 아이콘 — design SVG: 세로선(12,4→12,14) + 점(12,19 r1.6).
class _PokePainter extends CustomPainter {
  const _PokePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(12 * s, 4 * s), Offset(12 * s, 14 * s), stroke);
    canvas.drawCircle(Offset(12 * s, 19 * s), 1.6 * s, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PokePainter old) => old.color != color;
}
