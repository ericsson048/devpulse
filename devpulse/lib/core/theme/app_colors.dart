import 'package:flutter/material.dart';

/// DevPulse design system — OLED Dark + Cyberpunk Glassmorphism
/// Informed by UI/UX Pro Max skill: dark mode OLED + neon glow accents
class AppColors {
  AppColors._();

  // ── Brand primaries ──────────────────────────────────────────
  static const primary = Color(0xFFADC6FF);
  static const primaryContainer = Color(0xFF4D8EFF);
  static const primaryFixed = Color(0xFFD8E2FF);
  static const primaryFixedDim = Color(0xFFADC6FF);
  static const onPrimary = Color(0xFF002E6A);
  static const onPrimaryFixed = Color(0xFF001A42);
  static const onPrimaryFixedVariant = Color(0xFF004395);
  static const onPrimaryContainer = Color(0xFF00285D);
  static const inversePrimary = Color(0xFF005AC2);

  // ── Secondary (yellow/gold) ──────────────────────────────────
  static const secondary = Color(0xFFFFED76);
  static const secondaryFixed = Color(0xFFFCE425);
  static const secondaryFixedDim = Color(0xFFDEC800);
  static const secondaryContainer = Color(0xFFE7D000);
  static const onSecondary = Color(0xFF373100);
  static const onSecondaryFixed = Color(0xFF201C00);
  static const onSecondaryFixedVariant = Color(0xFF504700);
  static const onSecondaryContainer = Color(0xFF635800);

  // ── Tertiary (coral/red) ─────────────────────────────────────
  static const tertiary = Color(0xFFFFB3AD);
  static const tertiaryFixed = Color(0xFFFFDAD7);
  static const tertiaryFixedDim = Color(0xFFFFB3AD);
  static const tertiaryContainer = Color(0xFFFF5451);
  static const onTertiary = Color(0xFF68000A);
  static const onTertiaryFixed = Color(0xFF410004);
  static const onTertiaryFixedVariant = Color(0xFF930013);
  static const onTertiaryContainer = Color(0xFF5C0008);

  // ── Error ────────────────────────────────────────────────────
  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);
  static const onError = Color(0xFF690005);
  static const onErrorContainer = Color(0xFFFFDAD6);

  // ── OLED Surface / Background ────────────────────────────────
  static const background = Color(0xFF0B1326);
  static const surface = Color(0xFF0B1326);
  static const surfaceDim = Color(0xFF0B1326);
  static const surfaceBright = Color(0xFF31394D);
  static const surfaceVariant = Color(0xFF2D3449);
  static const surfaceContainerLowest = Color(0xFF060E20);
  static const surfaceContainerLow = Color(0xFF131B2E);
  static const surfaceContainer = Color(0xFF171F33);
  static const surfaceContainerHigh = Color(0xFF222A3D);
  static const surfaceContainerHighest = Color(0xFF2D3449);
  static const surfaceTint = Color(0xFFADC6FF);

  // ── On-surface ───────────────────────────────────────────────
  static const onSurface = Color(0xFFDAE2FD);
  static const onSurfaceVariant = Color(0xFFC2C6D6);
  static const onBackground = Color(0xFFDAE2FD);
  static const inverseSurface = Color(0xFFDAE2FD);
  static const inverseOnSurface = Color(0xFF283044);

  // ── Outline ──────────────────────────────────────────────────
  static const outline = Color(0xFF8C909F);
  static const outlineVariant = Color(0xFF424754);

  // ── Neon glow accents (cyberpunk layer) ──────────────────────
  static const neonBlue = Color(0xFF4D8EFF);
  static const neonGold = Color(0xFFFFED76);
  static const neonCoral = Color(0xFFFF5451);
}
