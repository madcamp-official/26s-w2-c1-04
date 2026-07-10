// Memory Pager — Flutter app (Android). Real screens are built per docs/API.md.
import 'package:flutter/material.dart';

void main() => runApp(const MemoryPagerApp());

class MemoryPagerApp extends StatelessWidget {
  const MemoryPagerApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'Memory Pager',
        home: Scaffold(body: Center(child: Text('Memory Pager'))),
      );
}
