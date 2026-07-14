// #5 시각 검증용 골든 — 꾸미기 아이템이 펫 몸에 맞게 그려지는지 직접 렌더해서 본다.
// 실행: flutter test --update-goldens test/pet_golden_test.dart
// 생성물: test/goldens/*.png 를 눈으로 확인한다(둥둥 뜬 이모지·하얀 테두리 없어야 함).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_pager/api.dart';
import 'package:memory_pager/mock.dart';
import 'package:memory_pager/pet.dart';

Widget _cell(String label, Widget child, {Color bg = const Color(0xFFF3EDE6)}) {
  return Container(
    width: 150,
    height: 176,
    color: bg,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 130, height: 130, child: Center(child: child)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    ),
  );
}

PetOutfit _hat(String e) => PetOutfit(hat: (emoji: e, name: null));
PetOutfit _cloth(String e) => PetOutfit(clothes: (emoji: e, name: null));
PetOutfit _acc(String e) => PetOutfit(acc: (emoji: e, name: null));

void main() {
  testWidgets('worn items grid', (tester) async {
    final cells = <Widget>[
      // 모자 7종
      _cell('중절모 🎩', const PetFace(size: 120)),
      ...[
        ['중절모 🎩', '🎩'],
        ['비니 🧢', '🧢'],
        ['밀짚 👒', '👒'],
        ['베레 🍓', '🍓'],
        ['리본 🎀', '🎀'],
        ['새싹 🌱', '🌱'],
        ['왕관 👑', '👑'],
      ].map((h) => _cell(h[0], PetFace(size: 120, outfit: _hat(h[1])))),
      // 옷 5종
      ...[
        ['티셔츠 👕', '👕'],
        ['후드 🧥', '🧥'],
        ['원피스 👗', '👗'],
        ['정장 🤵', '🤵'],
        ['우주복 🚀', '🚀'],
      ].map((c) => _cell(c[0], PetFace(size: 120, outfit: _cloth(c[1])))),
      // 액세서리 4종
      ...[
        ['안경 👓', '👓'],
        ['선글 🕶️', '🕶️'],
        ['목도리 🧣', '🧣'],
        ['가방 🎒', '🎒'],
      ].map((a) => _cell(a[0], PetFace(size: 120, outfit: _acc(a[1])))),
      // 조합
      _cell(
        '왕관+정장+안경',
        const PetFace(
          size: 120,
          outfit: PetOutfit(
            hat: (emoji: '👑', name: null),
            clothes: (emoji: '🤵', name: null),
            acc: (emoji: '👓', name: null),
          ),
        ),
      ),
      _cell(
        '밀짚+원피스+목도리',
        const PetFace(
          size: 120,
          outfit: PetOutfit(
            hat: (emoji: '👒', name: null),
            clothes: (emoji: '👗', name: null),
            acc: (emoji: '🧣', name: null),
          ),
        ),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: RepaintBoundary(
            child: SizedBox(
              width: 1050,
              child: Wrap(children: cells),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/worn.png'),
    );
  });

  testWidgets('full room scenes', (tester) async {
    // DecoratedPet 은 mock 에서 착용 아이템을 읽는다 — 테스트용으로 채운다.
    mock.api = Api('http://localhost:0');
    Widget scene(String key, List<StoreItem> items) {
      mock.storeItems
        ..clear()
        ..addAll(items);
      return SizedBox(
        width: 230,
        height: 230,
        // 씬마다 고유 key — const 재사용으로 mock 변경이 무시되지 않게(골든 전용).
        child: DecoratedPet(key: ValueKey(key), size: 220),
      );
    }

    StoreItem it(String cat, String emoji) =>
        StoreItem(emoji, 0, category: cat, emoji: emoji, wearing: true, owned: true);

    // 각 씬을 개별 골든으로 — mock 이 공유라 순차 렌더.
    for (final s in [
      ['scene_party', [it('hat', '👑'), it('clothes', '👗'), it('accessory', '👓'), it('background', '🌸'), it('furniture', '🪴'), it('prop', '🍰')]],
      ['scene_night', [it('hat', '🧢'), it('clothes', '🧥'), it('accessory', '🧣'), it('background', '🌌'), it('furniture', '🔥'), it('prop', '🎁')]],
      ['scene_beach', [it('hat', '👒'), it('clothes', '👕'), it('accessory', '🕶️'), it('background', '🏖'), it('furniture', '📚'), it('prop', '🎈')]],
    ]) {
      final name = s[0] as String;
      final items = (s[1] as List).cast<StoreItem>();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFFFFF6F1),
            body: Center(child: RepaintBoundary(child: scene(name, items))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/$name.png'),
      );
    }
  });
}
