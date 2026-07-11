// PetPicker — choose which drawn character is your pet.
//
// A calm grid of the 5 roster species, each shown live-animated at thumbnail
// size. Picking one calls `appState.setPetSpecies` (a client-local preference —
// it changes the drawing, not any server-owned pet data). Used as a full screen
// from settings and as a step during onboarding.

import 'package:flutter/material.dart';

import '../../charlab/roster.dart';
import '../../core/app_state.dart';
import '../components.dart';
import '../pet_view.dart';
import '../theme.dart';

/// Korean display names + one-line personality per species.
const Map<String, (String, String)> _blurb = {
  'bear': ('고미', '느긋한 아기 꿀곰'),
  'hamster': ('햄찌', '볼 빵빵 부지런이'),
  'seal': ('말랑', '뽀얀 물범 아기'),
  'sprout': ('새콩이', '갓 돋은 새싹 콩'),
  'mochi': ('말랑이', '말랑말랑 떡'),
};

/// The picker as its own screen (settings entry / standalone).
class PetPickerScreen extends StatelessWidget {
  const PetPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CpScaffold(
      title: '펫 고르기',
      leading: CpIconButton(
        icon: Icons.arrow_back,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      body: const SafeArea(child: PetPickerBody(padding: EdgeInsets.all(24))),
    );
  }
}

/// The reusable picker grid — embeddable in onboarding too.
class PetPickerBody extends StatelessWidget {
  const PetPickerBody({
    super.key,
    this.padding = EdgeInsets.zero,
    this.onPicked,
  });

  final EdgeInsets padding;
  final ValueChanged<String>? onPicked;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final selected = appState.petSpecies;
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: PetView(speciesId: selected, size: 150),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _blurb[selected]?.$1 ?? '',
                  style: cpSans(size: 18, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _blurb[selected]?.$2 ?? '',
                  style: cpSans(size: 12, color: cpInkA(0.5)),
                ),
              ),
              const SizedBox(height: 24),
              const CpHair(),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
                children: [
                  for (final s in petRoster)
                    _PickTile(
                      species: s,
                      selected: s.id == selected,
                      onTap: () {
                        appState.setPetSpecies(s.id);
                        onPicked?.call(s.id);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.species,
    required this.selected,
    required this.onTap,
  });

  final PetSpecies species;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? cpEucA(0.10) : cpPrint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? cpEuc : cpInkA(0.10),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              // Freeze the thumbnails at a pleasant frame so five animations
              // don't all run in the grid; the big preview above is live.
              child: PetView(speciesId: species.id, size: 84, frozenT: 0.25),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _blurb[species.id]?.$1 ?? species.name,
                style: cpSans(
                  size: 11,
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? cpInk : cpInkA(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
