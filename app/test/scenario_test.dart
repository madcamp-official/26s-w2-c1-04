// 완성도 평가 — 디자인 인터랙션 8종을 실제로 구동해 결과를 검증한다.
//   flutter test test/scenario_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_pager/main.dart';
import 'package:memory_pager/mock.dart';
import 'package:memory_pager/pet.dart';
import 'package:memory_pager/screens/draw_canvas.dart';
import 'package:memory_pager/screens/pet_house.dart';
import 'package:memory_pager/screens/settings.dart';
import 'package:memory_pager/screens/viewer.dart';
import 'package:memory_pager/shell.dart';
import 'package:memory_pager/theme.dart';

Widget _wrap(Widget home) => MaterialApp(theme: appTheme, home: home);

void main() {
  testWidgets('S1 콕 찌르기 → 오늘 카운트 증가', (t) async {
    await t.pumpWidget(_wrap(const AppShell()));
    await t.pump();
    final before = mock.pokesToday;
    await t.tap(find.text('콕 찌르기'));
    await t.pump();
    expect(mock.pokesToday, before + 1);
    expect(find.text('오늘 ${before + 1}번'), findsOneWidget);
  });

  testWidgets('S2 펫 5번 쓰다듬기 → 깜짝 낙서 화면', (t) async {
    await t.pumpWidget(_wrap(const AppShell()));
    await t.pump();
    // 펫 얼굴을 5번 탭 → 5번째에 깜짝 낙서로 push.
    final pet = find.byType(PetFace);
    expect(pet, findsWidgets);
    for (var i = 0; i < 5; i++) {
      await t.tap(pet.first);
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.pumpAndSettle();
    expect(find.text('모리가 그림을 그렸어요'), findsOneWidget);
  });

  testWidgets('S3 오늘의 질문 답변 저장', (t) async {
    mock.myAnswer = null;
    await t.pumpWidget(_wrap(const AppShell()));
    await t.pump();
    await t.tap(find.text('내 답변을 남겨보세요…'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, '억새밭 첫 데이트!');
    await t.tap(find.text('남기기'));
    await t.pumpAndSettle();
    expect(mock.myAnswer, '억새밭 첫 데이트!');
    expect(find.text('억새밭 첫 데이트!'), findsOneWidget);
  });

  testWidgets('S4 사라지기 낙서 5초 뒤 소멸 (SD-6)', (t) async {
    final eph = Doodle(
      id: 'test-eph',
      fromMe: false,
      type: DoodleType.text,
      text: '곧 사라져요',
      when: '방금 전',
      ephemeral: true,
      viewed: false,
    );
    mock.doodles.insert(0, eph);
    await t.pumpWidget(_wrap(ViewerScreen(doodle: eph)));
    await t.pump();
    expect(mock.doodles.contains(eph), isTrue);
    // 카운트다운 6초 진행.
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(mock.doodles.contains(eph), isFalse, reason: '5초 뒤 목록에서 제거돼야 함');
  });

  testWidgets('S5 낙서 캔버스 → 보내면 앨범에 추가', (t) async {
    final before = mock.doodles.length;
    await t.pumpWidget(_wrap(const DrawCanvasScreen()));
    await t.pump();
    await t.tap(find.text('나무에게 보내기'));
    await t.pump();
    expect(mock.doodles.length, greaterThan(before));
    expect(mock.doodles.first.fromMe, isTrue);
  });

  testWidgets('S6 설정 배경색 변경 → roomColor 반영', (t) async {
    await t.pumpWidget(_wrap(const SettingsScreen()));
    await t.pump();
    final before = mock.roomColor;
    // 배경 색상 스와치(원형) 중 두 번째를 탭.
    final swatches = find.byType(GestureDetector);
    // 스와치를 색으로 특정하기 어려우니, setRoomColor 를 부르는 탭을 순회.
    var changed = false;
    for (var i = 0; i < swatches.evaluate().length && !changed; i++) {
      await t.tap(swatches.at(i), warnIfMissed: false);
      await t.pump();
      if (mock.roomColor != before) changed = true;
    }
    expect(changed, isTrue, reason: '스와치 탭으로 roomColor 가 바뀌어야 함');
    expect(roomColors.contains(mock.roomColor), isTrue);
  });

  testWidgets('S7 펫 집 → 모자 착용 변경', (t) async {
    // 처음엔 중절모 착용.
    expect(mock.hats.first.wearing, isTrue);
    await t.pumpWidget(_wrap(const PetHouseScreen()));
    await t.pump();
    await t.tap(find.text('밀짚모자'), warnIfMissed: false);
    await t.pump();
    expect(mock.hats.firstWhere((h) => h.name == '밀짚모자').wearing, isTrue);
    expect(mock.hats.first.wearing, isFalse, reason: '중절모는 벗겨져야 함');
  });

  testWidgets('S8 온보딩: 이름 → 그룹 화면 진입', (t) async {
    mock.onboarded = false;
    await t.pumpWidget(const MemoryPagerApp());
    await t.pump();
    expect(find.text('Memory Pager'), findsWidgets);
    await t.enterText(find.byType(TextField).first, '세온');
    await t.tap(find.text('시작하기'));
    await t.pumpAndSettle();
    expect(find.textContaining('둘만의 그룹'), findsOneWidget);
    mock.onboarded = true; // 복원
  });
}
