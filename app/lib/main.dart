// Memory Pager — 진입점.
// --dart-define=API_BASE=https://anjonghwa.madcamp-kaist.org 를 주면 실서버로 부팅한다.
// (선택) --dart-define=DEVICE_UID=couple-a 로 기기를 구분한다(두 브라우저 = 커플 2인).
// API_BASE 가 없으면 Mock 데모(온보딩 완료 상태로 홈에서 시작).

import 'package:flutter/material.dart';

import 'mock.dart';
import 'screens/onboarding_name.dart';
import 'shell.dart';
import 'theme.dart';

const _apiBase = String.fromEnvironment('API_BASE');
const _deviceUid =
    String.fromEnvironment('DEVICE_UID', defaultValue: 'web-demo-a');

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

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late final Future<void>? _boot;

  @override
  void initState() {
    super.initState();
    // 실서버 모드면 부팅(register→/me). 데모면 mock 그대로.
    _boot = _apiBase.isEmpty
        ? null
        : mock.bootstrapReal(_apiBase, _deviceUid, '나');
  }

  @override
  Widget build(BuildContext context) {
    if (_boot == null) return _gate(); // 데모
    return FutureBuilder<void>(
      future: _boot,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _Splash();
        }
        return _gate();
      },
    );
  }

  Widget _gate() => ListenableBuilder(
        listenable: mock,
        builder: (context, _) =>
            mock.onboarded ? const AppShell() : const OnboardingNameScreen(),
      );
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: coral),
            const SizedBox(height: 16),
            Text('삐삐- 연결 중…', style: hand(20, c: coral)),
          ],
        ),
      ),
    );
  }
}
