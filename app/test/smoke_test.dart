// Memory Pager — smoke test: the app shell mounts a MaterialApp.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_pager/app.dart';

void main() {
  testWidgets('MemoryPagerApp mounts a MaterialApp', (tester) async {
    // The app boots an already-onboarded mock AppState whose realtime layer
    // starts a periodic timer once bootstrap finishes. Pump inside runAsync so
    // any such timers are REAL (not FakeAsync) and the pending-timer guard the
    // test framework runs at teardown stays clean.
    await tester.runAsync(() async {
      await tester.pumpWidget(const MemoryPagerApp());
    });

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
