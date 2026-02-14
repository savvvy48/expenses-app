import 'package:uuid/uuid.dart';
import '../../models/expense.dart';
import '../../models/person.dart';

class SampleData {
  static List<Expense> getExpenses() {
    final now = DateTime.now();
    return [
      Expense(id: const Uuid().v4(), title: 'Uber Trip', amount: 24.50,
        category: ExpenseCategory.transport, date: now,
        paymentMethod: PaymentMethod.upi, notes: 'Ride to downtown'),
      Expense(id: const Uuid().v4(), title: 'Starbucks', amount: 6.75,
        category: ExpenseCategory.food, date: now.subtract(const Duration(hours: 2)),
        paymentMethod: PaymentMethod.card, notes: 'Morning latte'),
      Expense(id: const Uuid().v4(), title: 'Apple Store', amount: 199.00,
        category: ExpenseCategory.shopping, date: now.subtract(const Duration(days: 1)),
        paymentMethod: PaymentMethod.card, notes: 'AirPods Pro case'),
      Expense(id: const Uuid().v4(), title: 'Netflix', amount: 15.99,
        category: ExpenseCategory.entertainment, date: now.subtract(const Duration(days: 3)),
        paymentMethod: PaymentMethod.card, isRecurring: true, recurringType: RecurringType.monthly),
      Expense(id: const Uuid().v4(), title: 'Grocery Run', amount: 84.32,
        category: ExpenseCategory.food, date: now.subtract(const Duration(days: 2)),
        paymentMethod: PaymentMethod.card),
      Expense(id: const Uuid().v4(), title: 'Rent Payment', amount: 1200.00,
        category: ExpenseCategory.housing, date: DateTime(now.year, now.month, 1),
        paymentMethod: PaymentMethod.bankTransfer, isRecurring: true, recurringType: RecurringType.monthly),
    ];
  }

  static List<Person> getPeople() {
    return [
      Person(id: const Uuid().v4(), name: 'Alice', email: 'alice@example.com', role: 'Admin'),
      Person(id: const Uuid().v4(), name: 'Bob', email: 'bob@example.com', role: 'Member'),
      Person(id: const Uuid().v4(), name: 'Charlie', email: 'charlie@example.com', role: 'Viewer'),
    ];
  }
}
