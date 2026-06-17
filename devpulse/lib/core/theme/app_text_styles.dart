import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// DevPulse typography — mirrors the HTML font system.
class AppTextStyles {
  AppTextStyles._();

  // display-lg  48px / -0.02em / w700 — Geist
  static TextStyle displayLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 48,
        height: 56 / 48,
        letterSpacing: -0.02 * 48,
        fontWeight: FontWeight.w700,
        color: color,
      );

  // display-lg-mobile  32px / -0.02em / w700 — Geist
  static TextStyle displayLgMobile({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.02 * 32,
        fontWeight: FontWeight.w700,
        color: color,
      );

  // headline-md  24px / w600 — Geist
  static TextStyle headlineMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // body-lg  18px / w400 — Inter
  static TextStyle bodyLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 18,
        height: 28 / 18,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // body-md  16px / w400 — Inter
  static TextStyle bodyMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // label-sm  14px / 0.05em / w500 — Geist
  static TextStyle labelSm({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.05 * 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  // code-block  15px / w400 — JetBrains Mono
  static TextStyle codeBlock({Color color = AppColors.onSurface}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 15,
        height: 24 / 15,
        fontWeight: FontWeight.w400,
        color: color,
      );
}
