import '../../models/expense.dart';

/// Parses natural language input like "Spent 450 on lunch at McDonald's"
/// or "Paid 200 for uber" into structured expense data.
class NLPExpenseParser {
  NLPExpenseParser._();

  /// Attempts to parse a natural-language string into expense parts.
  /// Returns null if parsing fails.
  static ParsedExpense? parse(String input) {
    if (input.trim().isEmpty) return null;

    final text = input.trim().toLowerCase();
    double? amount;
    String? title;
    ExpenseCategory? category;

    // ─── Extract Amount ───
    // Matches: 450, ₹450, $450, 1,200.50, Rs 300, etc.
    final amountRegex = RegExp(
      r'(?:₹|\$|€|£|rs\.?\s*)?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch != null) {
      final raw = amountMatch.group(1)!.replaceAll(',', '');
      amount = double.tryParse(raw);
    }

    // ─── Extract Category (keyword matching) ───
    category = _detectCategory(text);

    // ─── Extract Title ───
    // Remove amount and common prefixes, keep the rest as title
    var titleText = text;

    // Remove common prefixes
    final prefixes = [
      'spent', 'paid', 'bought', 'ordered', 'got', 'had',
      'for', 'on', 'at', 'to',
    ];
    for (final prefix in prefixes) {
      titleText = titleText.replaceAll(RegExp('\\b$prefix\\b'), '');
    }

    // Remove the amount match
    if (amountMatch != null) {
      titleText = titleText.replaceFirst(amountMatch.group(0)!, '');
    }

    // Remove currency symbols
    titleText = titleText
        .replaceAll(RegExp(r'[₹$€£]'), '')
        .replaceAll(RegExp(r'\brs\.?\b', caseSensitive: false), '')
        .trim();

    // Clean up extra spaces
    titleText = titleText.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Capitalize first letter
    if (titleText.isNotEmpty) {
      title = titleText[0].toUpperCase() + titleText.substring(1);
    }

    // Need at least an amount to be useful
    if (amount == null || amount <= 0) return null;

    return ParsedExpense(
      amount: amount,
      title: title,
      category: category,
    );
  }

  static ExpenseCategory? _detectCategory(String text) {
    final categoryKeywords = <String, ExpenseCategory>{
      // Food
      'food': ExpenseCategory.food,
      'lunch': ExpenseCategory.food,
      'dinner': ExpenseCategory.food,
      'breakfast': ExpenseCategory.food,
      'restaurant': ExpenseCategory.food,
      'coffee': ExpenseCategory.food,
      'snack': ExpenseCategory.food,
      'pizza': ExpenseCategory.food,
      'burger': ExpenseCategory.food,
      'groceries': ExpenseCategory.food,
      'grocery': ExpenseCategory.food,
      'swiggy': ExpenseCategory.food,
      'zomato': ExpenseCategory.food,
      'mcdonald': ExpenseCategory.food,
      'dominos': ExpenseCategory.food,
      'eat': ExpenseCategory.food,
      'chai': ExpenseCategory.food,
      'tea': ExpenseCategory.food,
      'biryani': ExpenseCategory.food,

      // Transport
      'uber': ExpenseCategory.transport,
      'ola': ExpenseCategory.transport,
      'rapido': ExpenseCategory.transport,
      'cab': ExpenseCategory.transport,
      'taxi': ExpenseCategory.transport,
      'auto': ExpenseCategory.transport,
      'petrol': ExpenseCategory.transport,
      'diesel': ExpenseCategory.transport,
      'fuel': ExpenseCategory.transport,
      'gas': ExpenseCategory.transport,
      'metro': ExpenseCategory.transport,
      'bus': ExpenseCategory.transport,
      'train': ExpenseCategory.transport,
      'flight': ExpenseCategory.transport,
      'ride': ExpenseCategory.transport,
      'parking': ExpenseCategory.transport,
      'toll': ExpenseCategory.transport,

      // Housing
      'rent': ExpenseCategory.housing,
      'electricity': ExpenseCategory.housing,
      'water bill': ExpenseCategory.housing,
      'maintenance': ExpenseCategory.housing,
      'wifi': ExpenseCategory.housing,
      'internet': ExpenseCategory.housing,
      'gas bill': ExpenseCategory.housing,

      // Subscriptions
      'netflix': ExpenseCategory.subscriptions,
      'spotify': ExpenseCategory.subscriptions,
      'amazon prime': ExpenseCategory.subscriptions,
      'hotstar': ExpenseCategory.subscriptions,
      'youtube': ExpenseCategory.subscriptions,
      'subscription': ExpenseCategory.subscriptions,
      'apple music': ExpenseCategory.subscriptions,
      'icloud': ExpenseCategory.subscriptions,

      // Health
      'medicine': ExpenseCategory.health,
      'doctor': ExpenseCategory.health,
      'hospital': ExpenseCategory.health,
      'gym': ExpenseCategory.health,
      'pharma': ExpenseCategory.health,
      'medical': ExpenseCategory.health,
      'health': ExpenseCategory.health,

      // Shopping
      'clothes': ExpenseCategory.shopping,
      'amazon': ExpenseCategory.shopping,
      'flipkart': ExpenseCategory.shopping,
      'myntra': ExpenseCategory.shopping,
      'shopping': ExpenseCategory.shopping,
      'shoes': ExpenseCategory.shopping,
      'gadget': ExpenseCategory.shopping,
      'electronics': ExpenseCategory.shopping,

      // Fun
      'movie': ExpenseCategory.fun,
      'game': ExpenseCategory.fun,
      'party': ExpenseCategory.fun,
      'concert': ExpenseCategory.fun,
      'fun': ExpenseCategory.fun,
      'drinks': ExpenseCategory.fun,
      'beer': ExpenseCategory.fun,
      'bar': ExpenseCategory.fun,
      'club': ExpenseCategory.fun,
    };

    for (final entry in categoryKeywords.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }
}

class ParsedExpense {
  final double amount;
  final String? title;
  final ExpenseCategory? category;

  const ParsedExpense({
    required this.amount,
    this.title,
    this.category,
  });
}
