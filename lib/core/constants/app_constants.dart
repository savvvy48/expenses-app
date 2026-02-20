

class AppConstants {
  static const String appName = 'PocketSafe';

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animSplashMin = Duration(milliseconds: 1500);
  static const Duration animSplashMax = Duration(seconds: 5);

  // Layout & Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 32.0;

  static const double iconSizeSmall = 16.0; // Increased from 12.0
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Budget Thresholds
  static const double budgetWarningYellow = 0.5;
  static const double budgetWarningOrange = 0.75;
  static const double budgetWarningRed = 0.9;
  static const double budgetLimit = 1.0;

  // Hive Box Names
  static const String boxExpenses = 'expenses';
  static const String boxCategories = 'custom_categories';
  static const String boxSettings = 'settings';
  static const String boxPeople = 'people';

  // Limits
  static const int maxNotesLength = 500;
  static const int maxTitleLength = 50;
  static const double defaultDailyLimit = 100.0;
}
