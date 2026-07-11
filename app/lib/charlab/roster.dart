// The chosen pet roster — the 5 characters the couple can pick from.
//
// Selected from the 10-character exploration: bear, hamster, seal, sprout,
// mochi. Each is keyed by a stable species id so a saved pick survives, and
// exposes its animated [PetCharacter]. The real app renders the couple's chosen
// species as their live pet.

import 'toolkit.dart';
import 'characters/char_03_bear.dart';
import 'characters/char_05_hamster.dart';
import 'characters/char_06_seal.dart';
import 'characters/char_09_sprout.dart';
import 'characters/char_10_mochi.dart';

/// A pickable pet species: a stable id + its character.
class PetSpecies {
  const PetSpecies(this.id, this.character);
  final String id;
  final PetCharacter character;

  String get name => character.name;
}

/// The 5 chosen species, in display order.
final List<PetSpecies> petRoster = <PetSpecies>[
  PetSpecies('bear', Char03()),
  PetSpecies('hamster', Char05()),
  PetSpecies('seal', Char06()),
  PetSpecies('sprout', Char09()),
  PetSpecies('mochi', Char10()),
];

/// The default pick when none is chosen yet (before the couple picks in
/// onboarding). Hamster — the liveliest of the five, so its idle + expression
/// reads immediately.
const String kDefaultSpecies = 'hamster';

/// Look up a species by id, falling back to the default.
PetSpecies speciesById(String? id) {
  for (final s in petRoster) {
    if (s.id == id) return s;
  }
  return petRoster.firstWhere((s) => s.id == kDefaultSpecies,
      orElse: () => petRoster.first);
}
