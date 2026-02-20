import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Accent (Violet) ───
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF6D28D9);

  // ─── Dark Theme Surfaces (True Black) ───
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF141414);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2A2A2A);

  // ─── Light Theme Surfaces (Warm Neutrals) ───
  static const Color lightBg = Color(0xFFF7F7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8E8EC);

  // ─── Pastel Pill Badges ───
  static const Color heroLavender = Color(0xFFC4B5FD);
  static const Color heroMint = Color(0xFF6EE7B7);
  static const Color heroPeach = Color(0xFFFCA5A5);
  static const Color heroSky = Color(0xFF93C5FD);
  static const Color heroCream = Color(0xFFFDE68A);
  static const Color heroBlush = Color(0xFFFBCFE8);

  // ─── Text Colors ───
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFA3A3A3);
  static const Color darkTextTertiary = Color(0xFF737373);
  static const Color lightTextPrimary = Color(0xFF171717);
  static const Color lightTextSecondary = Color(0xFF525252);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);

  // ─── Category Colors ───
  static const Color housing = Color(0xFF818CF8);
  static const Color food = Color(0xFFFB7185);
  static const Color transport = Color(0xFF34D399);
  static const Color fun = Color(0xFFFBBF24);
  static const Color subscriptions = Color(0xFFFB923C);
  static const Color health = Color(0xFF2DD4BF);
  static const Color shopping = Color(0xFFC084FC);

  // ─── Status ───
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFB7185);
  static const Color info = Color(0xFF8B5CF6);

  /// Returns white or black text color for best contrast on [background].
  static Color contrastText(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF171717) : Colors.white;
  }

  // ─── Shadows ───
  static List<BoxShadow> softShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.4)
              : Colors.black.withOpacity(0.06),
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> subtleShadow(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.25)
              : Colors.black.withOpacity(0.04),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> floatingShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.35),
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.25),
          offset: Offset.zero,
          blurRadius: 20,
          spreadRadius: 4,
        ),
      ];
}
