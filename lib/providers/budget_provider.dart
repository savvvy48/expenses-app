import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/budget.dart';

enum BudgetStatus { safe, notice, warning, critical, exceeded }

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
      (spent / _budget.monthlyLimit).clamp(0.0, 1.5);

  double dailyUtilization(double spent) =>
      (spent / _budget.dailyLimit).clamp(0.0, 1.5);

  bool isOverMonthlyBudget(double spent) => spent >= _budget.monthlyLimit;
  bool isNearMonthlyBudget(double spent) => spent >= _budget.monthlyLimit * 0.8;
  bool isOverDailyBudget(double spent) => spent >= _budget.dailyLimit;

  BudgetStatus getBudgetStatus(double spent, double limit) {
    if (limit <= 0) return BudgetStatus.safe;
    final usage = spent / limit;
    if (usage >= 1.0) return BudgetStatus.exceeded;
    if (usage >= 0.9) return BudgetStatus.critical;
    if (usage >= 0.75) return BudgetStatus.warning;
    if (usage >= 0.5) return BudgetStatus.notice;
    return BudgetStatus.safe;
  }

  Color statusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.exceeded:
        return const Color(0xFFD63031); // Dark Red
      case BudgetStatus.critical:
        return const Color(0xFFFF7675); // Red
      case BudgetStatus.warning:
        return const Color(0xFFFD9644); // Orange
      case BudgetStatus.notice:
        return const Color(0xFFFDCB6E); // Yellow
      case BudgetStatus.safe:
        return const Color(0xFF00B894); // Green
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
