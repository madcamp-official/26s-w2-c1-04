// 2d 달력 → 하루의 낙서를 인스타그램 스토리처럼 넘겨 본다(#8).
// 상단에 낙서 개수만큼 세그먼트 바, 화면 좌/우 탭으로 이동. 사라지는 낙서는 제외(호출측에서 필터).

import 'package:flutter/material.dart';

import '../mock.dart';
import '../theme.dart';
import 'draw_canvas.dart';

class StoryViewer extends StatefulWidget {
  const StoryViewer({super.key, required this.doodles, this.initialIndex = 0});

  final List<Doodle> doodles;
  final int initialIndex;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late int _i =
      widget.initialIndex.clamp(0, (widget.doodles.length - 1).clamp(0, 1 << 30));

  void _next() {
    if (_i < widget.doodles.length - 1) {
      setState(() => _i++);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_i > 0) setState(() => _i--);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doodles[_i];
    final hasImg = d.asset != null || d.imageUrl != null;
    final who = d.fromMe ? mock.myName : mock.partnerNick;
    final initial = who.isNotEmpty ? who.substring(0, 1) : '·';
    return Scaffold(
      backgroundColor: ink,
      body: Stack(
        children: [
          // 콘텐츠 + 좌/우 탭 영역(왼쪽 1/3 이전, 나머지 다음)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (e) {
                final w = MediaQuery.of(context).size.width;
                if (e.localPosition.dx < w * 0.32) {
                  _prev();
                } else {
                  _next();
                }
              },
              child: Center(
                child: hasImg
                    ? doodleImage(d, fit: BoxFit.contain)
                    : Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          d.text ?? '',
                          textAlign: TextAlign.center,
                          style: hand(26, c: Colors.white),
                        ),
                      ),
              ),
            ),
          ),
          // 상단: 스토리 세그먼트 바 + 헤더
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var k = 0; k < widget.doodles.length; k++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: k <= _i
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: .35),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: d.fromMe ? blush : partnerBlueBg,
                          shape: BoxShape.circle,
                        ),
                        child: Text(initial,
                            style: sans(13,
                                w: FontWeight.w800,
                                c: d.fromMe ? coral : partnerBlue)),
                      ),
                      const SizedBox(width: 8),
                      Text(who,
                          style:
                              sans(13.5, w: FontWeight.w800, c: Colors.white)),
                      const SizedBox(width: 6),
                      Text(d.when,
                          style: sans(12,
                              c: Colors.white.withValues(alpha: .7))),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 하단: 답장 낙서하기
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => DrawCanvasScreen(replyTo: d)),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: coral,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('답장 낙서하기',
                      style: sans(14, w: FontWeight.w800, c: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
