// Cold Press — DESIGN SYSTEM · theme.
//
// The cool-stone visual language for Memory Pager, promoted to reusable public
// tokens. A restrained neo-grotesque sans, tracked-caps eyebrows, and a cool
// mineral palette — architectural calm, nothing competing. Everything here is
// PUBLIC so real screens can share the exact same look as the Cold Press design.
//
// Self-contained: Flutter Material only. No packages, assets, network,
// Random, or DateTime.now().

import 'package:flutter/material.dart';

// ------------------------------------------------------------------ palette
/// Ground — the wide off-white mist the whole app floats on.
const Color cpMist = Color(0xFFECEDE9);

/// Dim ground — a half-step-down surface for quiet chips / coins.
const Color cpDim = Color(0xFFE2E3DE);

/// Slate ink — the single dark used for text and the one filled button.
const Color cpInk = Color(0xFF26282B);

/// Muted eucalyptus — the sole accent, used sparingly.
const Color cpEuc = Color(0xFF8A9A8E);

/// Cool off-white mat / print field — the passe-partout surface.
const Color cpPrint = Color(0xFFF4F5F2);

/// Ink at an arbitrary opacity — for hairlines and secondary text.
Color cpInkA(double a) => cpInk.withOpacity(a);

/// Eucalyptus at an arbitrary opacity — for accent keylines and tints.
Color cpEucA(double a) => cpEuc.withOpacity(a);

// -------------------------------------------------------------- typography
/// Restrained neo-grotesque sans — cool, architectural, no mono anywhere.
/// The single body/label voice of Cold Press.
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

/// Tracked-caps eyebrow — the quiet architectural label voice.
/// Wide tracking (~2.6) and w600; callers pass already-uppercased text.
TextStyle cpEyebrowStyle({Color color = cpInk, double size = 10}) => cpSans(
      size: size,
      color: color,
      weight: FontWeight.w600,
      spacing: 2.6,
      height: 1.2,
    );

// ------------------------------------------------------------------- theme
/// A light Material theme tuned to the Cold Press palette. Optional — screens
/// can also just use the tokens directly — but handy as an app-wide default.
final ThemeData cpTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: cpMist,
  colorScheme: ColorScheme.fromSeed(
    seedColor: cpEuc,
    brightness: Brightness.light,
  ).copyWith(
    surface: cpMist,
    primary: cpInk,
    secondary: cpEuc,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  textTheme: TextTheme(
    bodyMedium: cpSans(),
    bodyLarge: cpSans(size: 16),
    titleMedium: cpSans(size: 17, weight: FontWeight.w600, spacing: 0.4),
    labelSmall: cpEyebrowStyle(),
  ),
);
