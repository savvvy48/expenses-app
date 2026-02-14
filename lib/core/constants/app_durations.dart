/// Centralized animation duration constants.
///
/// Use these instead of hardcoded `Duration(...)` values
/// to ensure consistent timing throughout the app.
class AppDurations {
  AppDurations._();

  // UI Interactions
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);

  // Page & Theme Transitions
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration themeTransition = Duration(milliseconds: 400);
  static const Duration dismissDuration = Duration(milliseconds: 300);

  // Splash Screen
  static const Duration splashMin = Duration(milliseconds: 1500);
  static const Duration splashMax = Duration(seconds: 5);

  // Snackbar / Toast
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration toastDuration = Duration(seconds: 2);

  // Shimmer
  static const Duration shimmerCycle = Duration(milliseconds: 1500);
}
