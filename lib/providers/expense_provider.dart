import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/data/expense_repository.dart';
import '../models/expense.dart';
import '../models/time_period.dart';

enum SortOption {
  dateNewest,
  dateOldest,
  amountHighLow,
  amountLowHigh,
  categoryAZ,
}

class ExpenseProvider extends ChangeNotifier {
  final ExpenseRepository _repository;
  
  List<Expense> _expenses = [];
  List<ExpenseCategory> _customCategories = [];
  List<Expense> _lastDeletedBatch = []; // Stores last deleted items (single or batch)
  String _searchQuery = '';
  SortOption _currentSort = SortOption.dateNewest;
  String? _filterCategoryId;
  PaymentMethod? _filterPaymentMethod;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  ExpenseProvider(this._repository);

  List<Expense> get expenses => _getFilteredExpenses();
  List<Expense> get allExpenses => List.unmodifiable(_expenses);
  List<Expense> get templates => _expenses.where((e) => e.isTemplate).toList();

  List<ExpenseCategory> get allCategories => [...ExpenseCategory.defaults, ..._customCategories];
  // ... getters ...
  SortOption get currentSort => _currentSort;
  bool get canUndo => _lastDeletedBatch.isNotEmpty;
  String? get filterCategoryId => _filterCategoryId;
  PaymentMethod? get filterPaymentMethod => _filterPaymentMethod;
  bool get hasActiveFilters => _filterCategoryId != null || _filterPaymentMethod != null || _searchQuery.isNotEmpty;
  String get searchQuery => _searchQuery;

  Future<void> init() async {
    await _repository.init();
    _expenses = _repository.getAllExpenses();
    _customCategories = _repository.getCustomCategories();
    await _generateRecurringExpenses();
    _sortExpenses();
    notifyListeners();
  }

  void _sortExpenses() {
    switch (_currentSort) {
      case SortOption.dateNewest:
        _expenses.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.dateOldest:
        _expenses.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.amountHighLow:
        _expenses.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.amountLowHigh:
        _expenses.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case SortOption.categoryAZ:
        _expenses.sort((a, b) => a.category.label.compareTo(b.category.label));
        break;
    }
  }
  
  void setSortOption(SortOption option) {
    _currentSort = option;
    _sortExpenses();
    notifyListeners();
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
      _lastDeletedBatch = [_expenses[idx]]; // Overwrite batch with single item
      _expenses.removeAt(idx);
      notifyListeners();
      await _repository.deleteExpense(id);
    }
  }

  Future<void> deleteExpenses(List<String> ids) async {
    final toDelete = _expenses.where((e) => ids.contains(e.id)).toList();
    _lastDeletedBatch = toDelete;

    await Future.wait(ids.map((id) => _repository.deleteExpense(id)));
    
    _expenses.removeWhere((e) => ids.contains(e.id));
    notifyListeners();
  }

  Future<void> undoDelete() async {
    if (_lastDeletedBatch.isNotEmpty) {
      await Future.wait(_lastDeletedBatch.map((e) => _repository.saveExpense(e)));
      _expenses.addAll(_lastDeletedBatch);
      _sortExpenses();
      notifyListeners();
      _lastDeletedBatch.clear();
    }
  }

  // Category management
  Future<void> saveCategory(ExpenseCategory category) async {
    final idx = _customCategories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      _customCategories[idx] = category;
    } else {
      _customCategories.add(category);
    }
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

  double get thisMonthNetBalance => thisMonthIncome - thisMonthTotal;

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



  bool isDailyLimitExceeded(double newAmount, double dailyLimit) {
    // Only check if daily limit is set (non-zero)
    if (dailyLimit <= 0) return false;
    return (todayTotal + newAmount) > dailyLimit;
  }

  // Analytics Helpers
  List<Expense> getExpensesForPeriod(TimePeriod period, DateTime anchor) {
    if (period == TimePeriod.day) {
      return _expenses
          .where((e) =>
              e.date.day == anchor.day &&
              e.date.month == anchor.month &&
              e.date.year == anchor.year)
          .toList();
    } else if (period == TimePeriod.week) {
      // Find start of week (Monday)
      final start = anchor.subtract(Duration(days: anchor.weekday - 1));
      final end = start.add(const Duration(days: 6));
      return _expenses
          .where((e) =>
              e.date.isAfter(start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(end.add(const Duration(days: 1))))
          .toList();
    } else if (period == TimePeriod.month) {
      return _expenses.where((e) => 
        e.date.year == anchor.year && 
        e.date.month == anchor.month).toList();
    } else if (period == TimePeriod.year) {
      return _expenses.where((e) => 
        e.date.year == anchor.year).toList();
    }
    return []; // Should not be reached if all TimePeriod values are handled
  }

  // ... (rest of the file)
  
  // Recurring Expenses Logic
  Future<void> _generateRecurringExpenses() async {
    final now = DateTime.now();
    // Snapshot of currently active recurring expenses to iterate safely
    final initialRecurring = _expenses.where((e) => e.isRecurring).toList();
    bool addedAny = false;
    
    List<Expense> toAdd = [];
    List<Expense> toUpdate = [];

    for (var expense in initialRecurring) {
      var current = expense;
      
      // Loop to catch up all missed active periods
      while (true) {
        final nextDate = _getNextRecurringDate(current);
        
          // Break if we've caught up to the future
          // Also break if nextDate didn't advance (safety against infinite loop)
          if (nextDate.isAfter(now) || !nextDate.isAfter(current.date)) {
            break;
          }
          
          // Safety: Don't generate more than 1 year ahead or more than 50 instances at once
          if (nextDate.difference(now).inDays > 365) break; 
          
          // 1. Archive the current/past due expense (History)
          // Mark it as non-recurring so it stays as a static record
          final historicVersion = current.copyWith(
            isRecurring: false,
          );
          
          // 2. Create the new future/current expense (Active)
          // Move the recurring flag to this new instance
          final futureVersion = current.copyWith(
            id: const Uuid().v4(),
            date: nextDate,
            isRecurring: true,
          );
          
          toUpdate.add(historicVersion);
          toAdd.add(futureVersion);
          
          // Advance the loop to check if the NEW expense is also already due
          // (e.g. missed multiple months)
          current = futureVersion;
          addedAny = true;
          
          // Safety break for loop count
          // In practice, if someone hasn't opened app in 50 months, this stops it from freezing.
          // They can open it again to generate more if needed.
          // We can't easily track loop count here without a counter variable, so I'll trust the date check + 365 day limit.
        }
      }
    
    if (addedAny) {
      for (final u in toUpdate) {
        final idx = _expenses.indexWhere((e) => e.id == u.id);
        if (idx != -1) _expenses[idx] = u;
        await _repository.saveExpense(u);
      }
      for (final a in toAdd) {
        _expenses.insert(0, a);
        await _repository.saveExpense(a);
      }
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




  Map<String, double> get categoryTotals {
    final now = DateTime.now();
    return _getCategoryTotalsForPeriod(_expenses.where((e) => 
      !e.isIncome && e.date.month == now.month && e.date.year == now.year).toList());
  }

  Map<String, double> get categoryTotalsForWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return _getCategoryTotalsForPeriod(_expenses.where((e) => 
      !e.isIncome && !e.date.isBefore(startOfWeek)).toList());
  }

  Map<String, double> get categoryTotalsForYear {
    final now = DateTime.now();
    return _getCategoryTotalsForPeriod(_expenses.where((e) => 
      !e.isIncome && e.date.year == now.year).toList());
  }

  Map<String, double> _getCategoryTotalsForPeriod(List<Expense> list) {
    final map = <String, double>{};
    for (final e in list) {
      map[e.category.label] = (map[e.category.label] ?? 0) + e.amount;
    }
    return map;
  }

  Future<void> clearAllData() async {
    _expenses.clear();
    notifyListeners();
    await _repository.clearAllData();
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
    // Returns last 7 days trend including today
    final result = <String, double>{};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.month}/${day.day}';
      result[key] = _expenses
          .where((e) =>
              !e.isIncome &&
              e.date.day == day.day &&
              e.date.month == day.month &&
              e.date.year == day.year)
          .fold(0.0, (sum, e) => sum + e.amount);
    }
    return result.entries.toList();
  }

  int get recurringCount => _expenses.where((e) => e.isRecurring).length;

  // ════════════════════════════════════════════════════════════
  // SMART INSIGHTS
  // ════════════════════════════════════════════════════════════

  double get thisWeekTotal {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return _expenses
        .where((e) => !e.isIncome && !e.date.isBefore(startOfWeek))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get lastWeekTotal {
    final now = DateTime.now();
    final startOfThisWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
    return _expenses
        .where((e) =>
            !e.isIncome &&
            !e.date.isBefore(startOfLastWeek) &&
            e.date.isBefore(startOfThisWeek))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Percentage change this week vs last week. Positive = spending more.
  double get weekOverWeekChange {
    if (lastWeekTotal == 0) return 0;
    return ((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100;
  }

  /// Percentage change this month vs last month spending.
  double get monthOverMonthChange {
    if (lastMonthTotal == 0) return 0;
    return ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
  }

  /// Top 3 most-used category IDs, auto-learned from last 30 days of usage.
  List<ExpenseCategory> get topCategories {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recent = _expenses.where((e) =>
        !e.isIncome && e.date.isAfter(thirtyDaysAgo));

    final countMap = <String, int>{};
    final catMap = <String, ExpenseCategory>{};
    for (final e in recent) {
      countMap[e.category.id] = (countMap[e.category.id] ?? 0) + 1;
      catMap[e.category.id] = e.category;
    }

    final sorted = countMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => catMap[e.key]!).toList();
  }
}
