import 'package:flutter/material.dart';

// Payment methods
enum PaymentMethod {
  cash('Cash', Icons.money_rounded),
  card('Card', Icons.credit_card_rounded),
  upi('UPI', Icons.phone_android_rounded),
  bankTransfer('Bank Transfer', Icons.account_balance_rounded),
  wallet('Wallet', Icons.account_balance_wallet_rounded);

  const PaymentMethod(this.label, this.icon);
  final String label;
  final IconData icon;
}

// Recurring type
enum RecurringType {
  none('None'),
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const RecurringType(this.label);
  final String label;
}

// Expense category with customizable properties
class ExpenseCategory {
  final String id;
  final String label;
  final int iconCodePoint;
  final int colorValue;
  final bool isCustom;

  const ExpenseCategory({
    required this.id,
    required this.label,
    required this.iconCodePoint,
    required this.colorValue,
    this.isCustom = false,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'isCustom': isCustom,
      };

  factory ExpenseCategory.fromMap(Map<dynamic, dynamic> map) => ExpenseCategory(
        id: map['id'] as String,
        label: map['label'] as String,
        iconCodePoint: map['iconCodePoint'] as int,
        colorValue: map['colorValue'] as int,
        isCustom: map['isCustom'] as bool? ?? false,
      );

  // Default categories
  static final housing = ExpenseCategory(
    id: 'housing', label: 'Housing',
    iconCodePoint: Icons.home_rounded.codePoint, colorValue: 0xFF6C5CE7,
  );
  static final food = ExpenseCategory(
    id: 'food', label: 'Food',
    iconCodePoint: Icons.restaurant_rounded.codePoint, colorValue: 0xFFFF7675,
  );
  static final transport = ExpenseCategory(
    id: 'transport', label: 'Transport',
    iconCodePoint: Icons.directions_car_rounded.codePoint, colorValue: 0xFF00B894,
  );
  static final fun = ExpenseCategory(
    id: 'fun', label: 'Fun',
    iconCodePoint: Icons.sports_esports_rounded.codePoint, colorValue: 0xFFD4A017,
  );
  static final subscriptions = ExpenseCategory(
    id: 'subscriptions', label: 'Subscriptions',
    iconCodePoint: Icons.subscriptions_rounded.codePoint, colorValue: 0xFFE17055,
  );
  static final health = ExpenseCategory(
    id: 'health', label: 'Health',
    iconCodePoint: Icons.favorite_rounded.codePoint, colorValue: 0xFF55EFC4,
  );
  static final shopping = ExpenseCategory(
    id: 'shopping', label: 'Shopping',
    iconCodePoint: Icons.shopping_bag_rounded.codePoint, colorValue: 0xFFA29BFE,
  );
  
  // Aliases
  static final entertainment = fun;

  static List<ExpenseCategory> get defaults =>
      [housing, food, transport, fun, subscriptions, health, shopping];
}

// Split info for an expense
class ExpenseSplit {
  final String personId;
  final String personName;
  final double amount;
  final bool isPaid;

  const ExpenseSplit({
    required this.personId,
    required this.personName,
    required this.amount,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() => {
        'personId': personId,
        'personName': personName,
        'amount': amount,
        'isPaid': isPaid,
      };

  factory ExpenseSplit.fromMap(Map<dynamic, dynamic> map) => ExpenseSplit(
        personId: map['personId'] as String,
        personName: map['personName'] as String,
        amount: (map['amount'] as num).toDouble(),
        isPaid: map['isPaid'] as bool? ?? false,
      );
}

// Main expense model
class Expense {
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? notes;
  final PaymentMethod paymentMethod;
  final String currency;
  final bool isRecurring;
  final RecurringType recurringType;
  final List<String> receiptPaths;
  final List<ExpenseSplit> splits;
  final bool isIncome;
  final DateTime createdAt;
  final bool isTemplate;

  // Backward compatibility
  String? get receiptPath => receiptPaths.isEmpty ? null : receiptPaths.first;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.paymentMethod = PaymentMethod.cash,
    this.currency = 'USD',
    this.isRecurring = false,
    this.recurringType = RecurringType.none,
    List<String>? receiptPaths,
    String? receiptPath, // Legacy support
    this.splits = const [],
    this.isIncome = false,
    DateTime? createdAt,
    this.isTemplate = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        receiptPaths = receiptPaths ?? (receiptPath != null ? [receiptPath] : []);

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? notes,
    PaymentMethod? paymentMethod,
    String? currency,
    bool? isRecurring,
    RecurringType? recurringType,
    List<String>? receiptPaths,
    List<ExpenseSplit>? splits,
    bool? isIncome,
    bool? isTemplate,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      currency: currency ?? this.currency,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      receiptPaths: receiptPaths ?? this.receiptPaths,
      splits: splits ?? this.splits,
      isIncome: isIncome ?? this.isIncome,
      createdAt: createdAt,
      isTemplate: isTemplate ?? this.isTemplate,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'categoryId': category.id,
        'categoryLabel': category.label,
        'categoryIcon': category.iconCodePoint,
        'categoryColor': category.colorValue,
        'date': date.millisecondsSinceEpoch,
        'notes': notes,
        'paymentMethod': paymentMethod.index,
        'currency': currency,
        'isRecurring': isRecurring,
        'recurringType': recurringType.index,
        'receiptPaths': receiptPaths,
        'splits': splits.map((s) => s.toMap()).toList(),
        'isIncome': isIncome,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isTemplate': isTemplate,
      };

  factory Expense.fromMap(Map<dynamic, dynamic> map) {
    var paths = (map['receiptPaths'] as List<dynamic>?)?.cast<String>() ?? [];
    if (paths.isEmpty && map['receiptPath'] != null) {
      paths = [map['receiptPath'] as String];
    }

    return Expense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory(
        id: map['categoryId'] as String,
        label: map['categoryLabel'] as String,
        iconCodePoint: map['categoryIcon'] as int,
        colorValue: map['categoryColor'] as int,
      ),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      notes: map['notes'] as String?,
      paymentMethod: PaymentMethod.values[map['paymentMethod'] as int? ?? 0],
      currency: map['currency'] as String? ?? 'USD',
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurringType: RecurringType.values[map['recurringType'] as int? ?? 0],
      receiptPaths: paths,
      splits: (map['splits'] as List<dynamic>?)
              ?.map((s) => ExpenseSplit.fromMap(s as Map<dynamic, dynamic>))
              .toList() ??
          [],
      isIncome: map['isIncome'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      isTemplate: map['isTemplate'] as bool? ?? false,
    );
  }
}
