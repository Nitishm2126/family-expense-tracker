import 'package:flutter/material.dart';

/// Single source of truth for every color in the app.
/// The palette is a deep violet-purple system, chosen to feel closer to
/// a premium fintech app (Google Pay / PhonePe) than a generic template.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF6C4CF0);
  static const Color primaryDark = Color(0xFF4B2FD1);
  static const Color primaryLight = Color(0xFF9B85F7);
  static const Color secondary = Color(0xFFFFFFFF);

  static const List<Color> primaryGradient = [
    Color(0xFF7B5CFA),
    Color(0xFF5A32E0),
  ];

  static const List<Color> heroGradient = [
    Color(0xFF8A6BFF),
    Color(0xFF6438E0),
    Color(0xFF4B24C9),
  ];

  // Light theme surfaces
  static const Color backgroundLight = Color(0xFFF6F5FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Dark theme surfaces
  static const Color backgroundDark = Color(0xFF121018);
  static const Color surfaceDark = Color(0xFF1D1A28);
  static const Color cardDark = Color(0xFF242032);

  // Text
  static const Color textPrimaryLight = Color(0xFF1E1B2E);
  static const Color textSecondaryLight = Color(0xFF6F6C85);
  static const Color textPrimaryDark = Color(0xFFF2F1F8);
  static const Color textSecondaryDark = Color(0xFFA9A6BF);

  // Semantic
  static const Color income = Color(0xFF19B36B);
  static const Color expense = Color(0xFFE24C6D);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE0364C);
  static const Color info = Color(0xFF3E8BFF);

  // Category accent palette (used for charts, avatars, tags)
  static const List<Color> categoryPalette = [
    Color(0xFF6C4CF0),
    Color(0xFFE24C6D),
    Color(0xFFF5A623),
    Color(0xFF19B36B),
    Color(0xFF3E8BFF),
    Color(0xFFFF7A59),
    Color(0xFF00BFA6),
    Color(0xFFD84BFF),
    Color(0xFF5C6BC0),
    Color(0xFF9E9E9E),
  ];

  static const Color divider = Color(0xFFE7E5F0);
  static const Color dividerDark = Color(0xff32304099);

  static const Color shadow = Color(0x1F6C4CF0);
}

