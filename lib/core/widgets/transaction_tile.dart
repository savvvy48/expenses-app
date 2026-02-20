import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../../models/expense.dart';

/// A single transaction row matching the fintech reference design.
class TransactionTile extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  final String currencySymbol;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.expense,
    required this.isDark,
    required this.currencySymbol,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = expense.category.color;
    final amountStr = expense.isIncome
        ? '+$currencySymbol${expense.amount.toStringAsFixed(2)}'
        : '-$currencySymbol${expense.amount.toStringAsFixed(2)}';
    final amountColor = expense.isIncome ? AppColors.success : AppColors.error;
    final timeStr = DateFormat('hh:mm a').format(expense.date);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // ─── Avatar ───
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: catColor.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                expense.category.icon,
                color: catColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // ─── Title + Category ───
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expense.category.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Amount + Time ───
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountStr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
