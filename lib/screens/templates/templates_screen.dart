import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../add_expense/add_expense_screen.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final templates = context.watch<ExpenseProvider>().templates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
        centerTitle: true,
      ),
      body: templates.isEmpty
          ? const Center(
              child: EmptyStateWidget(
                icon: Icons.auto_awesome_rounded,
                title: 'No templates yet',
                subtitle: 'Save frequent expenses as templates to add them faster',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return AnimatedListItem(
                  index: index,
                  child: _TemplateCard(
                    template: template,
                    isDark: isDark,
                  ),
                );
              },
            ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final Expense template; // Changed from ExpenseTemplate to Expense
  final bool isDark;

  const _TemplateCard({required this.template, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(template: template),
            ),
          );
        },
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: template.category.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(template.category.icon, color: template.category.color),
        ),
        title: Text(
          template.title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${template.isIncome ? 'Income' : 'Expense'} • ${template.paymentMethod.label}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }
}
