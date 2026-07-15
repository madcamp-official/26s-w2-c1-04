// 디자인 대비 시각 검증 — 14화면을 실제 폰트로 390x844에 렌더해 골든 PNG 로 뽑는다.
//   flutter test --update-goldens test/golden_test.dart
// 그러면 test/goldens/*.png 가 생성된다. 사람이/에이전트가 눈으로 디자인과 대조.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_pager/mock.dart';
import 'package:memory_pager/screens/album.dart';
import 'package:memory_pager/screens/calendar.dart';
import 'package:memory_pager/screens/diary.dart';
import 'package:memory_pager/screens/draw_canvas.dart';
import 'package:memory_pager/screens/home.dart';
import 'package:memory_pager/screens/neighbor.dart';
import 'package:memory_pager/screens/onboarding_group.dart';
import 'package:memory_pager/screens/onboarding_name.dart';
import 'package:memory_pager/screens/onboarding_nickname.dart';
import 'package:memory_pager/screens/pet_house.dart';
import 'package:memory_pager/screens/report.dart';
import 'package:memory_pager/screens/settings.dart';
import 'package:memory_pager/screens/surprise.dart';
import 'package:memory_pager/screens/viewer.dart';
import 'package:memory_pager/shell.dart';
import 'package:memory_pager/theme.dart';

Future<void> _font(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = await File(p).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _shoot(WidgetTester tester, Widget screen, String name) async {
  await tester.pumpWidget(MaterialApp(theme: appTheme, home: screen));
  await tester.pump(const Duration(milliseconds: 60));
  // 사진 에셋 디코딩 완료를 기다린다.
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      final w = e.widget as Image;
      await precacheImage(w.image, e);
    }
  });
  await tester.pump(const Duration(milliseconds: 60));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    await _font('Pretendard', [
      'assets/fonts/Pretendard-Regular.ttf',
      'assets/fonts/Pretendard-SemiBold.ttf',
      'assets/fonts/Pretendard-Bold.ttf',
      'assets/fonts/Pretendard-ExtraBold.ttf',
    ]);
    await _font('Gaegu', [
      'assets/fonts/Gaegu-Regular.ttf',
      'assets/fonts/Gaegu-Bold.ttf',
    ]);
  });

  setUp(() => tester0Size());

  testWidgets('01 shell(home tab)', (t) => _shoot(t, const AppShell(), '01_shell_home'));
  testWidgets('02 onboarding name', (t) => _shoot(t, const OnboardingNameScreen(), '02_onboarding_name'));
  testWidgets('03 onboarding group', (t) => _shoot(t, const OnboardingGroupScreen(myName: '지우'), '03_onboarding_group'));
  testWidgets('04 nickname', (t) => _shoot(t, const NicknameScreen(myName: '지우'), '04_nickname'));
  testWidgets('05 home', (t) => _shoot(t, const HomeScreen(), '05_home'));
  testWidgets('06 draw canvas', (t) => _shoot(t, const DrawCanvasScreen(), '06_draw_canvas'));
  testWidgets('07 viewer', (t) => _shoot(t, ViewerScreen(doodle: mock.doodles.first), '07_viewer'));
  testWidgets('08 album', (t) => _shoot(t, const AlbumScreen(), '08_album'));
  testWidgets('09 calendar', (t) => _shoot(t, const CalendarScreen(), '09_calendar'));
  testWidgets('10 report', (t) => _shoot(t, const ReportScreen(), '10_report'));
  testWidgets('11 diary', (t) => _shoot(t, const DiaryScreen(), '11_diary'));
  testWidgets('12 pet house', (t) => _shoot(t, const PetHouseScreen(), '12_pet_house'));
  testWidgets('13 neighbor', (t) => _shoot(t, const NeighborScreen(), '13_neighbor'));
  testWidgets('14 settings', (t) => _shoot(t, const SettingsScreen(), '14_settings'));
  testWidgets('15 surprise', (t) => _shoot(t, const SurpriseScreen(), '15_surprise'));
  // 쓰다듬기 큐 그림 일기 — 장면별 손그림 시각 검증(시연용 팝업).
  testWidgets(
      '15b surprise scene0',
      (t) => _shoot(
          t,
          const SurpriseScreen(
              entry: DiaryEntry(
                  dateLabel: '7월 15일 맑음',
                  caption: '오늘은 둘이 한강을 걸었대. 나도 그 바람 같이 맞고 싶다.',
                  scene: 0)),
          '15b_surprise_scene0'));
  testWidgets(
      '15c surprise scene1',
      (t) => _shoot(
          t,
          const SurpriseScreen(
              entry: DiaryEntry(
                  dateLabel: '7월 14일 흐림',
                  caption: '또 떡볶이 얘기! 매콤한 게 그렇게 좋을까. 나도 한 입만…',
                  scene: 1)),
          '15c_surprise_scene1'));
  testWidgets(
      '15d surprise scene2',
      (t) => _shoot(
          t,
          const SurpriseScreen(
              entry: DiaryEntry(
                  dateLabel: '7월 13일 별밤',
                  caption: '밤에 나란히 앉아 별을 셌대. 다음엔 나도 꼭 끼워줘.',
                  scene: 2)),
          '15d_surprise_scene2'));
}

// 390x844 논리 픽셀, dpr 2 로 고정.
void tester0Size() {
  final b = TestWidgetsFlutterBinding.instance;
  b.platformDispatcher.views.first.physicalSize = const Size(780, 1688);
  b.platformDispatcher.views.first.devicePixelRatio = 2.0;
  addTearDown(() {
    b.platformDispatcher.views.first.resetPhysicalSize();
    b.platformDispatcher.views.first.resetDevicePixelRatio();
  });
}
