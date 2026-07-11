// Memory Pager — 더보기 (More) menu (tab 3) + legacy CommHomeScreen alias.
//
// The old CommHomeScreen (poke + send + received log) folded into the new IA:
// the 홈 tab now owns 받은 편지 and the 함께 그림 그리기 loop, so this file becomes
// the 더보기 menu — a calm rounded list of the secondary destinations that used
// to clutter the home. [MoreScreen] is the real tab; [CommHomeScreen] is kept
// as a thin alias so any lingering reference still resolves (it simply renders
// [MoreScreen]).
//
// Renders inside the app shell's IndexedStack — NO back affordance, NO bottom
// nav of its own (AppShell owns [CpBottomNav]). Chrome is Material OUTLINED line
// icons, never emoji. Each row pushes a full-screen destination via Navigator.

import 'package:flutter/material.dart';

import '../components.dart';
import '../theme.dart';
import 'pet_explore.dart';
import 'pet_house.dart';
import 'pet_store.dart';
import 'settings.dart';
import 'widget_preview.dart';

/// The 더보기 tab: a clean rounded list of secondary destinations.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_MoreEntry>[
      _MoreEntry(
        Icons.storefront_outlined,
        '스토어',
        '아이템을 구경하고 사요',
        () => const PetStoreScreen(),
      ),
      _MoreEntry(
        Icons.cottage_outlined,
        '집 꾸미기',
        '펫의 집을 꾸미고 배치해요',
        () => const PetHouseScreen(),
      ),
      _MoreEntry(
        Icons.pets_outlined,
        '다른 그룹 펫',
        '다른 커플의 펫을 구경해요',
        () => const PetExploreScreen(),
      ),
      _MoreEntry(
        Icons.widgets_outlined,
        '홈 위젯',
        '잠금화면에 뜰 최근 낙서를 봐요',
        () => const WidgetPreviewScreen(),
      ),
      _MoreEntry(
        Icons.settings_outlined,
        '설정',
        '별명 · 그룹 · 알림을 관리해요',
        () => const SettingsScreen(),
      ),
    ];

    return CpScaffold(
      title: '더보기',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          CpMatted(
            mat: 6,
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  _MoreRow(entry: entries[i]),
                  if (i != entries.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: CpHair(opacity: 0.06),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One destination in [MoreScreen]: a line [icon], a [label] + [subtitle], and a
/// [build] that produces the full-screen target to push.
class _MoreEntry {
  const _MoreEntry(this.icon, this.label, this.subtitle, this.build);

  final IconData icon;
  final String label;
  final String subtitle;
  final Widget Function() build;
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.entry});

  final _MoreEntry entry;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => entry.build()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cpEucA(0.10),
                borderRadius: BorderRadius.circular(cpRadiusSmall),
              ),
              child: Icon(entry.icon, size: 21, color: cpEuc),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: cpSans(size: 15, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.subtitle,
                    style: cpSans(size: 12, color: cpInkA(0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: cpInkA(0.3)),
          ],
        ),
      ),
    );
  }
}

/// Legacy alias — [CommHomeScreen] is no longer a tab. Kept so any lingering
/// reference resolves; it simply renders the [MoreScreen] content.
class CommHomeScreen extends StatelessWidget {
  const CommHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const MoreScreen();
}
