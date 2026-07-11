// Charlab gallery — a separate entrypoint for exploring the hand-drawn pet
// characters, kept out of the real app. Run/build with:
//   flutter run   -d chrome -t lib/charlab_main.dart
//   flutter build web        -t lib/charlab_main.dart
//
// QA deep-links:
//   ?c=03            select character 03
//   ?c=03&solo=1     render only that character (no chrome) — for screenshots
//   ?c=03&t=0.42     freeze the idle loop at phase 0.42 (deterministic frame)

import 'package:flutter/material.dart';

import 'charlab/registry.dart';
import 'charlab/toolkit.dart';

void main() => runApp(const CharlabApp());

class CharlabApp extends StatelessWidget {
  const CharlabApp({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Uri.base.queryParameters;
    final solo = p['solo'] == '1';
    final t = double.tryParse(p['t'] ?? '');
    final id = p['c'];
    var idx = id == null ? 0 : characters.indexWhere((c) => c.id == id);
    if (idx < 0) idx = 0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Charlab · Pet Characters',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      home: solo
          ? _Solo(character: characters[idx], frozenT: t)
          : GalleryPage(initial: idx, frozenT: t),
    );
  }
}

/// The neutral paper stage every character sits on.
const _paper = Color(0xFFF3EFE6);

class _Solo extends StatelessWidget {
  const _Solo({required this.character, this.frozenT});
  final PetCharacter character;
  final double? frozenT;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: Center(
        child: SizedBox(
          width: 360,
          height: 360,
          child: character.build(context, frozenT: frozenT),
        ),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, this.initial = 0, this.frozenT});
  final int initial;
  final double? frozenT;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late int _sel = widget.initial;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 820;
    final c = characters[_sel];
    return Scaffold(
      backgroundColor: const Color(0xFF15161A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1E24),
        foregroundColor: Colors.white,
        title: Text('Charlab · 펫 캐릭터 (${characters.length}종)'),
      ),
      body: Row(
        children: [
          if (wide) SizedBox(width: 300, child: _list()),
          Expanded(
            child: Column(
              children: [
                _info(c),
                Expanded(child: Center(child: _stage(c))),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide ? null : SizedBox(height: 96, child: _stripList()),
    );
  }

  Widget _stage(PetCharacter c) {
    return Container(
      margin: const EdgeInsets.all(24),
      width: 380,
      height: 380,
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 30)],
      ),
      clipBehavior: Clip.antiAlias,
      child: c.build(context, frozenT: widget.frozenT),
    );
  }

  Widget _info(PetCharacter c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        color: const Color(0xFF1C1E24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('#${c.id}  ${c.name}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: 4),
            Text(c.concept, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 2),
            Text('✦ ${c.signature}', style: TextStyle(color: c.accent, fontSize: 12)),
          ],
        ),
      );

  Widget _list() => ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: characters.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final c = characters[i];
          final sel = i == _sel;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _sel = i),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: sel ? c.accent.withValues(alpha: 0.18) : const Color(0xFF1C1E24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sel ? c.accent : Colors.white10, width: sel ? 2 : 1),
              ),
              child: Row(children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(10)),
                    child: c.build(context, frozenT: 0.2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('#${c.id}  ${c.name}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(c.concept,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ]),
            ),
          );
        },
      );

  Widget _stripList() => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount: characters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = characters[i];
          final sel = i == _sel;
          return GestureDetector(
            onTap: () => setState(() => _sel = i),
            child: Container(
              width: 64,
              decoration: BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? c.accent : Colors.white24, width: sel ? 2 : 1),
              ),
              child: c.build(context, frozenT: 0.2),
            ),
          );
        },
      );
}
