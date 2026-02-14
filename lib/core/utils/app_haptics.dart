import 'package:flutter/services.dart';

/// Standardized haptic feedback utility.
///
/// Provides semantic aliases for different interaction types,
/// ensuring consistent tactile feedback across the app.
class AppHaptics {
  AppHaptics._();

  // ─── Raw Levels ───
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void selection() => HapticFeedback.selectionClick();
  static void vibrate() => HapticFeedback.vibrate();

  // ─── Semantic Aliases ───
  /// Tap on a button, card, or interactive element
  static void onTap() => light();

  /// Selecting an item from a list
  static void onSelection() => selection();

  /// Toggling a switch or checkbox
  static void onToggle() => selection();

  /// Successful action (save, export, etc.)
  static void onSuccess() => medium();

  /// Destructive action (delete, dismiss)
  static void onDelete() => heavy();

  /// Error feedback
  static void onError() => heavy();

  /// Warning feedback
  static void onWarning() => medium();

  /// Long press trigger (entering selection mode)
  static void onLongPress() => medium();

  /// Swipe gesture haptic
  static void onSwipe() => light();
}
