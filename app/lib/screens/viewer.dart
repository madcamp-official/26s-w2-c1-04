// 4b 받은 낙서 뷰어 — full-bleed. 실시간(ephemeral) 모드는 5초 카운트 후 사라진다.

import 'dart:math' as math;

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

class _ViewerScreenState extends State<ViewerScreen>
    with TickerProviderStateMixin {
  late final bool _showCountdown;
  // 화면에 그릴 낙서. 사라지는 낙서는 열람 전 서버가 본문(url·text)을 잠가서 내려주므로
  // 열람 처리 후 잠금 해제된 본문을 다시 받아 이 값을 교체한다(#1 빈 화면 방지).
  late Doodle _d = widget.doodle;
  int _count = 5;
  bool _closing = false;
  bool _liked = false; // 로컬 좋아요(서버 리액션 API 미제공)

  // 하트/콕 인터랙션 애니메이션(imp5)
  late final AnimationController _heartBtn; // 하트 버튼 팝(눌림) 바운스
  late final AnimationController _pokeBtn; // 콕 버튼 흔들림
  final List<int> _floaters = []; // 떠오르는 하트들(고유 id 목록)
  int _floatId = 0;
  bool _pokeFlash = false; // '콕 찔렀어요!' 배지 표시 여부

  @override
  void initState() {
    super.initState();
    _heartBtn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _pokeBtn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _showCountdown = widget.doodle.ephemeral && !widget.doodle.viewed;
    // 받은(상대) 낙서를 열면 열람 처리한다. 일반 낙서도 표시해야 홈의 "새 낙서"
    // 카드(latestFromPartner)가 사라진다. 예전엔 ephemeral 만 markViewed 해서
    // 일반 낙서는 계속 미열람으로 남아 카드가 안 없어졌다.
    if (!widget.doodle.fromMe && !widget.doodle.viewed) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await mock.markViewed(widget.doodle);
        // 사라지는 낙서는 열람 전 서버가 url·text 를 null 로 잠가 내려준다 → 그대로 열면
        // 빈 화면(#1). 열람 처리 뒤 잠금 해제된 본문을 다시 받아 채우고, 이미지를 미리
        // 디코드한 다음에야 카운트다운을 시작한다(BUG-1). 예전엔 markViewed 직후 바로
        // 카운트다운이 돌아, 이미지가 뜨기(재조회+네트워크 fetch+디코드 ~3-4초)도 전에
        // 5초가 다 흘러 사실상 빈 화면만 보였다(사용자 '빈 화면' 신고의 실제 원인).
        if (widget.doodle.ephemeral && mock.real) {
          try {
            final full = await mock.api!.getDoodle(widget.doodle.id);
            if (!mounted) return;
            setState(() => _d = full);
            final prov = doodleImageProvider(full);
            if (prov != null && mounted) {
              // 이미지 바이트를 미리 받아 캐시에 넣는다. 이후 서버가 파일을 지워도
              // (view+5s) 캐시된 바이트로 계속 그려진다.
              try {
                await precacheImage(prov, context);
              } catch (_) {
                // 디코드 실패(만료 등)여도 카운트다운은 진행한다.
              }
            }
          } catch (_) {
            // 이미 만료됐거나 조회 실패면 기존(잠긴) 낙서 그대로 둔다.
          }
        }
        // 이미지가 화면에 실제로 뜬 뒤에 5초를 센다.
        if (mounted && _showCountdown) _tick();
      });
    } else if (_showCountdown) {
      // markViewed 경로를 타지 않는 경우엔(희귀) 곧바로 시작.
      _tick();
    }
  }

  void _tick() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted || _closing) return;
      // 답장 캔버스 등이 위에 떠 있으면(이 뷰어가 최상단이 아니면) 카운트다운을 멈추고
      // 대기한다. 예전엔 그대로 pop() 해서 최상단 답장 화면을 닫아 작성 내용을 날렸다.
      if (ModalRoute.of(context)?.isCurrent != true) {
        _tick();
        return;
      }
      setState(() => _count -= 1);
      if (_count <= 0) {
        _closing = true;
        mock.doodles.remove(widget.doodle);
        mock.refresh(); // markViewed 는 initState 에서 이미 호출(중복 view → 410 방지)
        Navigator.of(context).pop();
      } else {
        _tick();
      }
    });
  }

  @override
  void dispose() {
    _heartBtn.dispose();
    _pokeBtn.dispose();
    super.dispose();
  }

  // 하트: 좋아요 토글 + 버튼 팝 + 하트가 위로 떠오르는 애니메이션(imp5).
  void _onLike() {
    setState(() {
      _liked = !_liked;
      if (_liked) _floaters.add(++_floatId);
    });
    _heartBtn.forward(from: 0);
  }

  void _removeFloater(int id) {
    if (!mounted) return;
    setState(() => _floaters.remove(id));
  }

  // 콕: 서버로 찌르고, 버튼을 흔들며 '콕 찔렀어요!' 배지를 잠깐 띄운다(imp5).
  void _onPoke() {
    mock.poke();
    _pokeBtn.forward(from: 0);
    setState(() => _pokeFlash = true);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _pokeFlash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ink,
      body: ListenableBuilder(
        listenable: mock,
        builder: (context, _) {
          final d = _d; // 잠금 해제되면 교체된 낙서를 그린다(#1)
          return Stack(
            fit: StackFit.expand,
            children: [
              // ---- 배경: 사진/그림(asset 또는 network) 또는 텍스트 낙서
              // 손글씨 등 이미지가 있는 낙서는 타입과 무관하게 이미지를 그린다.
              if (d.asset != null || d.imageUrl != null)
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
                                    () {
                                      final name = d.fromMe
                                          ? mock.myName
                                          : mock.partnerName;
                                      return name.isNotEmpty
                                          ? name.substring(0, 1)
                                          : '나';
                                    }(),
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
                                      d.fromMe ? mock.myName : mock.partnerNick,
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

                    // 하단 액션 줄 — 본인 낙서엔 답장·좋아요·콕을 띄우지 않는다.
                    if (!d.fromMe)
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
                          AnimatedBuilder(
                            animation: _heartBtn,
                            builder: (_, child) {
                              final scale =
                                  1 + math.sin(_heartBtn.value * math.pi) * 0.35;
                              return Transform.scale(scale: scale, child: child);
                            },
                            child: _roundAction(
                              onTap: _onLike,
                              child: Text(
                                '♥',
                                style: sans(19,
                                    c: _liked ? coral : Colors.black26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedBuilder(
                            animation: _pokeBtn,
                            builder: (_, child) {
                              final t = _pokeBtn.value;
                              final ang =
                                  math.sin(t * math.pi * 4) * 0.28 * (1 - t);
                              return Transform.rotate(angle: ang, child: child);
                            },
                            child: _roundAction(
                              onTap: _onPoke,
                              child: const CustomPaint(
                                size: Size(19, 19),
                                painter: _PokePainter(coral),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 떠오르는 하트(imp5) — 좋아요를 누를 때마다 위로 날아오른다.
                    if (!d.fromMe)
                      Positioned(
                        right: 84,
                        bottom: 96,
                        child: IgnorePointer(
                          child: SizedBox(
                            width: 60,
                            height: 170,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                for (final id in _floaters)
                                  _FloatingHeart(
                                    key: ValueKey(id),
                                    seed: id,
                                    onDone: () => _removeFloater(id),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // '콕 찔렀어요!' 배지(imp5) — 콕을 누르면 잠깐 팝업된다.
                    if (!d.fromMe)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 104,
                        child: IgnorePointer(
                          child: Center(
                            child: AnimatedScale(
                              scale: _pokeFlash ? 1 : 0.6,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutBack,
                              child: AnimatedOpacity(
                                opacity: _pokeFlash ? 1 : 0,
                                duration: const Duration(milliseconds: 180),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: coral,
                                    borderRadius: BorderRadius.circular(99),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: .25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text('콕 찔렀어요!',
                                      style: sans(13.5,
                                          w: FontWeight.w800, c: Colors.white)),
                                ),
                              ),
                            ),
                          ),
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

/// 좋아요를 누를 때 위로 떠오르며 사라지는 하트(imp5). 자기 애니메이션이 끝나면
/// [onDone] 으로 부모에게 제거를 알린다.
class _FloatingHeart extends StatefulWidget {
  const _FloatingHeart({super.key, required this.onDone, required this.seed});

  final VoidCallback onDone;
  final int seed;

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        final dx = math.sin((t * 3.2) + widget.seed) * 15; // 좌우로 살랑
        final scale = 0.6 + (t < .3 ? t / .3 : 1) * 0.7;
        return Transform.translate(
          offset: Offset(dx, -150 * t),
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: Text('♥', style: sans(26, c: coral)),
            ),
          ),
        );
      },
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
