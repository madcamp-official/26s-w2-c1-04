// Memory Pager — Pet home (tab 0 · '펫키우기').
//
// The default landing tab: the live pet, its activity/utterance, level growth,
// worn items, and the entry links out to the rest of the pet world. Renders
// inside the app shell's IndexedStack — it owns NO bottom nav and NO back
// affordance (the shell provides both). State comes from the global [appState];
// every mutation goes through an [appState] action and REST stays the truth.

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../components.dart';
import '../pet_view.dart';
import '../theme.dart';
import 'monthly_report.dart';
import 'pet_diary.dart';
import 'pet_explore.dart';
import 'pet_house.dart';
import 'pet_store.dart';
import 'settings.dart';

// The app<->server contract exposes no level curve, so we can't know the exact
// exp span of a level. The growth bar is a *display normalization* of the real
// [Pet.exp] — a fixed 100-exp span per level — never a second, invented number.
// Level-ups themselves ride the realtime `pet:level_up` event, not this bar.
const int _kExpPerLevel = 100;

class PetHomeScreen extends StatelessWidget {
  const PetHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CpScaffold(body: _PetHomeBody());
  }
}

// ===========================================================================
// Body — the one stateful piece (pat interaction + press feedback)
// ===========================================================================

class _PetHomeBody extends StatefulWidget {
  const _PetHomeBody();

  @override
  State<_PetHomeBody> createState() => _PetHomeBodyState();
}

class _PetHomeBodyState extends State<_PetHomeBody> {
  /// Bumped on every pat so the speech slip re-fades even when the pet repeats
  /// the same cached line.
  int _patSeq = 0;

  /// Quiet press feedback on the portrait.
  bool _pressed = false;

  Future<void> _pat() async {
    if (appState.pet == null) return;
    try {
      await appState.pat(); // currentUtterance + exp already reflected in state
      if (!mounted) return;
      setState(() => _patSeq++);
      // r.utterance == appState.currentUtterance now; r.expGained already added.
    } on ApiException catch (_) {
      // Contract edge (e.g. 404 not_found): stay quiet, invent no reply.
    } on StateError catch (_) {
      // Pet vanished between guard and call — no-op.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final pet = appState.pet;
        if (pet == null) {
          return const Center(
            child: CpEmptyState(
              icon: Icons.pets_outlined,
              text: '펫을 불러오는 중이에요',
            ),
          );
        }

        // Prefer the socket fast-path activity; fall back to the REST snapshot.
        final activity = appState.currentActivity ?? pet.currentActivity?.activity;
        final utterance = appState.currentUtterance;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(pet: pet),
              const SizedBox(height: 30),
              _Portrait(
                speciesId: appState.petSpecies,
                pressed: _pressed,
                onPat: _pat,
                onPressChanged: (v) => setState(() => _pressed = v),
              ),
              const SizedBox(height: 14),
              Center(child: CpEyebrow('탭하여 쓰다듬기', size: 9)),
              const SizedBox(height: 20),
              _SpeechArea(utterance: utterance, seq: _patSeq),
              const SizedBox(height: 20),
              _ActivityLabel(mood: _moodGlyph(activity), activity: activity),
              const SizedBox(height: 26),
              Center(
                child: _Growth(level: pet.level, exp: pet.exp),
              ),
              const SizedBox(height: 32),
              const CpHair(),
              const SizedBox(height: 24),
              _EquippedSection(items: pet.equippedItems),
              const SizedBox(height: 32),
              const CpHair(),
              const SizedBox(height: 24),
              const _LinksSection(),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================================
// Header — name · Lv · coins
// ===========================================================================

class _Header extends StatelessWidget {
  const _Header({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CpEyebrow('내 펫'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      pet.name,
                      overflow: TextOverflow.ellipsis,
                      style: cpSans(size: 24, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _LvBadge(pet.level),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CpCoins(pet.coins),
      ],
    );
  }
}

class _LvBadge extends StatelessWidget {
  const _LvBadge(this.level);

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cpEucA(0.12),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: cpEucA(0.5), width: 0.5),
      ),
      child: Text(
        'LV $level',
        style: cpSans(
          size: 11,
          color: cpEuc,
          weight: FontWeight.w600,
          spacing: 1.2,
        ),
      ),
    );
  }
}

// ===========================================================================
// Portrait — the matted pet, tap to pat
// ===========================================================================

class _Portrait extends StatelessWidget {
  const _Portrait({
    required this.speciesId,
    required this.pressed,
    required this.onPat,
    required this.onPressChanged,
  });

  final String speciesId;
  final bool pressed;
  final Future<void> Function() onPat;
  final ValueChanged<bool> onPressChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPat,
        onTapDown: (_) => onPressChanged(true),
        onTapUp: (_) => onPressChanged(false),
        onTapCancel: () => onPressChanged(false),
        child: AnimatedScale(
          scale: pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: SizedBox(
            width: 220,
            child: CpMatted(
              mat: 20,
              inset: 0,
              child: SizedBox(
                height: 180,
                child: Center(
                  child: PetView(speciesId: speciesId, size: 170),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Speech — the pat utterance, faded via an AnimatedSwitcher
// ===========================================================================

class _SpeechArea extends StatelessWidget {
  const _SpeechArea({required this.utterance, required this.seq});

  /// The pet's current line (from a pat or a socket activity change). Null until
  /// the pet has spoken — then we honestly show a prompt, not a fake line.
  final String? utterance;
  final int seq;

  @override
  Widget build(BuildContext context) {
    final Widget child = (utterance != null && utterance!.isNotEmpty)
        ? CpSpeechSlip(utterance!, key: ValueKey('slip/$seq/$utterance'))
        : Padding(
            key: const ValueKey('prompt'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '펫을 쓰다듬어 인사를 나눠보세요',
              textAlign: TextAlign.center,
              style: cpSans(size: 13, color: cpInkA(0.4)),
            ),
          );

    return SizedBox(
      height: 56,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: child,
        ),
      ),
    );
  }
}

// ===========================================================================
// Activity label — current_activity.activity
// ===========================================================================

class _ActivityLabel extends StatelessWidget {
  const _ActivityLabel({required this.mood, required this.activity});

  final String mood;
  final PetActivityKind? activity;

  @override
  Widget build(BuildContext context) {
    // Honest empty state when the pet has no activity yet — no invented status.
    final label = activity == null ? '아직 활동이 없어요' : _activityLabel(activity!);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cpPrint,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: cpInkA(0.10), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 9),
            Text(
              label,
              style: cpSans(size: 12, color: cpInkA(0.7), weight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Growth — exp toward the next level
// ===========================================================================

class _Growth extends StatelessWidget {
  const _Growth({required this.level, required this.exp});

  final int level;
  final int exp;

  @override
  Widget build(BuildContext context) {
    final into = ((exp % _kExpPerLevel) + _kExpPerLevel) % _kExpPerLevel;
    final growth = into / _kExpPerLevel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CpGrowth(growth, levelLabel: 'LV $level · 다음 레벨'),
        const SizedBox(height: 8),
        Text(
          '$into / $_kExpPerLevel EXP',
          style: cpSans(size: 10, color: cpInkA(0.4), spacing: 0.4),
        ),
      ],
    );
  }
}

// ===========================================================================
// Equipped items
// ===========================================================================

class _EquippedSection extends StatelessWidget {
  const _EquippedSection({required this.items});

  final List<EquippedItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CpEyebrow('착용 아이템'),
        const SizedBox(height: 14),
        if (items.isEmpty)
          Text(
            '착용한 아이템이 없어요',
            style: cpSans(size: 13, color: cpInkA(0.4)),
          )
        else
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [for (final it in items) _EquipChip(it)],
          ),
      ],
    );
  }
}

class _EquipChip extends StatelessWidget {
  const _EquipChip(this.item);

  final EquippedItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cpPrint,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: cpInkA(0.12), width: 0.5),
          ),
          child: Text(
            _catGlyph(item.category),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _catLabel(item.category),
          style: cpSans(size: 10, color: cpInkA(0.55), spacing: 0.4),
        ),
      ],
    );
  }
}

// ===========================================================================
// Links — entry points out to the rest of the pet world (each pushes)
// ===========================================================================

class _LinksSection extends StatelessWidget {
  const _LinksSection();

  @override
  Widget build(BuildContext context) {
    final links = <_LinkSpec>[
      _LinkSpec('🛍️', '스토어', () => const PetStoreScreen(), accent: true),
      _LinkSpec('📔', '일기장', () => const PetDiaryScreen()),
      _LinkSpec('📊', '월간 레포트', () => const MonthlyReportScreen()),
      _LinkSpec('🏠', '집 꾸미기', () => const PetHouseScreen()),
      _LinkSpec('🐾', '다른 그룹 펫', () => const PetExploreScreen()),
      _LinkSpec('⚙️', '설정', () => const SettingsScreen()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CpEyebrow('바로가기'),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            const cols = 3;
            const gap = 12.0;
            final w = (c.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: 22,
              children: [
                for (final l in links)
                  SizedBox(
                    width: w,
                    child: CpAction(
                      glyph: l.glyph,
                      label: l.label,
                      accent: l.accent,
                      onTap: () => _push(context, l.build()),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LinkSpec {
  const _LinkSpec(this.glyph, this.label, this.build, {this.accent = false});

  final String glyph;
  final String label;
  final Widget Function() build;
  final bool accent;
}

// ===========================================================================
// Helpers
// ===========================================================================

void _push(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}

/// Korean label for the pet's current activity. The [PetActivityKind] enum
/// already folds unknown wire values into [PetActivityKind.waiting], so this
/// switch is exhaustive and never crashes on a future activity name.
String _activityLabel(PetActivityKind a) => switch (a) {
      PetActivityKind.eating => '밥 먹는 중',
      PetActivityKind.sleeping => '자는 중',
      PetActivityKind.walking => '산책 중',
      PetActivityKind.playing => '노는 중',
      PetActivityKind.drawing => '그림 그리는 중',
      PetActivityKind.waiting => '기다리는 중',
    };

/// A mood glyph standing in for the (asset-less) pet portrait, keyed to what it
/// is doing. Null activity → a neutral face (never a fabricated mood).
String _moodGlyph(PetActivityKind? a) => switch (a) {
      PetActivityKind.eating => '😋',
      PetActivityKind.sleeping => '😴',
      PetActivityKind.walking => '🚶',
      PetActivityKind.playing => '😆',
      PetActivityKind.drawing => '🎨',
      PetActivityKind.waiting => '🙂',
      null => '🙂',
    };

/// Category glyph for a worn item. [ItemCategory] folds unknown values into
/// [ItemCategory.prop], so this switch is exhaustive.
String _catGlyph(ItemCategory c) => switch (c) {
      ItemCategory.clothes => '👕',
      ItemCategory.hat => '🎩',
      ItemCategory.accessory => '🎀',
      ItemCategory.furniture => '🪑',
      ItemCategory.background => '🖼️',
      ItemCategory.prop => '🧸',
    };

String _catLabel(ItemCategory c) => switch (c) {
      ItemCategory.clothes => '의상',
      ItemCategory.hat => '모자',
      ItemCategory.accessory => '악세서리',
      ItemCategory.furniture => '가구',
      ItemCategory.background => '배경',
      ItemCategory.prop => '소품',
    };
