class ValidationResult {
  final bool isValid;
  final String? message;

  const ValidationResult.valid() : isValid = true, message = null;
  const ValidationResult.invalid(this.message) : isValid = false;
}

class ValidationService {
  static ValidationResult validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const ValidationResult.invalid('Title is required');
    }
    if (value.length > 50) {
      return const ValidationResult.invalid('Title must be under 50 characters');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.invalid('Amount is required');
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return const ValidationResult.invalid('Invalid amount format');
    }
    if (amount <= 0) {
      return const ValidationResult.invalid('Amount must be positive');
    }
    if (amount > 1000000) { // Reasonable cap
      return const ValidationResult.invalid('Amount exceeds maximum limit');
    }
    return const ValidationResult.valid();
  }

  static ValidationResult validateSplits(double totalAmount, double splitSum) {
    // Allow small floating point error
    if ((totalAmount - splitSum).abs() > 0.01) {
      return ValidationResult.invalid(
        'Split total must equal expense amount (diff: ${(totalAmount - splitSum).toStringAsFixed(2)})'
      );
    }
    return const ValidationResult.valid();
  }
}
