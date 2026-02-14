import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/toast.dart';

class AppFeedback {
  static void success(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    AppToast.success(context, message);
  }

  static void error(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    AppToast.error(context, message);
  }

  static void info(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    AppToast.info(context, message);
  }

  static void warning(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    AppToast.warning(context, message);
  }

  static void onTap() => HapticFeedback.lightImpact();
  static void onSelection() => HapticFeedback.selectionClick();
  static void onDelete() => HapticFeedback.heavyImpact();
  static void onSuccess() => HapticFeedback.mediumImpact();
  static void onError() => HapticFeedback.heavyImpact();
}
