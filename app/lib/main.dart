// Memory Pager — 진입점.
// --dart-define=API_BASE=https://anjonghwa.madcamp-kaist.org 를 주면 실서버로 부팅한다.
// (선택) --dart-define=DEVICE_UID=couple-a 로 기기를 구분한다(두 브라우저 = 커플 2인).
// API_BASE 가 없으면 Mock 데모(온보딩 완료 상태로 홈에서 시작).

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock.dart';
import 'screens/onboarding_name.dart';
import 'shell.dart';
import 'theme.dart';

const _apiBase = String.fromEnvironment('API_BASE');
// 테스트용 강제 uid(선택). 비어 있으면 기기별로 생성·영속화한다.
const _forcedUid = String.fromEnvironment('DEVICE_UID');

/// 기기 고유 id. 최초 실행 때 만들어 저장하고, 이후 재사용한다(완성품에서 한 기기 = 한 유저).
Future<String> _deviceUid() async {
  if (_forcedUid.isNotEmpty) return _forcedUid;
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('device_uid');
  if (saved != null && saved.length >= 8) return saved;
  final r = Random();
  final uid = 'mp-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}-'
      '${List.generate(6, (_) => r.nextInt(36).toRadixString(36)).join()}';
  await prefs.setString('device_uid', uid);
  return uid;
}

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
        : _deviceUid().then((uid) => mock.bootstrapReal(_apiBase, uid, '나'));
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
