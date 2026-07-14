// 이웃 개성 시각 확인 — 이웃마다 색·모자가 달라 서로 다른 커플로 보이는지.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_pager/pet.dart';

void main() {
  testWidgets('neighbor personas', (tester) async {
    // neighbor.dart 의 _personas 와 동일 (색, 잉크, 펫, 커플, 모자).
    final personas = <(Color, Color, String, String, String?)>[
      (Color(0xFFB49BE0), Color(0xFF2E2440), '몽실', '달래 ♥ 보리', '🎀'),
      (Color(0xFFF3A6B8), Color(0xFF5A2A38), '초코', '토리 ♥ 마루', null),
      (Color(0xFFF6C270), Color(0xFF5A4020), '단추', '코코 ♥ 별이', '👑'),
      (Color(0xFF8FD0C0), Color(0xFF20463E), '두부', '하루 ♥ 나나', '🌱'),
      (Color(0xFF9FC0F0), Color(0xFF223A5A), '방울', '밤이 ♥ 솔이', '🧢'),
      (Color(0xFFC0D890), Color(0xFF3A4620), '감자', '유자 ♥ 미소', null),
      (Color(0xFFE0A0D0), Color(0xFF4A2044), '젤리', '앵두 ♥ 자두', '👒'),
      (Color(0xFFF0A98C), Color(0xFF5A3020), '마요', '노을 ♥ 바다', null),
    ];
    final cells = personas.map((p) {
      return Container(
        width: 200,
        height: 210,
        color: const Color(0xFFEDE6F5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 172,
              height: 160,
              child: PetFace(
                size: 172,
                color: p.$1,
                faceInk: p.$2,
                outfit: p.$5 == null
                    ? null
                    : PetOutfit(hat: (emoji: p.$5, name: null)),
              ),
            ),
            Text(p.$4, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        ),
      );
    }).toList();

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: RepaintBoundary(child: SizedBox(width: 820, child: Wrap(children: cells))),
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(RepaintBoundary).first, matchesGoldenFile('goldens/neighbors.png'));
  });
}
