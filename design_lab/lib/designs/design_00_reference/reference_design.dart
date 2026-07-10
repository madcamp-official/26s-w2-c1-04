// design_00_reference — a neutral Material 3 baseline.
//
// Purpose: (1) prove the harness compiles & renders, (2) act as a TEMPLATE that
// shows every content element each hero screen must contain. The 10 generated
// designs replace this look entirely but keep the same content coverage.

import 'package:flutter/material.dart';
import '../../shared/design_variant.dart';
import '../../shared/models.dart';

class ReferenceDesign extends DesignVariant {
  @override
  String get id => '00';
  @override
  String get name => 'Reference · Material Baseline';
  @override
  String get concept => '중립적인 Material 3 기준선 — 콘텐츠 커버리지 확인용 템플릿.';
  @override
  String get signature => '모드 토글(일반/사라지기) + 펜 팔레트 기본 구현.';
  @override
  String get inspiration => 'Flutter Material 3 defaults';
  @override
  Color get accent => const Color(0xFF6750A4);
  @override
  Brightness get brightness => Brightness.light;

  @override
  Widget build(BuildContext context, HeroScreen screen, AppData data) {
    final theme = ThemeData(
      colorSchemeSeed: accent,
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: 'Roboto',
    );
    return Theme(
      data: theme,
      child: switch (screen) {
        HeroScreen.drawSend => _DrawSend(data: data),
        HeroScreen.petHome => _PetHome(data: data),
        HeroScreen.memoryAlbum => _MemoryAlbum(data: data),
      },
    );
  }
}

// ------------------------------------------------------------------ Draw & Send
class _DrawSend extends StatefulWidget {
  const _DrawSend({required this.data});
  final AppData data;
  @override
  State<_DrawSend> createState() => _DrawSendState();
}

class _DrawSendState extends State<_DrawSend> {
  int pen = 1;
  double thickness = 6;
  SendMode mode = SendMode.normal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('${widget.data.couple.partnerNickname}에게'),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text('보내기'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF6F3FF), Color(0xFFEDE7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: const Center(
                  child: Text('✏️  캔버스', style: TextStyle(fontSize: 18, color: Colors.black38)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // pen palette
            Row(
              children: [
                for (int i = 0; i < demoPenColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => pen = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: demoPenColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: pen == i ? cs.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.line_weight_rounded, size: 20),
                Expanded(
                  child: Slider(
                    value: thickness,
                    min: 1,
                    max: 20,
                    onChanged: (v) => setState(() => thickness = v),
                  ),
                ),
              ],
            ),
            // mode toggle
            SegmentedButton<SendMode>(
              segments: const [
                ButtonSegment(value: SendMode.normal, label: Text('일반'), icon: Icon(Icons.push_pin_rounded)),
                ButtonSegment(value: SendMode.disappearing, label: Text('사라지기'), icon: Icon(Icons.timer_rounded)),
              ],
              selected: {mode},
              onSelectionChanged: (s) => setState(() => mode = s.first),
            ),
            const SizedBox(height: 6),
            Text(mode.description, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _tool(Icons.photo_library_rounded, '갤러리'),
                _tool(Icons.photo_camera_rounded, '사진'),
                _tool(Icons.notifications_active_rounded, '찌르기'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tool(IconData i, String l) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(onPressed: () {}, icon: Icon(i)),
          Text(l, style: const TextStyle(fontSize: 11)),
        ],
      );
}

// -------------------------------------------------------------------- Pet Home
class _PetHome extends StatefulWidget {
  const _PetHome({required this.data});
  final AppData data;
  @override
  State<_PetHome> createState() => _PetHomeState();
}

class _PetHomeState extends State<_PetHome> {
  bool patted = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pet = widget.data.pet;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text('${pet.name} · Lv.${pet.level}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: const Text('🪙'),
                label: Text('${pet.coins}'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (patted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(pet.speech),
                    ),
                  GestureDetector(
                    onTap: () => setState(() => patted = !patted),
                    child: Text('${pet.moodEmoji}${pet.moodEmoji}', style: const TextStyle(fontSize: 96)),
                  ),
                  const SizedBox(height: 8),
                  const Text('쓰다듬어 보세요', style: TextStyle(color: Colors.black38, fontSize: 12)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 220,
                    child: Column(
                      children: [
                        LinearProgressIndicator(value: pet.growth, minHeight: 8),
                        const SizedBox(height: 4),
                        Text('다음 레벨까지 ${(pet.growth * 100).round()}%', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // store
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('스토어', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: const Text('전체보기')),
                  ],
                ),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: pet.store.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final it = pet.store[i];
                      return Container(
                        width: 80,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: it.equipped ? cs.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(it.emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(it.owned ? (it.equipped ? '착용중' : '보유') : '🪙${it.price}',
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _RefNav(current: 0),
    );
  }
}

// ---------------------------------------------------------------- Memory Album
class _MemoryAlbum extends StatefulWidget {
  const _MemoryAlbum({required this.data});
  final AppData data;
  @override
  State<_MemoryAlbum> createState() => _MemoryAlbumState();
}

class _MemoryAlbumState extends State<_MemoryAlbum> {
  bool byDate = true;
  DoodleType? filter;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = widget.data.album.where((d) => filter == null || d.type == filter).toList();
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('낙서 사진첩'),
        actions: [
          TextButton(
            onPressed: () => setState(() => byDate = !byDate),
            child: Text(byDate ? '날짜별' : '유형별'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('전체', filter == null, () => setState(() => filter = null)),
                for (final t in DoodleType.values)
                  _chip(t.label, filter == t, () => setState(() => filter = t)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final d = items[i];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(colors: d.swatch),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(d.type.icon, color: Colors.white, size: 16),
                          const Spacer(),
                          if (d.liked) const Icon(Icons.favorite, color: Colors.white, size: 16),
                        ],
                      ),
                      const Spacer(),
                      Text(d.emoji, style: const TextStyle(fontSize: 40)),
                      const Spacer(),
                      Text(d.caption,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${d.author} · ${d.at.month}/${d.at.day}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _RefNav(current: 1),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(label: Text(label), selected: sel, onSelected: (_) => onTap()),
      );
}

class _RefNav extends StatelessWidget {
  const _RefNav({required this.current});
  final int current;
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: current,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.pets_rounded), label: '펫 키우기'),
        NavigationDestination(icon: Icon(Icons.photo_library_rounded), label: '사진첩'),
        NavigationDestination(icon: Icon(Icons.forum_rounded), label: '소통'),
      ],
    );
  }
}
