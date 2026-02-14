import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/data/expense_repository.dart';
import '../core/data/sample_data.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  
  List<Expense> _expenses = [];
  List<ExpenseCategory> _customCategories = [];
  Expense? _lastDeleted;
  String _searchQuery = '';
  String? _filterCategoryId;
  PaymentMethod? _filterPaymentMethod;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  ExpenseProvider(this._repository);

  List<Expense> get expenses => _getFilteredExpenses();
  List<Expense> get allExpenses => List.unmodifiable(_expenses);
  List<ExpenseCategory> get allCategories => [
        ...ExpenseCategory.defaults,
        ..._customCategories,
      ];
  Expense? get lastDeleted => _lastDeleted;
  String get searchQuery => _searchQuery;

  Future<void> init() async {
    await _repository.init();

    _expenses = _repository.getAllExpenses();
    _customCategories = _repository.getCustomCategories();

    final settingsBox = await Hive.openBox(AppConstants.boxSettings);
    final isInitialized = settingsBox.get('isInitialized', defaultValue: false);
    
    if (!isInitialized) {
      if (_expenses.isEmpty) {
        _expenses = SampleData.getExpenses();
        await _repository.saveAllExpenses(_expenses);
      }
      await settingsBox.put('isInitialized', true);
    }
    
    _sortExpenses();
    await _generateRecurringExpenses();
    notifyListeners();
  }

  void _sortExpenses() {
    _expenses.sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> _getFilteredExpenses() {
    var result = List<Expense>.from(_expenses);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) =>
          e.title.toLowerCase().contains(q) ||
          (e.notes?.toLowerCase().contains(q) ?? false) ||
          e.category.label.toLowerCase().contains(q)).toList();
    }
    if (_filterCategoryId != null) {
      result = result.where((e) => e.category.id == _filterCategoryId).toList();
    }
    if (_filterPaymentMethod != null) {
      result = result.where((e) => e.paymentMethod == _filterPaymentMethod).toList();
    }
    if (_filterStartDate != null) {
      result = result.where((e) => !e.date.isBefore(_filterStartDate!)).toList();
    }
    if (_filterEndDate != null) {
      result = result.where((e) => !e.date.isAfter(
          _filterEndDate!.add(const Duration(days: 1)))).toList();
    }
    return result;
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  void setFilterPaymentMethod(PaymentMethod? method) {
    _filterPaymentMethod = method;
    notifyListeners();
  }

  void setFilterDateRange(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterCategoryId = null;
    _filterPaymentMethod = null;
    _filterStartDate = null;
    _filterEndDate = null;
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _filterCategoryId != null ||
      _filterPaymentMethod != null ||
      _filterStartDate != null;

  // CRUD
  Future<void> addExpense(Expense expense) async {
    _expenses.insert(0, expense);
    _sortExpenses();
    notifyListeners();
    await _repository.saveExpense(expense);
  }

  Future<void> updateExpense(Expense expense) async {
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      _expenses[idx] = expense;
      _sortExpenses();
      notifyListeners();
      await _repository.saveExpense(expense);
    }
  }

  Future<void> deleteExpense(String id) async {
    final idx = _expenses.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _lastDeleted = _expenses.removeAt(idx);
      notifyListeners();
      await _repository.deleteExpense(id);
    }
  }

  Future<void> undoDelete() async {
    if (_lastDeleted != null) {
      await addExpense(_lastDeleted!);
      _lastDeleted = null;
    }
  }

  // Category management
  Future<void> addCategory(ExpenseCategory category) async {
    _customCategories.add(category);
    notifyListeners();
    await _repository.saveCategory(category);
  }

  Future<void> deleteCategory(String id) async {
    _customCategories.removeWhere((c) => c.id == id);
    notifyListeners();
    await _repository.deleteCategory(id);
  }

  // Computed properties
  double get totalIncome =>
      _expenses.where((e) => e.isIncome).fold(0.0, (sum, e) => sum + e.amount);

  double get totalSpent =>
      _expenses.where((e) => !e.isIncome).fold(0.0, (sum, e) => sum + e.amount);

  double get netBalance => totalIncome - totalSpent;

  double get thisMonthIncome {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.isIncome && e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get thisMonthTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => !e.isIncome && e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get lastMonthTotal {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return _expenses
        .where((e) => !e.isIncome && e.date.month == lastMonth.month && e.date.year == lastMonth.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get todayTotal {
    final today = DateTime.now();
    return _expenses
        .where((e) =>
            !e.isIncome &&
            e.date.day == today.day &&
            e.date.month == today.month &&
            e.date.year == today.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  bool isDailyLimitExceeded(double newAmount) {
    // Only check if daily limit is set (non-zero)
    if (AppConstants.defaultDailyLimit <= 0) return false;
    return (todayTotal + newAmount) > AppConstants.defaultDailyLimit;
  }

  // Analytics Helpers
  List<Expense> getExpensesForPeriod(String period, DateTime anchor) {
    if (period == 'Day') {
      return _expenses.where((e) => 
        e.date.year == anchor.year && 
        e.date.month == anchor.month && 
        e.date.day == anchor.day).toList();
    } else if (period == 'Week') {
      // Find start of week (Monday)
      final startOfWeek = anchor.subtract(Duration(days: anchor.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return _expenses.where((e) => 
        !e.date.isBefore(startOfWeek.subtract(const Duration(seconds: 1))) && 
        !e.date.isAfter(endOfWeek.add(const Duration(days: 1)))).toList();
    } else {
      // Month
      return _expenses.where((e) => 
        e.date.year == anchor.year && 
        e.date.month == anchor.month).toList();
    }
  }

  // ... (rest of the file)
  
  // Recurring Expenses Logic
  Future<void> _generateRecurringExpenses() async {
    final now = DateTime.now();
    final recurring = _expenses.where((e) => e.isRecurring).toList();
    bool addedAny = false;

    for (final expense in recurring) {
      DateTime nextDate = _getNextRecurringDate(expense);
      
      // While the next due date is in the past (including today)
      while (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
        // Create new instance
        final newExpense = expense.copyWith(
          id: const Uuid().v4(),
          date: nextDate,
          isRecurring: false, // Instances are not recurring themselves
          // Link to parent if we had a parentId field, for now just a copy
        );
        
        // Add to list but don't save yet to avoid multiple file writes
        _expenses.insert(0, newExpense);
        await _repository.saveExpense(newExpense);
        addedAny = true;
        
        // Advance to next period
        nextDate = _getNextRecurringDate(newExpense.copyWith(date: nextDate, recurringType: expense.recurringType));
      }
    }
    
    if (addedAny) {
      _sortExpenses();
      notifyListeners();
    }
  }

  DateTime _getNextRecurringDate(Expense e) {
    switch (e.recurringType) {
      case RecurringType.daily:
        return e.date.add(const Duration(days: 1));
      case RecurringType.weekly:
        return e.date.add(const Duration(days: 7));
      case RecurringType.monthly:
        return DateTime(e.date.year, e.date.month + 1, e.date.day);
      case RecurringType.yearly:
        return DateTime(e.date.year + 1, e.date.month, e.date.day);
      case RecurringType.none:
        return e.date;
    }
  }

  List<Expense> _getFilteredExpenses() {
    var result = List<Expense>.from(_expenses);
    
    // 1. Search (Title, Notes, Payment Method Label, Category Label)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) =>
          e.title.toLowerCase().contains(q) ||
          (e.notes?.toLowerCase().contains(q) ?? false) ||
          e.paymentMethod.label.toLowerCase().contains(q) ||
          e.category.label.toLowerCase().contains(q)).toList();
    }

    // 2. Category Filter
    if (_filterCategoryId != null) {
      result = result.where((e) => e.category.id == _filterCategoryId).toList();
    }

    // 3. Payment Method Filter
    if (_filterPaymentMethod != null) {
      result = result.where((e) => e.paymentMethod == _filterPaymentMethod).toList();
    }

    // 4. Date Range Filter
    if (_filterStartDate != null) {
      result = result.where((e) => !e.date.isBefore(_filterStartDate!)).toList();
    }
    if (_filterEndDate != null) {
      result = result.where((e) => !e.date.isAfter(
          _filterEndDate!.add(const Duration(days: 1)))).toList();
    }
    
    return result;
  }


  Map<String, double> get categoryTotals {
    final map = <String, double>{};
    for (final e in _expenses.where((e) {
      final now = DateTime.now();
      return e.date.month == now.month && e.date.year == now.year;
    })) {
      map[e.category.id] = (map[e.category.id] ?? 0) + e.amount;
    }
    return map;
  }

  Map<String, double> get personTotals {
    final map = <String, double>{};
    for (final e in _expenses) {
      for (final s in e.splits) {
        map[s.personName] = (map[s.personName] ?? 0) + s.amount;
      }
    }
    return map;
  }

  List<MapEntry<String, double>> get weeklyTrend {
    final result = <String, double>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.month}/${day.day}';
      result[key] = _expenses
          .where((e) =>
              e.date.day == day.day &&
              e.date.month == day.month &&
              e.date.year == day.year)
          .fold(0.0, (sum, e) => sum + e.amount);
    }
    return result.entries.toList();
  }

  int get recurringCount => _expenses.where((e) => e.isRecurring).length;
}
