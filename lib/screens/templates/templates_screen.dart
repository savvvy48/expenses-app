import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_feedback.dart';
import '../../providers/expense_provider.dart';

import '../add_expense/add_expense_screen.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    final templates = provider.allExpenses.where((e) => e.isTemplate).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Templates'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: templates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.copy_all_rounded,
                      size: 64,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('No templates yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.5))),
                  const SizedBox(height: 8),
                  Text('Save an expense as template to see it here',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              separatorBuilder: (ctx, index) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final template = templates[i];
                return Dismissible(
                  key: ValueKey(template.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    color: AppColors.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    AppFeedback.onDelete();
                    provider.deleteExpense(template.id);
                  },
                  child: GestureDetector(
                    onTap: () {
                      AppFeedback.onTap();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddExpenseScreen(template: template),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: template.category.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(template.category.icon,
                                color: template.category.color, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(template.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  '${template.currency == 'USD' ? '\$' : template.currency} ${template.amount.toStringAsFixed(2)} • ${template.category.label}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
