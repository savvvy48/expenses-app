import 'package:flutter/material.dart';
import '../widgets/toast.dart';
import 'app_haptics.dart';

/// Combined haptic + visual feedback utility.
///
/// Use [AppHaptics] directly when you only need tactile feedback.
/// Use [AppFeedback] when you want both haptic + toast notification.
class AppFeedback {
  AppFeedback._();

  // ─── Haptic + Toast Combos ───
  static void success(BuildContext context, String message) {
    AppHaptics.onSuccess();
    AppToast.success(context, message);
  }

  static void error(BuildContext context, String message) {
    AppHaptics.onError();
    AppToast.error(context, message);
  }

  static void info(BuildContext context, String message) {
    AppHaptics.onTap();
    AppToast.info(context, message);
  }

  static void warning(BuildContext context, String message) {
    AppHaptics.onWarning();
    AppToast.warning(context, message);
  }

  // ─── Haptic-Only (Convenience Delegates) ───
  static void onTap() => AppHaptics.onTap();
  static void onSelection() => AppHaptics.onSelection();
  static void onDelete() => AppHaptics.onDelete();
  static void onSuccess() => AppHaptics.onSuccess();
  static void onError() => AppHaptics.onError();
  static void heavyImpact() => AppHaptics.heavy();
}
