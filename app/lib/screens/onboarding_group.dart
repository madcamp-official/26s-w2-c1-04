// 1b 온보딩 · 그룹 만들기 / 들어가기 — 디자인 HTML 646~678 실측 재현.

import 'package:flutter/material.dart';

import '../mock.dart';
import '../theme.dart';
import 'onboarding_nickname.dart';

class OnboardingGroupScreen extends StatefulWidget {
  const OnboardingGroupScreen({super.key, required this.myName});

  final String myName;

  @override
  State<OnboardingGroupScreen> createState() => _OnboardingGroupScreenState();
}

class _OnboardingGroupScreenState extends State<OnboardingGroupScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// 실서버면 서버에 그룹 생성/참여를 반영하고 홈으로. 데모면 별명 화면으로.
  Future<void> _finish({String? joinCode}) async {
    if (_busy) return;
    if (!mock.real) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NicknameScreen(myName: widget.myName)));
      return;
    }
    setState(() => _busy = true);
    await mock.completeOnboarding(name: widget.myName, joinCode: joinCode);
    if (!mounted) return;
    setState(() => _busy = false);
    if (mock.onboarded) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else if (mock.bootstrapError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          joinCode != null ? '코드를 확인해 주세요' : '그룹을 만들지 못했어요',
          style: sans(13),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            // ---- 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '${widget.myName}님, 반가워요!\n둘만의 그룹을 만들어요',
                      style: sans(24, w: FontWeight.w800, h: 1.35),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      '그룹은 딱 두 사람만 들어올 수 있어요',
                      style: sans(14, c: hintWarm),
                    ),
                  ),
                ],
              ),
            ),
            // ---- 본문
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: Column(
                  children: [
                    _createCard(),
                    const SizedBox(height: 16),
                    _orDivider(),
                    const SizedBox(height: 16),
                    _joinCard(),
                    const SizedBox(height: 16),
                    _infoStrip(),
                  ],
                ),
              ),
            ),
            // ---- 하단 CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: GestureDetector(
                onTap: _busy ? null : () => _finish(),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: coral,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: coral.withValues(alpha: .3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white))
                      : Text(
                          '그룹 만들기',
                          style: sans(17, w: FontWeight.w700, c: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------- 카드 1 · 그룹 만들기
  Widget _createCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: myPinkBg, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: blush,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text('+', style: sans(16, w: FontWeight.w800, c: coral)),
              ),
              const SizedBox(width: 10),
              Text('그룹 만들기', style: sans(17, w: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '그룹을 만들면 초대 코드가 자동으로 생성돼요. 코드를 연인에게 보내주세요.',
            style: sans(13, c: hintWarm, h: 1.5),
          ),
          const SizedBox(height: 14),
          CustomPaint(
            painter: _DashedRRectPainter(
              color: dashPeach,
              strokeWidth: 1.5,
              radius: 14,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: blushSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mock.inviteCode,
                    style: sans(20, w: FontWeight.w700, c: coral, ls: 4),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: coral,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '복사',
                      style: sans(12, w: FontWeight.w700, c: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------- '또는' 구분선
  Widget _orDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Expanded(child: SizedBox(height: 1, child: ColoredBox(color: lineSoft))),
          const SizedBox(width: 12),
          Text('또는', style: sans(12, c: muted)),
          const SizedBox(width: 12),
          const Expanded(child: SizedBox(height: 1, child: ColoredBox(color: lineSoft))),
        ],
      ),
    );
  }

  // ---------------------------------------------------- 카드 2 · 코드로 들어가기
  Widget _joinCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line, width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child:
                    Text('→', style: sans(15, w: FontWeight.w800, c: inkSoft)),
              ),
              const SizedBox(width: 10),
              Text('초대 코드로 들어가기', style: sans(17, w: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    style: sans(16, ls: 3),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '코드 입력',
                      hintStyle: sans(16, c: muted, ls: 3),
                    ),
                    onSubmitted: (v) =>
                        v.trim().isEmpty ? null : _finish(joinCode: v.trim()),
                  ),
                ),
                GestureDetector(
                  onTap: _busy || _code.text.trim().isEmpty
                      ? null
                      : () => _finish(joinCode: _code.text.trim()),
                  child: Text('→',
                      style: sans(18, w: FontWeight.w800, c: coral)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------- 안내 스트립
  Widget _infoStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: blushSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text('♥', style: hand(22, c: coral)),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: sans(13, c: brown, h: 1.5),
                children: [
                  const TextSpan(text: '친구가 들어오면 서로에게 '),
                  TextSpan(
                    text: '별명',
                    style: sans(13, w: FontWeight.w700, c: coral, h: 1.5),
                  ),
                  const TextSpan(text: '을 지어줄 수 있어요'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------- 점선 라운드 보더
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0, gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, (d + dash).clamp(0, metric.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.radius != radius;
}
