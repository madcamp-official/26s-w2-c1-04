// 1a 온보딩 · 내 이름 작성 — 디자인 HTML 619~644 실측 그대로.
// paper 바탕, 중앙 로고(펫 88 blush 박스) + 이름 입력 + 하단 '시작하기' CTA.

import 'package:flutter/material.dart';

import '../pet.dart';
import '../theme.dart';
import 'onboarding_group.dart';

class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _start() {
    final entered = _name.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OnboardingGroupScreen(myName: entered.isEmpty ? '지우' : entered),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Column(
          children: [
            // ---- 중앙 콘텐츠 (키보드가 올라와도 스크롤로 대응)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 88px blush 박스 + 펫 얼굴(64)
                      Container(
                        width: 88,
                        height: 88,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          color: blush,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        alignment: Alignment.center,
                        child: const PetFace(size: 64, cheeks: false),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '삐- 삐-',
                          style: hand(16, c: coral, ls: 2),
                        ),
                      ),
                      Text(
                        'Memory Pager',
                        style: sans(26, w: FontWeight.w800, ls: -0.5),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '둘만의 낙서와 추억을 담는\n우리들의 작은 호출기',
                          textAlign: TextAlign.center,
                          style: sans(14, c: hintWarm, h: 1.5),
                        ),
                      ),
                      // ---- 이름 입력 블록
                      Padding(
                        padding: const EdgeInsets.only(top: 44),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '내 이름',
                                style:
                                    sans(13, w: FontWeight.w600, c: inkSoft),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 56,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(color: myPinkBg, width: 1.5),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _name,
                                  cursorColor: coral,
                                  cursorWidth: 2,
                                  style: sans(17, w: FontWeight.w600),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _start(),
                                  decoration: InputDecoration(
                                    isCollapsed: true,
                                    border: InputBorder.none,
                                    hintText: '지우',
                                    hintStyle: sans(17,
                                        w: FontWeight.w600, c: muted),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '상대방에게 보여질 이름이에요',
                                style: sans(12, c: muted),
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
              child: GestureDetector(
                onTap: _start,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: coral,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: coral.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '시작하기',
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
}
