// Memory Pager — 진입점.
// 데모는 온보딩 완료 상태(mock.onboarded=true)로 홈에서 시작한다.
// 설정의 "로그아웃"이 mock 을 리셋하면 온보딩(1a→1b→4a)이 열린다.

import 'package:flutter/material.dart';

import 'mock.dart';
import 'screens/onboarding_name.dart';
import 'shell.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MemoryPagerApp());
}

class MemoryPagerApp extends StatelessWidget {
  const MemoryPagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Pager',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mock,
      builder: (context, _) =>
          mock.onboarded ? const AppShell() : const OnboardingNameScreen(),
    );
  }
}
