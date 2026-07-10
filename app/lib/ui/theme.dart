// Cold Press — the Memory Pager design system's tokens.
//
// The cool-stone counterpart to warm clay: architectural calm, a cool mineral
// palette, a restrained neo-grotesque sans, and tracked-caps eyebrows. Nothing
// blinks or moves; the quiet mat border is the only decoration.
//
// This file is PUBLIC (no underscores) so the whole app can share one voice.
// Only `package:flutter/material.dart` is used — no assets, no packages.

import 'package:flutter/material.dart';

// ------------------------------------------------------------------ palette
/// Ground — the cool off-white the whole app rests on.
const Color cpMist = Color(0xFFECEDE9);

/// Dim ground — a hair darker than [cpMist], for chips / pills.
const Color cpDim = Color(0xFFE2E3DE);

/// Slate ink — the single dark tone for text and fills.
const Color cpInk = Color(0xFF26282B);

/// Muted eucalyptus — the sole accent. Used sparingly, never loud.
const Color cpEuc = Color(0xFF8A9A8E);

/// Cool off-white mat / print field — the matted card surface.
const Color cpPrint = Color(0xFFF4F5F2);

/// [cpInk] at opacity [a] (0..1). Ink is the only dark; tint it, don't recolor.
Color cpInkA(double a) => cpInk.withOpacity(a);

/// [cpEuc] at opacity [a] (0..1).
Color cpEucA(double a) => cpEuc.withOpacity(a);

// ----------------------------------------------------------------- type
/// The restrained neo-grotesque sans used everywhere — cool, architectural,
/// no mono anywhere. Mirrors Cold Press's `_d11Sans`.
TextStyle cpSans({
  double size = 14,
  Color color = cpInk,
  FontWeight weight = FontWeight.w400,
  double spacing = 0.2,
  double height = 1.4,
}) =>
    TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

/// Tracked-caps eyebrow — the quiet architectural label voice. Callers usually
/// pass an already-dimmed [color]; the text should be `.toUpperCase()`d by the
/// widget that renders it (see `CpEyebrow`).
TextStyle cpEyebrowStyle({Color color = cpInk, double size = 10}) => cpSans(
      size: size,
      color: color,
      weight: FontWeight.w600,
      spacing: 2.6,
      height: 1.2,
    );

// ----------------------------------------------------------------- theme
/// A light [ThemeData] seeded from [cpEuc] on a [cpMist] ground. Splashes are
/// suppressed to keep the Cold Press stillness — interaction is quiet.
final ThemeData cpTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: cpMist,
  canvasColor: cpMist,
  primaryColor: cpEuc,
  colorScheme: ColorScheme.fromSeed(
    seedColor: cpEuc,
    brightness: Brightness.light,
  ).copyWith(
    surface: cpMist,
    onSurface: cpInk,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  textSelectionTheme: const TextSelectionThemeData(cursorColor: cpEuc),
);
