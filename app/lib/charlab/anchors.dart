// Per-species anchor points for placing worn items on a pet.
//
// Each pet is drawn in a square box; anchors are NORMALIZED (0..1) positions in
// that box where an item of a given slot sits. Species differ (a bear's head is
// higher and wider than a mochi's), so each roster species tunes its own set.
// Item art is drawn centered on the anchor, scaled by [unit] * the slot's size.

import 'package:flutter/material.dart';

import '../core/models.dart';

/// Where an item sits on the pet.
enum ItemSlot { hat, face, body, prop }

/// Map the wire [ItemCategory] onto a drawable slot.
ItemSlot slotForCategory(ItemCategory c) => switch (c) {
      ItemCategory.hat => ItemSlot.hat,
      ItemCategory.accessory => ItemSlot.face,
      ItemCategory.clothes => ItemSlot.body,
      ItemCategory.furniture => ItemSlot.prop,
      ItemCategory.background => ItemSlot.prop,
      ItemCategory.prop => ItemSlot.prop,
    };

/// Normalized placement of each slot for one species.
class PetAnchors {
  const PetAnchors({
    required this.hat,
    required this.face,
    required this.body,
    required this.prop,
    this.unit = 1.0,
  });

  /// Center of the head crown (hats rest here, growing upward).
  final Offset hat;

  /// Center of the eye line (glasses / accessories).
  final Offset face;

  /// Center of the torso (clothes).
  final Offset body;

  /// A spot beside the pet on the ground (held/placed props).
  final Offset prop;

  /// Per-species scale multiplier — smaller pets wear smaller items.
  final double unit;

  Offset of(ItemSlot slot) => switch (slot) {
        ItemSlot.hat => hat,
        ItemSlot.face => face,
        ItemSlot.body => body,
        ItemSlot.prop => prop,
      };
}

/// Anchors per roster species id. Tuned against the drawn characters (bear,
/// hamster, seal, sprout, mochi) so items land on the head/eyes/body correctly.
const Map<String, PetAnchors> _anchors = {
  'bear': PetAnchors(
    hat: Offset(0.50, 0.30),
    face: Offset(0.50, 0.54),
    body: Offset(0.50, 0.68),
    prop: Offset(0.80, 0.82),
    unit: 1.0,
  ),
  'hamster': PetAnchors(
    hat: Offset(0.50, 0.30),
    face: Offset(0.50, 0.55),
    body: Offset(0.50, 0.70),
    prop: Offset(0.80, 0.84),
    unit: 0.96,
  ),
  'seal': PetAnchors(
    hat: Offset(0.50, 0.33),
    face: Offset(0.50, 0.52),
    body: Offset(0.50, 0.66),
    prop: Offset(0.82, 0.82),
    unit: 0.94,
  ),
  'sprout': PetAnchors(
    hat: Offset(0.50, 0.34),
    face: Offset(0.50, 0.58),
    body: Offset(0.50, 0.72),
    prop: Offset(0.80, 0.84),
    unit: 0.9,
  ),
  'mochi': PetAnchors(
    hat: Offset(0.50, 0.32),
    face: Offset(0.50, 0.56),
    body: Offset(0.50, 0.70),
    prop: Offset(0.80, 0.84),
    unit: 0.95,
  ),
};

/// Anchors for [speciesId], falling back to the bear's if unknown.
PetAnchors anchorsFor(String speciesId) =>
    _anchors[speciesId] ?? _anchors['bear']!;
