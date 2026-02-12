import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  static const String _boxName = 'expenses';
  static const String _categoryBoxName = 'custom_categories';
  List<Expense> _expenses = [];
  List<ExpenseCategory> _customCategories = [];
  Expense? _lastDeleted;
  String _searchQuery = '';
  String? _filterCategoryId;
  PaymentMethod? _filterPaymentMethod;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<Expense> get expenses => _getFilteredExpenses();
  List<Expense> get allExpenses => List.unmodifiable(_expenses);
  List<ExpenseCategory> get allCategories => [
        ...ExpenseCategory.defaults,
        ..._customCategories,
      ];
  Expense? get lastDeleted => _lastDeleted;
  String get searchQuery => _searchQuery;

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final catBox = await Hive.openBox(_categoryBoxName);
    _expenses = box.values
        .map((e) => Expense.fromMap(e as Map<dynamic, dynamic>))
        .toList();
    _customCategories = catBox.values
        .map((e) => ExpenseCategory.fromMap(e as Map<dynamic, dynamic>))
        .toList();
    if (_expenses.isEmpty) _loadSampleData();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void _loadSampleData() {
    final now = DateTime.now();
    _expenses = [
      Expense(id: const Uuid().v4(), title: 'Uber Trip', amount: 24.50,
        category: ExpenseCategory.transport, date: now,
        paymentMethod: PaymentMethod.upi, notes: 'Ride to downtown'),
      Expense(id: const Uuid().v4(), title: 'Starbucks', amount: 6.75,
        category: ExpenseCategory.food, date: now.subtract(const Duration(hours: 2)),
        paymentMethod: PaymentMethod.card, notes: 'Morning latte'),
      Expense(id: const Uuid().v4(), title: 'Apple Store', amount: 199.00,
        category: ExpenseCategory.shopping, date: now.subtract(const Duration(days: 1)),
        paymentMethod: PaymentMethod.card, notes: 'AirPods Pro'),
      Expense(id: const Uuid().v4(), title: 'Gym Membership', amount: 45.00,
        category: ExpenseCategory.health, date: now.subtract(const Duration(days: 2)),
        paymentMethod: PaymentMethod.bankTransfer, isRecurring: true,
        recurringType: RecurringType.monthly, notes: 'Monthly subscription'),
      Expense(id: const Uuid().v4(), title: 'Whole Foods', amount: 120.00,
        category: ExpenseCategory.food, date: now.subtract(const Duration(days: 1)),
        paymentMethod: PaymentMethod.card, notes: 'Weekly groceries'),
      Expense(id: const Uuid().v4(), title: 'Netflix', amount: 15.99,
        category: ExpenseCategory.subscriptions, date: now.subtract(const Duration(days: 3)),
        paymentMethod: PaymentMethod.card, isRecurring: true,
        recurringType: RecurringType.monthly, notes: 'Premium plan'),
      Expense(id: const Uuid().v4(), title: 'Rent Payment', amount: 1200.00,
        category: ExpenseCategory.housing, date: now.subtract(const Duration(days: 5)),
        paymentMethod: PaymentMethod.bankTransfer, isRecurring: true,
        recurringType: RecurringType.monthly),
      Expense(id: const Uuid().v4(), title: 'Gas Station', amount: 55.00,
        category: ExpenseCategory.transport, date: now.subtract(const Duration(days: 3)),
        paymentMethod: PaymentMethod.card),
      Expense(id: const Uuid().v4(), title: 'Movie Tickets', amount: 32.00,
        category: ExpenseCategory.fun, date: now.subtract(const Duration(days: 4)),
        paymentMethod: PaymentMethod.upi, notes: 'IMAX showing'),
      Expense(id: const Uuid().v4(), title: 'Electricity Bill', amount: 85.00,
        category: ExpenseCategory.housing, date: now.subtract(const Duration(days: 6)),
        paymentMethod: PaymentMethod.bankTransfer, isRecurring: true,
        recurringType: RecurringType.monthly),
      Expense(id: const Uuid().v4(), title: 'Pizza Night', amount: 42.00,
        category: ExpenseCategory.food, date: now.subtract(const Duration(days: 7)),
        paymentMethod: PaymentMethod.cash, notes: 'Dinner with friends',
        splits: [
          const ExpenseSplit(personId: '2', personName: 'Sarah Chen', amount: 14.00),
          const ExpenseSplit(personId: '3', personName: 'Marcus Vance', amount: 14.00),
        ]),
      Expense(id: const Uuid().v4(), title: 'Spotify', amount: 9.99,
        category: ExpenseCategory.subscriptions, date: now.subtract(const Duration(days: 8)),
        paymentMethod: PaymentMethod.card, isRecurring: true,
        recurringType: RecurringType.monthly),
    ];
    _saveAll();
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
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    await _save(expense);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      _expenses[idx] = expense;
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      await _save(expense);
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String id) async {
    final idx = _expenses.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _lastDeleted = _expenses.removeAt(idx);
      final box = await Hive.openBox(_boxName);
      await box.delete(id);
      notifyListeners();
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
    final box = await Hive.openBox(_categoryBoxName);
    await box.put(category.id, category.toMap());
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _customCategories.removeWhere((c) => c.id == id);
    final box = await Hive.openBox(_categoryBoxName);
    await box.delete(id);
    notifyListeners();
  }

  // Computed properties
  double get totalSpent =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get thisMonthTotal {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get lastMonthTotal {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return _expenses
        .where((e) => e.date.month == lastMonth.month && e.date.year == lastMonth.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get todayTotal {
    final today = DateTime.now();
    return _expenses
        .where((e) =>
            e.date.day == today.day &&
            e.date.month == today.month &&
            e.date.year == today.year)
        .fold(0.0, (sum, e) => sum + e.amount);
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

  // Persistence
  Future<void> _save(Expense expense) async {
    final box = await Hive.openBox(_boxName);
    await box.put(expense.id, expense.toMap());
  }

  Future<void> _saveAll() async {
    final box = await Hive.openBox(_boxName);
    for (final e in _expenses) {
      await box.put(e.id, e.toMap());
    }
  }
}
