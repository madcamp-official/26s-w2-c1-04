// 1c 온보딩 · 초대 코드 대기(#23) — 그룹을 만든 사람이 상대가 들어올 때까지 머무는 화면.
// 홈은 아직 해금하지 않는다(솔로 상태에서 기능이 열려 코드가 꼬이는 것을 막는다).
// 상대가 들어오면 mock 폴링이 자동으로 홈으로 전환한다(이 화면은 스스로 내비게이션하지 않음).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mock.dart';
import '../pet.dart';
import '../theme.dart';

class OnboardingWaitScreen extends StatelessWidget {
  const OnboardingWaitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final code = mock.inviteCode;
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              // 펫 + 대기 애니메이션 느낌의 정적 배지
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: blush,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: const PetFace(size: 66, cheeks: false),
              ),
              const SizedBox(height: 22),
              Text('삐- 삐- 상대를 기다리는 중',
                  style: hand(17, c: coral, ls: 1)),
              const SizedBox(height: 8),
              Text(
                '연인이 아래 코드로 들어오면\n자동으로 함께 시작해요',
                textAlign: TextAlign.center,
                style: sans(15, c: hintWarm, h: 1.5),
              ),
              const SizedBox(height: 32),
              // ---- 초대 코드 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: myPinkBg, width: 1.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text('초대 코드', style: sans(12.5, w: FontWeight.w600, c: muted)),
                    const SizedBox(height: 10),
                    Text(
                      code.isEmpty ? '••••••' : code,
                      style: sans(30, w: FontWeight.w800, ls: 6),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: code.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(
                                  ClipboardData(text: code));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('코드를 복사했어요',
                                        style: sans(13)),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 11),
                        decoration: BoxDecoration(
                          color: coral,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('코드 복사하기',
                            style:
                                sans(14, w: FontWeight.w700, c: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 대기 인디케이터
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: coral),
                  ),
                  const SizedBox(width: 10),
                  Text('연결을 기다리고 있어요…',
                      style: sans(13, c: muted)),
                ],
              ),
              const Spacer(),
              // ---- 취소(그룹 나가기)
              GestureDetector(
                onTap: () => mock.cancelWaiting(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28, top: 8),
                  child: Text('그룹 만들기 취소',
                      style: sans(14, w: FontWeight.w600, c: muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
