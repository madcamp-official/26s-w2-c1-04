// PetView — renders the couple's chosen character as their live, animated pet.
//
// Bridges the charlab roster into the app UI: given a species id it paints the
// matching [PetCharacter] at a fixed box size. Used big on the pet home (tap to
// pat) and tiny in the species picker.

import 'package:flutter/material.dart';

import '../charlab/roster.dart';
import '../charlab/toolkit.dart';
import '../core/models.dart';

/// Maps the app's pet activity onto a drawable [PetExpression]. Unknown/absent
/// activity → neutral (an honest calm face, never a faked mood).
PetExpression expressionForActivity(PetActivityKind? a) => switch (a) {
      PetActivityKind.eating => PetExpression.eating,
      PetActivityKind.sleeping => PetExpression.sleepy,
      PetActivityKind.walking => PetExpression.curious,
      PetActivityKind.playing => PetExpression.excited,
      PetActivityKind.drawing => PetExpression.focused,
      PetActivityKind.waiting => PetExpression.neutral,
      null => PetExpression.neutral,
    };

/// Paints [speciesId]'s character in a [size]×[size] box. Pass [frozenT] to
/// freeze the idle loop (for thumbnails / deterministic stills) and
/// [expression] to set the face/pose (e.g. from the pet's current activity).
class PetView extends StatelessWidget {
  const PetView({
    super.key,
    required this.speciesId,
    this.size = 150,
    this.frozenT,
    this.expression = PetExpression.neutral,
  });

  final String speciesId;
  final double size;
  final double? frozenT;
  final PetExpression expression;

  @override
  Widget build(BuildContext context) {
    final PetCharacter c = speciesById(speciesId).character;
    return SizedBox(
      width: size,
      height: size,
      child: c.build(context, frozenT: frozenT, expression: expression),
    );
  }
}
