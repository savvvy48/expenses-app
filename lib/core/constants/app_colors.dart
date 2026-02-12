import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary accent
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF5B8DEF);
  static const Color primaryDark = Color(0xFF1A4FCC);

  // Dark theme surfaces
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkCard = Color(0xFF161616);
  static const Color darkBorder = Color(0xFF2A2A2A);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5E5);

  // Text colors
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFF999999);
  static const Color darkTextTertiary = Color(0xFF666666);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextTertiary = Color(0xFF999999);

  // Category colors
  static const Color housing = Color(0xFF6C5CE7);
  static const Color food = Color(0xFFFF7675);
  static const Color transport = Color(0xFF00B894);
  static const Color fun = Color(0xFFFDCB6E);
  static const Color subscriptions = Color(0xFFE17055);
  static const Color health = Color(0xFF55EFC4);
  static const Color shopping = Color(0xFFA29BFE);

  // Status
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFFF7675);

  // Sharp shadow for elevation
  static List<BoxShadow> sharpShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.08),
          offset: const Offset(4, 4),
          blurRadius: 0,
        ),
      ];

  // Subtle sharp shadow
  static List<BoxShadow> subtleShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.06),
          offset: const Offset(2, 2),
          blurRadius: 0,
        ),
      ];
}
