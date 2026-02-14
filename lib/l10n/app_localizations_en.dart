// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Daily Expenses';

  @override
  String get netBalance => 'Net Balance';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get startTracking => 'Tap + to add your first expense';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get deleteSelected => 'Delete Selected?';

  @override
  String deleteConfirmation(int count) {
    return 'Are you sure you want to delete $count transaction(s)?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get undo => 'Undo';

  @override
  String deleted(String title) {
    return '$title deleted';
  }

  @override
  String get filterExpenses => 'Filter Expenses';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get searchExpenses => 'Search expenses...';

  @override
  String get categories => 'Categories';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get amount => 'Amount';

  @override
  String get title => 'Title';

  @override
  String get date => 'Date';

  @override
  String get notes => 'Notes';

  @override
  String get selectDate => 'Select transaction date';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get recurring => 'Recurring';

  @override
  String get splitExpense => 'Split Expense';

  @override
  String get saveAsTemplate => 'Save as Template';

  @override
  String get templates => 'Templates';

  @override
  String get noTemplatesYet => 'No templates yet';

  @override
  String get saveTemplateHint => 'Save an expense as template to see it here';

  @override
  String get analytics => 'Analytics';

  @override
  String get settings => 'Settings';

  @override
  String get people => 'People';

  @override
  String get home => 'Home';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get exportData => 'Export Data';

  @override
  String get backupData => 'Backup Data';

  @override
  String get restoreData => 'Restore Data';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get monthlyBudget => 'Monthly Budget';

  @override
  String get dailyBudget => 'Daily Budget';

  @override
  String get noPeopleYet => 'No people added yet';

  @override
  String get addPeopleHint =>
      'People involved in split expenses will appear here';

  @override
  String get totalSpent => 'Total Spent';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisWeek => 'This Week';

  @override
  String get today => 'Today';

  @override
  String get allTime => 'All Time';

  @override
  String selected(int count) {
    return '$count selected';
  }
}
