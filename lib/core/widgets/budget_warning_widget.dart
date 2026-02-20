import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../constants/app_colors.dart';
import 'package:provider/provider.dart';

class BudgetWarningWidget extends StatelessWidget {
  const BudgetWarningWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final expProv = context.watch<ExpenseProvider>();
    final budgetProv = context.watch<BudgetProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final limit = budgetProv.monthlyLimit;
    if (limit <= 0) return const SizedBox.shrink();

    final spent = expProv.thisMonthTotal;
    final usage = spent / limit;
    final status = budgetProv.getBudgetStatus(spent, limit);

    // Only show if warning or over
    if (status == BudgetStatus.ok) return const SizedBox.shrink();

    final color = budgetProv.statusColor(status);
    final label = budgetProv.statusLabel(status);
    final pctStr = '${(usage * 100).toStringAsFixed(0)}%';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                status == BudgetStatus.over
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$pctStr of monthly budget used',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Pulsing dot for "over"
            if (status == BudgetStatus.over) _PulseDot(color: color),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
