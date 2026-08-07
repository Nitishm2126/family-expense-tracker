import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale for the whole app. Poppins gives the rounded,
/// friendly-but-professional look used throughout fintech apps.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle displayLarge(Color color) =>
      _base(size: 32, weight: FontWeight.w700, color: color, letterSpacing: -0.5);

  static TextStyle headline(Color color) =>
      _base(size: 22, weight: FontWeight.w600, color: color, letterSpacing: -0.3);

  static TextStyle title(Color color) =>
      _base(size: 18, weight: FontWeight.w600, color: color);

  static TextStyle subtitle(Color color) =>
      _base(size: 15, weight: FontWeight.w500, color: color);

  static TextStyle body(Color color) =>
      _base(size: 14, weight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle bodyMedium(Color color) =>
      _base(size: 14, weight: FontWeight.w500, color: color);

  static TextStyle caption(Color color) =>
      _base(size: 12, weight: FontWeight.w400, color: color);

  static TextStyle captionMedium(Color color) =>
      _base(size: 12, weight: FontWeight.w500, color: color);

  static TextStyle amountLarge(Color color) =>
      _base(size: 30, weight: FontWeight.w700, color: color, letterSpacing: -0.5);

  static TextStyle amountMedium(Color color) =>
      _base(size: 18, weight: FontWeight.w600, color: color);

  static TextStyle button = _base(
    size: 16,
    weight: FontWeight.w600,
    color: AppColors.secondary,
    letterSpacing: 0.2,
  );
}

