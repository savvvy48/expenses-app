import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/budget.dart';

/// Simplified to 3 states as per the blueprint:
/// OK = within budget, Warning = 80%+, Over = 100%+
enum BudgetStatus { ok, warning, over }

class BudgetProvider extends ChangeNotifier {
  static const String _boxName = 'budget';
  Budget _budget = const Budget(id: 'default');

  Budget get budget => _budget;
  double get monthlyLimit => _budget.monthlyLimit;
  double get dailyLimit => _budget.dailyLimit;

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final data = box.get('default');
    if (data != null) {
      _budget = Budget.fromMap(data as Map<dynamic, dynamic>);
    }
    notifyListeners();
  }

  double monthlyUtilization(double spent) =>
      _budget.monthlyLimit > 0 ? (spent / _budget.monthlyLimit).clamp(0.0, 1.5) : 0;

  double dailyUtilization(double spent) =>
      _budget.dailyLimit > 0 ? (spent / _budget.dailyLimit).clamp(0.0, 1.5) : 0;

  bool isOverMonthlyBudget(double spent) =>
      _budget.monthlyLimit > 0 && spent >= _budget.monthlyLimit;
  bool isNearMonthlyBudget(double spent) =>
      _budget.monthlyLimit > 0 && spent >= _budget.monthlyLimit * 0.8;
  bool isOverDailyBudget(double spent) =>
      _budget.dailyLimit > 0 && spent >= _budget.dailyLimit;

  /// Simplified 3-state budget status
  BudgetStatus getBudgetStatus(double spent, double limit) {
    if (limit <= 0) return BudgetStatus.ok;
    final usage = spent / limit;
    if (usage >= 1.0) return BudgetStatus.over;
    if (usage >= 0.8) return BudgetStatus.warning;
    return BudgetStatus.ok;
  }

  Color statusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.over:
        return const Color(0xFFEF4444); // Red
      case BudgetStatus.warning:
        return const Color(0xFFF59E0B); // Amber
      case BudgetStatus.ok:
        return const Color(0xFF10B981); // Green
    }
  }

  Color budgetColor(double utilization) {
    if (utilization >= 1.0) return statusColor(BudgetStatus.over);
    if (utilization >= 0.8) return statusColor(BudgetStatus.warning);
    return statusColor(BudgetStatus.ok);
  }

  String statusLabel(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.over:
        return 'Over Budget';
      case BudgetStatus.warning:
        return 'Nearing Limit';
      case BudgetStatus.ok:
        return 'On Track';
    }
  }

  Future<void> setMonthlyLimit(double limit) async {
    _budget = _budget.copyWith(monthlyLimit: limit);
    await _save();
    notifyListeners();
  }

  Future<void> setDailyLimit(double limit) async {
    _budget = _budget.copyWith(dailyLimit: limit);
    await _save();
    notifyListeners();
  }

  Future<void> setCategoryLimit(String categoryId, double limit) async {
    final limits = Map<String, double>.from(_budget.categoryLimits);
    limits[categoryId] = limit;
    _budget = _budget.copyWith(categoryLimits: limits);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final box = await Hive.openBox(_boxName);
    await box.put('default', _budget.toMap());
  }
}
