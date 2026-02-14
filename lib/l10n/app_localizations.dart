import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App title displayed in the app bar
  ///
  /// In en, this message translates to:
  /// **'Daily Expenses'**
  String get appTitle;

  /// Label for the net balance section
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// Header for the recent transactions list
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// Empty state title when no transactions exist
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// Empty state subtitle
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first expense'**
  String get startTracking;

  /// FAB and screen title for adding an expense
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// Screen title for editing an expense
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// Confirmation dialog title for bulk delete
  ///
  /// In en, this message translates to:
  /// **'Delete Selected?'**
  String get deleteSelected;

  /// Confirmation message for bulk delete
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {count} transaction(s)?'**
  String deleteConfirmation(int count);

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Undo action label
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Snackbar message after deleting an expense
  ///
  /// In en, this message translates to:
  /// **'{title} deleted'**
  String deleted(String title);

  /// Filter sheet title
  ///
  /// In en, this message translates to:
  /// **'Filter Expenses'**
  String get filterExpenses;

  /// Button to clear all active filters
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search expenses...'**
  String get searchExpenses;

  /// Category section header
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Payment method section header
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// Amount field label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Title field label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Date field label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Notes field label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Date picker help text
  ///
  /// In en, this message translates to:
  /// **'Select transaction date'**
  String get selectDate;

  /// Income toggle label
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// Expense toggle label
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// Recurring toggle label
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// Split expense section header
  ///
  /// In en, this message translates to:
  /// **'Split Expense'**
  String get splitExpense;

  /// Save as template button label
  ///
  /// In en, this message translates to:
  /// **'Save as Template'**
  String get saveAsTemplate;

  /// Templates screen title
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// Empty state for templates screen
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get noTemplatesYet;

  /// Empty state subtitle for templates
  ///
  /// In en, this message translates to:
  /// **'Save an expense as template to see it here'**
  String get saveTemplateHint;

  /// Analytics screen title
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// People screen title
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// Home tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Dark mode toggle label
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Export data button label
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// Backup data button label
  ///
  /// In en, this message translates to:
  /// **'Backup Data'**
  String get backupData;

  /// Restore data button label
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get restoreData;

  /// Category management button label
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// Monthly budget section header
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get monthlyBudget;

  /// Daily budget section header
  ///
  /// In en, this message translates to:
  /// **'Daily Budget'**
  String get dailyBudget;

  /// Empty state for people screen
  ///
  /// In en, this message translates to:
  /// **'No people added yet'**
  String get noPeopleYet;

  /// Empty state subtitle for people
  ///
  /// In en, this message translates to:
  /// **'People involved in split expenses will appear here'**
  String get addPeopleHint;

  /// Total spent label in analytics
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// This month filter label
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// This week filter label
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Today filter label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// All time filter label
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// Selection count label
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
