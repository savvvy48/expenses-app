import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/expense.dart';
import '../constants/app_constants.dart';
import 'expense_repository.dart';

class HiveExpenseRepository implements ExpenseRepository {
  late Box<Map> _expenseBox;
  late Box<Map> _categoryBox;

  @override
  Future<void> init() async {
    try {
      _expenseBox = await Hive.openBox<Map>(AppConstants.boxExpenses);
      _categoryBox = await Hive.openBox<Map>(AppConstants.boxCategories);
    } catch (e, stack) {
      log('Error initializing hive boxes: $e', error: e, stackTrace: stack);
      // In a real app, might want to delete corrupted boxes or show fatal error
      rethrow;
    }
  }

  @override
  List<Expense> getAllExpenses() {
    try {
      return _expenseBox.values
          .map((e) => Expense.fromMap(e))
          .toList();
    } catch (e, stack) {
      log('Error fetching expenses: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Future<void> saveExpense(Expense expense) async {
    try {
      await _expenseBox.put(expense.id, expense.toMap());
    } catch (e, stack) {
      log('Error saving expense ${expense.id}: $e', error: e, stackTrace: stack);
      throw Exception('Failed to save expense');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await _expenseBox.delete(id);
    } catch (e, stack) {
      log('Error deleting expense $id: $e', error: e, stackTrace: stack);
      throw Exception('Failed to delete expense');
    }
  }

  @override
  Future<void> saveAllExpenses(List<Expense> expenses) async {
    try {
      final Map<String, Map<String, dynamic>> batch = {
        for (var e in expenses) e.id: e.toMap()
      };
      await _expenseBox.putAll(batch);
    } catch (e, stack) {
      log('Error batch saving expenses: $e', error: e, stackTrace: stack);
      throw Exception('Failed to save expenses');
    }
  }

  @override
  Future<void> clearAllExpenses() async {
    try {
      await _expenseBox.clear();
    } catch (e, stack) {
      log('Error clearing expenses: $e', error: e, stackTrace: stack);
      throw Exception('Failed to clear data');
    }
  }

  @override
  List<ExpenseCategory> getCustomCategories() {
    try {
      return _categoryBox.values
          .map((e) => ExpenseCategory.fromMap(e))
          .toList();
    } catch (e, stack) {
      log('Error fetching categories: $e', error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Future<void> saveCategory(ExpenseCategory category) async {
    try {
      await _categoryBox.put(category.id, category.toMap());
    } catch (e, stack) {
      log('Error saving category: $e', error: e, stackTrace: stack);
      throw Exception('Failed to save category');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _categoryBox.delete(id);
    } catch (e, stack) {
      log('Error deleting category: $e', error: e, stackTrace: stack);
      throw Exception('Failed to delete category');
    }
  }
}
