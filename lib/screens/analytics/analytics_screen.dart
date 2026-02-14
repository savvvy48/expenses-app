import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/count_up_text.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 2; // 0=Day, 1=Week, 2=Month

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    
    // Get parameters for query
    final now = DateTime.now();
    String periodKey = 'Month';
    if (_selectedPeriod == 0) periodKey = 'Day';
    if (_selectedPeriod == 1) periodKey = 'Week';
    
    // Filter expenses based on selection
    final filteredExpenses = provider.getExpensesForPeriod(periodKey, now);
    
    // Calculate totals from filtered list
    final categoryTotals = <String, double>{};
    final personTotals = <String, double>{};
    double totalAmount = 0;

    for (final e in filteredExpenses) {
      // Only include expenses, not income
      if (e.isIncome) continue;
      
      totalAmount += e.amount;
      categoryTotals.update(e.category.id, (v) => v + e.amount, ifAbsent: () => e.amount);
      
      for (final split in e.splits) {
        personTotals.update(split.personId, (v) => v + split.amount, ifAbsent: () => split.amount);
      }
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedListItem(
              index: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Analytics',
                      style: theme.textTheme.headlineMedium),
                  _PeriodToggle(
                    selected: _selectedPeriod,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPeriod = v);
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Animated Pie Chart
            AnimatedListItem(
              index: 1,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                  boxShadow: AppColors.sharpShadow(isDark),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Spending Overview',
                            style: theme.textTheme.titleMedium),
                        CountUpText(
                          end: totalAmount,
                          prefix: '\$',
                          decimals: 2,
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (categoryTotals.isEmpty)
                      const SizedBox(
                        height: 250,
                        child: EmptyStateWidget(
                          title: 'No Data',
                          subtitle: 'No expenses for this period',
                          icon: Icons.bar_chart,
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: _AnimatedPieChart(
                          categoryTotals: categoryTotals,
                          totalAmount: totalAmount,
                          categories: provider.allCategories,
                          isDark: isDark,
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Legend
                    ...categoryTotals.entries.toList().asMap().entries.map((e) {
                      final cat = provider.allCategories
                          .firstWhere((c) => c.id == e.value.key,
                              orElse: () => ExpenseCategory.defaults.first);
                      final pct = totalAmount > 0
                          ? (e.value.value / totalAmount * 100)
                          : 0.0;
                      return AnimatedListItem(
                        index: e.key + 2,
                        delay: const Duration(milliseconds: 50),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                  width: 12, height: 12, color: cat.color),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(cat.label,
                                    style: theme.textTheme.bodyLarge),
                              ),
                              Text('\$${e.value.value.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 44,
                                child: Text('${pct.toStringAsFixed(0)}%',
                                    textAlign: TextAlign.right,
                                    style: theme.textTheme.bodySmall),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category Bars with animated widths
            AnimatedListItem(
              index: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                  boxShadow: AppColors.subtleShadow(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category Breakdown',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    if (categoryTotals.isEmpty)
                      Text('No data', style: theme.textTheme.bodySmall)
                    else
                      ...categoryTotals.entries.toList().asMap().entries.map((e) {
                        final cat = provider.allCategories
                            .firstWhere((c) => c.id == e.value.key,
                                orElse: () => ExpenseCategory.defaults.first);
                        final ratio =
                            totalAmount > 0 ? e.value.value / totalAmount : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      color:
                                          cat.color.withValues(alpha: 0.12),
                                      child: Icon(cat.icon,
                                          color: cat.color, size: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(cat.label,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(fontSize: 13)),
                                  ]),
                                  Text(
                                      '\$${e.value.value.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 6,
                                color: (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)
                                    .withValues(alpha: 0.5),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: ratio),
                                  duration:
                                      Duration(milliseconds: 600 + e.key * 100),
                                  curve: Curves.easeOutCubic,
                                  builder: (ctx, val, _) =>
                                      FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: val,
                                    child: Container(color: cat.color),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Spending by Person
            AnimatedListItem(
              index: 4,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                  boxShadow: AppColors.subtleShadow(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spending by Person',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    if (personTotals.isEmpty)
                      Text('No split expenses for this period',
                          style: theme.textTheme.bodySmall)
                    else
                      ...personTotals.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((e) => AnimatedListItem(
                                index: e.key,
                                delay: const Duration(milliseconds: 60),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        color: AppColors.primary,
                                        child: Center(
                                          child: Text(
                                              e.value.key.isNotEmpty ? e.value.key[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  fontSize: 14)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Text(e.value.key,
                                              style: theme
                                                  .textTheme.bodyLarge)),
                                      CountUpText(
                                        end: e.value.value,
                                        prefix: '\$',
                                        decimals: 2,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// --- Animated Pie Chart ---
class _AnimatedPieChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final double totalAmount;
  final List<ExpenseCategory> categories;
  final bool isDark;

  const _AnimatedPieChart({
    required this.categoryTotals,
    required this.totalAmount,
    required this.categories,
    required this.isDark,
  });

  @override
  State<_AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<_AnimatedPieChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: _PieChartPainter(
            categoryTotals: widget.categoryTotals,
            totalAmount: widget.totalAmount,
            categories: widget.categories,
            progress: Curves.easeOutCubic.transform(_ctrl.value),
            isDark: widget.isDark,
          ),
        );
      },
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> categoryTotals;
  final double totalAmount;
  final List<ExpenseCategory> categories;
  final double progress;
  final bool isDark;

  _PieChartPainter({
    required this.categoryTotals,
    required this.totalAmount,
    required this.categories,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;
    final totalSweep = 2 * pi * progress;

    for (final entry in categoryTotals.entries) {
      final cat = categories.firstWhere((c) => c.id == entry.key,
          orElse: () => ExpenseCategory.defaults.first);
      final sweepAngle = (entry.value / totalAmount) * totalSweep;

      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Separator line between slices
      final separatorPaint = Paint()
        ..color = isDark ? const Color(0xFF0A0A0A) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(rect, startAngle, sweepAngle, true, separatorPaint);

      startAngle += sweepAngle;
    }

    // Center circle (donut)
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    canvas.drawCircle(center, radius * 0.55, Paint()..color = bgColor);

    // Border circle
    final borderPaint = Paint()
      ..color = isDark ? AppColors.darkBorder : AppColors.lightBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.55, borderPaint);
  }

  @override
  bool shouldRepaint(_PieChartPainter old) =>
      old.progress != progress || old.categoryTotals != categoryTotals;
}

// --- Period Toggle ---
class _PeriodToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _PeriodToggle({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final labels = ['Day', 'Week', 'Month'];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final sel = i == selected;
          return SpringButton(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: sel ? AppColors.primary : Colors.transparent,
              child: Text(labels[i],
                  style: TextStyle(
                    color: sel
                        ? Colors.white
                        : isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  )),
            ),
          );
        }),
      ),
    );
  }
}
