// PetView — renders the couple's chosen character as their live, animated pet.
//
// Bridges the charlab roster into the app UI: given a species id it paints the
// matching [PetCharacter] at a fixed box size. Used big on the pet home (tap to
// pat) and tiny in the species picker.

import 'package:flutter/material.dart';

import '../charlab/roster.dart';
import '../charlab/toolkit.dart';

/// Paints [speciesId]'s character in a [size]×[size] box. Pass [frozenT] to
/// freeze the idle loop (for thumbnails / deterministic stills).
class PetView extends StatelessWidget {
  const PetView({
    super.key,
    required this.speciesId,
    this.size = 150,
    this.frozenT,
  });

  final String speciesId;
  final double size;
  final double? frozenT;

  @override
  Widget build(BuildContext context) {
    final PetCharacter c = speciesById(speciesId).character;
    return SizedBox(
      width: size,
      height: size,
      child: c.build(context, frozenT: frozenT),
    );
  }
}
