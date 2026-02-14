import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/expense.dart';
import 'logger_service.dart';

class ExportService {
  static Future<void> exportCSV(List<Expense> expenses) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Date,Title,Amount,Category,Payment Method,Is Recurring,Notes,Splits');
    
    // Rows
    for (final e in expenses) {
      final date = DateFormat('yyyy-MM-dd').format(e.date);
      final title = _escape(e.title);
      final amount = e.amount.toStringAsFixed(2);
      final category = _escape(e.category.label);
      final payment = _escape(e.paymentMethod.label);
      final recurring = e.isRecurring ? 'Yes' : 'No';
      final notes = _escape(e.notes ?? '');
      final splits = _escape(e.splits.map((s) => '${s.personName}:${s.amount}').join('|'));
      
      buffer.writeln('$date,$title,$amount,$category,$payment,$recurring,$notes,$splits');
    }
    
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/expenses_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString());
      
      await Share.shareXFiles([XFile(path)], text: 'Here is my expense export.');
    } catch (e) {
      AppLogger.e('Export error', e);
      rethrow;
    }
  }

  static Future<void> shareSummary(List<Expense> expenses) async {
    final now = DateTime.now();
    final thisMonth = expenses.where((e) => 
      !e.isIncome && 
      e.date.year == now.year && 
      e.date.month == now.month
    ).toList();
    
    final total = thisMonth.fold(0.0, (sum, e) => sum + e.amount);
    final count = thisMonth.length;
    
    // Group by Category
    final byCategory = <String, double>{};
    for (final e in thisMonth) {
      byCategory[e.category.label] = (byCategory[e.category.label] ?? 0) + e.amount;
    }
    
    final sortedCats = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final buffer = StringBuffer();
    buffer.writeln('📅 Expense Summary - ${DateFormat('MMMM yyyy').format(now)}');
    buffer.writeln('Total Spent: \$${total.toStringAsFixed(2)} ($count transactions)');
    buffer.writeln('');
    buffer.writeln('Top Categories:');
    for (var i = 0; i < sortedCats.length && i < 5; i++) {
      final cat = sortedCats[i];
      final pct = (cat.value / total * 100).toStringAsFixed(1);
      buffer.writeln('• ${cat.key}: \$${cat.value.toStringAsFixed(2)} ($pct%)');
    }
    
    await Share.share(buffer.toString());
  }

  static Future<void> exportJSONBackup(List<Expense> expenses, List<ExpenseCategory> customCategories) async {
    final backup = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'customCategories': customCategories.map((c) => c.toMap()).toList(),
    };
    
    try {
      final jsonString = jsonEncode(backup);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/daily_expenses_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
      final file = File(path);
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles([XFile(path)], text: 'Daily Expenses Backup');
    } catch (e) {
      AppLogger.e('Backup error', e);
      rethrow;
    }
  }

  static String _escape(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }
}
