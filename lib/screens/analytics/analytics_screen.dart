import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/utils/app_haptics.dart';
import '../../models/expense.dart';
import '../../models/time_period.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  TimePeriod _selectedPeriod = TimePeriod.month;
  final List<TimePeriod> _periods = [
    TimePeriod.week,
    TimePeriod.month,
    TimePeriod.year,
  ];
  int _touchedIndex = -1;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final symbol = settingsProv.currencySymbol;
    final stats = _getStatsByPeriod(provider);
    final totalSpent = stats.values.fold<double>(0, (a, b) => a + b);
    final totalIncome = provider.thisMonthIncome;
    final weeklyTrend = provider.weeklyTrend;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Hero Header with Gradient ───
            SliverToBoxAdapter(
              child: _buildHeroHeader(
                  isDark, totalSpent, totalIncome, symbol, provider),
            ),

            // ─── Period Toggle ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _buildPeriodToggle(isDark),
              ),
            ),

            // ─── Weekly Spending Trend (Bar Chart) ───
            if (weeklyTrend.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildWeeklyTrend(isDark, weeklyTrend, symbol),
              ),

            // ─── Donut Chart + Legend ───
            if (stats.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildDonutSection(isDark, stats, totalSpent, symbol),
              ),

            // ─── Category Breakdown List ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'CATEGORY BREAKDOWN',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
              ),
            ),

            if (stats.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyStateWidget(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'No data yet',
                    subtitle: 'Start tracking expenses to see analytics',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = stats.entries.elementAt(index);
                      final cat = ExpenseCategory.defaults.firstWhere(
                        (c) => c.label == entry.key,
                        orElse: () => ExpenseCategory.defaults.first,
                      );
                      final pct = totalSpent > 0
                          ? (entry.value / totalSpent) * 100
                          : 0.0;

                      return AnimatedListItem(
                        index: index,
                        child: _CategoryBar(
                          icon: cat.icon,
                          color: cat.color,
                          name: entry.key,
                          amount: '$symbol${entry.value.toStringAsFixed(2)}',
                          percentage: pct,
                          isDark: isDark,
                          isHighlighted: _touchedIndex == index,
                        ),
                      );
                    },
                    childCount: stats.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HERO HEADER (Gradient card with total + income/expense)
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeroHeader(bool isDark, double totalSpent, double totalIncome,
      String symbol, ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
              const Color(0xFF4C1D95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              offset: const Offset(0, 12),
              blurRadius: 32,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analytics',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedPeriod.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Big total
            Text(
              'Total Spent',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _animCtrl,
              builder: (context, child) {
                return Text(
                  '$symbol ${(totalSpent * _animCtrl.value).toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Income vs Expense row
            Row(
              children: [
                _HeroStatChip(
                  icon: Icons.trending_up_rounded,
                  label: 'Income',
                  value: '$symbol${totalIncome.toStringAsFixed(0)}',
                  color: AppColors.heroMint,
                ),
                const SizedBox(width: 12),
                _HeroStatChip(
                  icon: Icons.trending_down_rounded,
                  label: 'Spent',
                  value: '$symbol${totalSpent.toStringAsFixed(0)}',
                  color: AppColors.heroPeach,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PERIOD TOGGLE (Full-width pill selector)
  // ═══════════════════════════════════════════════════════════

  Widget _buildPeriodToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF0F0F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: SpringButton(
              onTap: () {
                AppHaptics.onSelection();
                setState(() => _selectedPeriod = period);
                _animCtrl.reset();
                _animCtrl.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isDark ? Colors.white : AppColors.primary)
                                .withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    period.label,
                    style: GoogleFonts.inter(
                      color: isSelected
                          ? (isDark
                              ? AppColors.darkBg
                              : Colors.white)
                          : isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WEEKLY SPENDING TREND (Bar Chart)
  // ═══════════════════════════════════════════════════════════

  Widget _buildWeeklyTrend(
      bool isDark, List<MapEntry<String, double>> trend, String symbol) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxVal = trend.map((e) => e.value).reduce(math.max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Trend',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      tooltipRoundedRadius: 12,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '$symbol${rod.toY.toStringAsFixed(0)}',
                          GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= trend.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              trend[idx].key.length > 3
                                  ? trend[idx].key.substring(0, 3)
                                  : trend[idx].key,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary,
                              ),
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(trend.length, (i) {
                    final isMax = trend[i].value == maxVal && maxVal > 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: trend[i].value,
                          width: 20,
                          borderRadius: BorderRadius.circular(8),
                          gradient: isMax
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                )
                              : LinearGradient(
                                  colors: isDark
                                      ? [
                                          AppColors.darkBorder,
                                          const Color(0xFF3A3A3A),
                                        ]
                                      : [
                                          const Color(0xFFE5E7EB),
                                          const Color(0xFFD1D5DB),
                                        ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DONUT CHART + LEGEND
  // ═══════════════════════════════════════════════════════════

  Widget _buildDonutSection(
      bool isDark, Map<String, double> stats, double total, String symbol) {
    final sections = stats.entries.map((e) {
      final cat = ExpenseCategory.defaults.firstWhere(
        (c) => c.label == e.key,
        orElse: () => ExpenseCategory.defaults.first,
      );
      final idx = stats.keys.toList().indexOf(e.key);
      final isTouched = _touchedIndex == idx;

      return PieChartSectionData(
        color: cat.color,
        value: e.value,
        radius: isTouched ? 32 : 24,
        showTitle: false,
        borderSide: isTouched
            ? BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 2)
            : BorderSide.none,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 60,
                      sectionsSpace: 4,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            _touchedIndex = response
                                    ?.touchedSection?.touchedSectionIndex ??
                                -1;
                          });
                        },
                      ),
                    ),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  ),
                  // Center label
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$symbol${total.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Legend row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: stats.entries.map((e) {
                final cat = ExpenseCategory.defaults.firstWhere(
                  (c) => c.label == e.key,
                  orElse: () => ExpenseCategory.defaults.first,
                );
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      e.key,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DATA HELPER
  // ═══════════════════════════════════════════════════════════

  Map<String, double> _getStatsByPeriod(ExpenseProvider provider) {
    switch (_selectedPeriod) {
      case TimePeriod.week:
        return provider.categoryTotalsForWeek;
      case TimePeriod.year:
        return provider.categoryTotalsForYear;
      case TimePeriod.month:
      default:
        return provider.categoryTotals;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// HERO STAT CHIP (inside gradient header)
// ═══════════════════════════════════════════════════════════

class _HeroStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeroStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CATEGORY BAR (animated progress bar for each category)
// ═══════════════════════════════════════════════════════════

class _CategoryBar extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String amount;
  final double percentage;
  final bool isDark;
  final bool isHighlighted;

  const _CategoryBar({
    required this.icon,
    required this.color,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.isDark,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted
              ? color.withValues(alpha: isDark ? 0.12 : 0.08)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted
                ? color.withValues(alpha: 0.4)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),

                // Name + pct
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${percentage.toStringAsFixed(1)}% of spending',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  amount,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Animated progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percentage / 100),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color,
                                color.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
