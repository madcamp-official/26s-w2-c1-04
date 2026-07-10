// Smoke test: the design gallery boots and shows its title + a phone frame.

import 'package:flutter_test/flutter_test.dart';

import 'package:memory_pager/main.dart';
import 'package:memory_pager/registry.dart';

void main() {
  testWidgets('Gallery boots and renders a phone frame', (tester) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pump();

    expect(find.textContaining('디자인 비교'), findsOneWidget);
    expect(find.byType(PhoneFrame), findsOneWidget);
    expect(designs, isNotEmpty);
  });
}
