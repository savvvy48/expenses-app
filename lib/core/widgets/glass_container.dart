import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A container with glassmorphism effect — frosted glass with blur.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final bool isDark;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.blur = 20,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.7),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Show a modal bottom sheet with glassmorphism backdrop.
  static Future<T?> showGlassModal<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.85)
                    : AppColors.lightSurface.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: builder(ctx),
            ),
          ),
        );
      },
    );
  }
}
