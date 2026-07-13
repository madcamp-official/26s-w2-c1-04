// 4a 온보딩 · 별명 지어주기 (친구 입장 직후)
// 디자인 원본: "Memory Pager 디자인.dc.html" 35–67행.

import 'package:flutter/material.dart';

import '../mock.dart';
import '../theme.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key, required this.myName});

  final String myName;

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nick = TextEditingController(text: '나무늘보');

  static const List<String> _suggestions = ['자기', '곰돌이', '우리 강아지', '여보'];

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final v = _nick.text.trim();
    if (v.isNotEmpty) mock.setPartnerNick(v);
    // 실서버 흐름은 그룹 화면에서 이미 온보딩을 마쳤다(중복 생성 방지).
    if (!mock.onboarded) await mock.completeOnboarding(name: widget.myName);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _skip() async {
    if (!mock.onboarded) await mock.completeOnboarding(name: widget.myName);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final myInitial = widget.myName.isNotEmpty ? widget.myName[0] : '지';
    final partnerInitial =
        mock.partnerName.isNotEmpty ? mock.partnerName[0] : '나';

    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ---- 아바타 두 개 + 하트
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _avatar(myInitial, bg: blush, fg: coral),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('♥', style: hand(26, c: coral)),
                          ),
                          _avatar(partnerInitial,
                              bg: partnerBlueBg, fg: partnerBlue),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('삐삐- 연결 완료!', style: hand(16, c: coral, ls: 2)),
                      const SizedBox(height: 6),
                      Text(
                        '${mock.partnerName}님이 들어왔어요\n별명을 지어주세요',
                        textAlign: TextAlign.center,
                        style: sans(24, w: FontWeight.w800, h: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text('별명은 앱 곳곳에서 이름 대신 보여요',
                          style: sans(13.5, c: hintWarm)),
                      const SizedBox(height: 36),
                      // ---- 별명 입력
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: myPinkBg, width: 1.5),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: _nick,
                          style: sans(17, w: FontWeight.w600),
                          cursorColor: coral,
                          cursorWidth: 2,
                          cursorHeight: 22,
                          cursorRadius: const Radius.circular(2),
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ---- 추천 별명 칩
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in _suggestions)
                              GestureDetector(
                                onTap: () {
                                  _nick.text = s;
                                  _nick.selection = TextSelection.collapsed(
                                      offset: s.length);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: blushSoft,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(s,
                                      style: sans(13,
                                          w: FontWeight.w700, c: coral)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ---- 하단 CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: coral,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: coral.withValues(alpha: .3),
                            offset: const Offset(0, 6),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Text('별명 지어주기',
                          style:
                              sans(17, w: FontWeight.w700, c: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _skip,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Text('나중에 할게요',
                          style: sans(13, w: FontWeight.w600, c: muted)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String label, {required Color bg, required Color fg}) {
    return Container(
      width: 74,
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Text(label, style: sans(22, w: FontWeight.w800, c: fg)),
    );
  }
}
