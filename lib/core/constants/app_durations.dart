class AppDurations {
  AppDurations._();

  // Micro-interactions (button press, toggle)
  static const Duration micro = Duration(milliseconds: 150);

  // Standard element animations (card appear, chip select)
  static const Duration standard = Duration(milliseconds: 300);

  // Page/screen transitions
  static const Duration page = Duration(milliseconds: 450);

  // Long transitions (splash, onboarding)
  static const Duration slow = Duration(milliseconds: 600);

  // Staggered list item delay
  static const Duration stagger = Duration(milliseconds: 60);

  // Splash screen durations
  static const Duration splashMin = Duration(milliseconds: 800);
  static const Duration splashMax = Duration(seconds: 5);

  // Theme transition
  static const Duration themeTransition = Duration(milliseconds: 300);
}
