// Registry of all charlab pet characters shown in the gallery. Each generated
// character adds one import + one entry. Keep ordered by id.

import 'toolkit.dart';
import 'characters/char_00_reference.dart';
import 'characters/char_01_cat.dart';
import 'characters/char_02_bunny.dart';
import 'characters/char_03_bear.dart';
import 'characters/char_04_chick.dart';
import 'characters/char_05_hamster.dart';
import 'characters/char_06_seal.dart';
import 'characters/char_07_ghost.dart';
import 'characters/char_08_frog.dart';
import 'characters/char_09_sprout.dart';
import 'characters/char_10_mochi.dart';

final List<PetCharacter> characters = <PetCharacter>[
  ReferenceCharacter(),
  Char01(),
  Char02(),
  Char03(),
  Char04(),
  Char05(),
  Char06(),
  Char07(),
  Char08(),
  Char09(),
  Char10(),
];
