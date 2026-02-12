class Budget {
  final String id;
  final double monthlyLimit;
  final double dailyLimit;
  final Map<String, double> categoryLimits; // categoryId -> limit

  const Budget({
    required this.id,
    this.monthlyLimit = 5000.0,
    this.dailyLimit = 200.0,
    this.categoryLimits = const {},
  });

  Budget copyWith({
    double? monthlyLimit,
    double? dailyLimit,
    Map<String, double>? categoryLimits,
  }) {
    return Budget(
      id: id,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      categoryLimits: categoryLimits ?? this.categoryLimits,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'monthlyLimit': monthlyLimit,
        'dailyLimit': dailyLimit,
        'categoryLimits': categoryLimits,
      };

  factory Budget.fromMap(Map<dynamic, dynamic> map) => Budget(
        id: map['id'] as String? ?? 'default',
        monthlyLimit: (map['monthlyLimit'] as num?)?.toDouble() ?? 5000.0,
        dailyLimit: (map['dailyLimit'] as num?)?.toDouble() ?? 200.0,
        categoryLimits: (map['categoryLimits'] as Map<dynamic, dynamic>?)
                ?.map((k, v) => MapEntry(k as String, (v as num).toDouble())) ??
            {},
      );
}
