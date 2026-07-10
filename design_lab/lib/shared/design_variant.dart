// The contract every one of the 10 design variants implements.
//
// A DesignVariant is a COMPLETE, self-contained visual language for Memory
// Pager. It owns its colors, typography, components, motion and layout — two
// variants should look like different apps. It only reuses the shared [AppData].

import 'package:flutter/material.dart';
import 'models.dart';

abstract class DesignVariant {
  /// Two-digit id, e.g. "01".
  String get id;

  /// Human name of the design direction, e.g. "Neo-Pager Mono".
  String get name;

  /// One-line concept describing the visual/UX direction.
  String get concept;

  /// The signature interaction/feature that expresses this design.
  String get signature;

  /// Where the idea came from (random / web-trend + reference), for the report.
  String get inspiration => '';

  /// A representative accent colour used only for the gallery chip.
  Color get accent;

  /// Whether the design reads as light or dark (drives gallery chrome).
  Brightness get brightness;

  /// Build one hero screen at phone size (428 x 926 logical px frame).
  Widget build(BuildContext context, HeroScreen screen, AppData data);
}
