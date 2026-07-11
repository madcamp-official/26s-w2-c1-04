// Memory Pager — the design system's tokens (Sumone-style pastel).
//
// Warm cream paper, a soft heart-pink accent, gentle gold for currency, rounded
// everything, generous whitespace. An elegant serif for the wordmark, a soft
// rounded sans for body. No emoji anywhere — chrome uses line icons.
//
// Token NAMES are kept from the previous system (cpMist/cpInk/cpEuc/…) so the
// whole app keeps compiling; only their VALUES and the styling change.
//
// This file is PUBLIC (no underscores). Only `package:flutter/material.dart`.

import 'package:flutter/material.dart';

// ------------------------------------------------------------------ palette
/// Ground — the warm cream paper the whole app rests on.
const Color cpMist = Color(0xFFFAF6EE);

/// Dim ground — a hair deeper than [cpMist], for chips / pills / cards.
const Color cpDim = Color(0xFFF1E9DB);

/// Warm brown-ink — the primary text/line tone (never pure black).
const Color cpInk = Color(0xFF473D33);

/// Soft heart-pink — the accent. Hearts, active nav, key highlights. Sparingly.
const Color cpEuc = Color(0xFFE4707E);

/// Warm white — card / surface / mat field.
const Color cpPrint = Color(0xFFFFFDF9);

/// Gentle gold — currency (coins/snacks). Not an accent; a separate warm tone.
const Color cpGold = Color(0xFFC99A5B);

/// Soft peach — a secondary warm tint (badges, gentle fills).
const Color cpPeach = Color(0xFFF2C6A6);

/// [cpInk] at opacity [a] (0..1). Ink is the only dark; tint it, don't recolor.
Color cpInkA(double a) => cpInk.withValues(alpha: a);

/// [cpEuc] at opacity [a] (0..1).
Color cpEucA(double a) => cpEuc.withValues(alpha: a);

// ------------------------------------------------------------------ radius
/// Standard corner radii — soft and rounded, the opposite of the old boxy 1–2px.
const double cpRadiusCard = 20;
const double cpRadiusPill = 999;
const double cpRadiusSmall = 12;

// ----------------------------------------------------------------- type
/// The soft rounded sans used for body/UI. Warm, gentle, a touch of line height.
TextStyle cpSans({
  double size = 14,
  Color color = cpInk,
  FontWeight weight = FontWeight.w400,
  double spacing = 0.1,
  double height = 1.45,
}) =>
    TextStyle(
      fontFamily: _sansFamily,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );

/// The elegant serif for the wordmark and display numbers (e.g. "Sumone", "52").
TextStyle cpSerif({
  double size = 22,
  Color color = cpInk,
  FontWeight weight = FontWeight.w500,
  double spacing = 0.2,
  FontStyle style = FontStyle.italic,
  double height = 1.2,
}) =>
    TextStyle(
      fontFamily: _serifFamily,
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: spacing,
      fontStyle: style,
      height: height,
    );

/// A soft label voice (replaces the old tracked-caps eyebrow). Gentle, small,
/// slightly muted — not shouty all-caps. Korean ignores toUpperCase anyway.
TextStyle cpEyebrowStyle({Color color = cpInk, double size = 11}) => cpSans(
      size: size,
      color: color,
      weight: FontWeight.w600,
      spacing: 0.6,
      height: 1.3,
    );

// Platform serif/sans stacks (no bundled font assets — use system faces).
const String _serifFamily = 'Georgia';
const String _sansFamily = 'Helvetica';

// ----------------------------------------------------------------- theme
/// A light [ThemeData] on the cream ground. Splashes suppressed for a calm,
/// pastel feel; text selection uses the pink accent.
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
