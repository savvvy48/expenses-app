import '../../models/expense.dart';
import '../../models/person.dart';

abstract class ExpenseRepository {
  Future<void> init();
  
  // Expenses
  List<Expense> getAllExpenses();
  Future<void> saveExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<void> saveAllExpenses(List<Expense> expenses);
  Future<void> clearAllExpenses();

  // Categories
  List<ExpenseCategory> getCustomCategories();
  Future<void> saveCategory(ExpenseCategory category);
  Future<void> deleteCategory(String id);

  // People
  List<Person> getAllPeople();
  Future<void> addPerson(Person person);

  // System
  Future<void> clearAllData();
}
