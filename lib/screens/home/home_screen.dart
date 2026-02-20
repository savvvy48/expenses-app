import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/budget_warning_widget.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/transaction_tile.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/settings_provider.dart';
import '../add_expense/add_expense_screen.dart';
import '../settings/budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _balanceVisible = true;
  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expProvider = context.watch<ExpenseProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final symbol = settingsProv.currencySymbol;

    // Filter expenses based on search
    final allExpenses = expProvider.expenses;
    final query = _searchCtrl.text.toLowerCase();
    final expenses = query.isEmpty
        ? allExpenses
        : allExpenses
            .where((e) =>
                e.title.toLowerCase().contains(query) ||
                e.category.label.toLowerCase().contains(query) ||
                e.amount.toString().contains(query))
            .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── Header ───
            SliverToBoxAdapter(
              child: _buildHeader(isDark),
            ),

            // ─── Search Bar (pull-down reveal) ───
            if (_searchOpen)
              SliverToBoxAdapter(
                child: _buildSearchBar(isDark),
              ),

            // ─── Wallet Balance Hero ───
            SliverToBoxAdapter(
              child: _buildWalletCard(isDark, expProvider, symbol),
            ),

            // ─── Smart Quick-Add Categories ───
            SliverToBoxAdapter(
              child: _buildSmartQuickAdd(isDark, expProvider, symbol),
            ),

            // ─── Budget Warning ───
            const SliverToBoxAdapter(
              child: BudgetWarningWidget(),
            ),

            // ─── Insight Card ───
            SliverToBoxAdapter(
              child: _buildInsightCard(isDark, expProvider, symbol),
            ),

            // ─── Transactions Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transactions',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      DateFormat('MMM yyyy').format(DateTime.now()),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Transaction List with Swipe ───
            if (expenses.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: query.isNotEmpty
                      ? EmptyStateWidget(
                          icon: Icons.search_off_rounded,
                          title: 'No results',
                          subtitle: 'Try a different search term',
                        )
                      : const EmptyStateWidget(
                          icon: Icons.receipt_long_outlined,
                          title: 'No transactions yet',
                          subtitle: 'Tap + to add your first expense',
                        ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final expense = expenses[index];
                      final showDateHeader = index == 0 ||
                          !_isSameDay(expenses[index - 1].date, expense.date);

                      return AnimatedListItem(
                        index: index,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showDateHeader)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 12, bottom: 6),
                                child: Text(
                                  _formatDateHeader(expense.date),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            // ─── Swipe: Left=Delete, Right=Edit ───
                            Dismissible(
                              key: ValueKey(expense.id),
                              direction: DismissDirection.horizontal,
                              // Right swipe → Edit (blue)
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 24),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              // Left swipe → Delete (red)
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 24,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                HapticFeedback.mediumImpact();
                                if (direction == DismissDirection.startToEnd) {
                                  // Swipe right → open edit screen (don't dismiss)
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      fullscreenDialog: true,
                                      builder: (_) => AddExpenseScreen(
                                        editExpense: expense,
                                      ),
                                    ),
                                  );
                                  return false; // Don't actually dismiss
                                }
                                // Swipe left → confirm delete
                                return true;
                              },
                              onDismissed: (_) {
                                expProvider.deleteExpense(expense.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${expense.title} deleted',
                                      style: GoogleFonts.inter(),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      textColor: AppColors.primary,
                                      onPressed: () {
                                        expProvider.undoDelete();
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: TransactionTile(
                                expense: expense,
                                isDark: isDark,
                                currencySymbol: symbol,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: expenses.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER (with search toggle)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(bool isDark) {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    if (hour < 12) {
      greeting = 'Good Morning';
      emoji = '☀️';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      emoji = '🌤️';
    } else {
      greeting = 'Good Evening';
      emoji = '🌙';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting $emoji',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Search toggle
              SpringButton(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _searchOpen = !_searchOpen;
                    if (!_searchOpen) {
                      _searchCtrl.clear();
                    }
                  });
                  if (_searchOpen) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _searchFocus.requestFocus();
                    });
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _searchOpen
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : (isDark ? AppColors.darkCard : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _searchOpen
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _searchOpen
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    size: 22,
                    color: _searchOpen
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Notifications
              SpringButton(
                onTap: () => AppToast.info(context, 'No new notifications'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 22,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSearchBar(bool isDark) {
    return AnimatedOpacity(
      opacity: _searchOpen ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              border: InputBorder.none,
              icon: Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WALLET HERO CARD (with trend indicator)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWalletCard(
      bool isDark, ExpenseProvider provider, String symbol) {
    final balance = provider.thisMonthNetBalance;
    final income = provider.thisMonthIncome;
    final expenses = provider.thisMonthTotal;
    final weekChange = provider.weekOverWeekChange;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Balance',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      setState(() => _balanceVisible = !_balanceVisible),
                  child: Icon(
                    _balanceVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ─── Big balance ───
            Text(
              _balanceVisible
                  ? '$symbol ${balance.toStringAsFixed(2)}'
                  : '$symbol ••••',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            // ─── Trend indicator ↑↓ ───
            if (_balanceVisible && weekChange != 0)
              _buildTrendIndicator(weekChange, symbol, provider),
            const SizedBox(height: 20),

            // Income / Expense pills
            Row(
              children: [
                _BalancePill(
                  icon: Icons.trending_up_rounded,
                  label: 'Income',
                  amount: '$symbol${income.toStringAsFixed(0)}',
                  color: AppColors.heroMint,
                ),
                const SizedBox(width: 12),
                _BalancePill(
                  icon: Icons.trending_down_rounded,
                  label: 'Spent',
                  amount: '$symbol${expenses.toStringAsFixed(0)}',
                  color: AppColors.heroPeach,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(
      double weekChange, String symbol, ExpenseProvider provider) {
    final isUp = weekChange > 0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isUp ? AppColors.heroPeach : AppColors.heroMint)
                .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14,
                color: isUp ? AppColors.heroPeach : AppColors.heroMint,
              ),
              const SizedBox(width: 4),
              Text(
                '${weekChange.abs().toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isUp ? AppColors.heroPeach : AppColors.heroMint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isUp ? 'more than last week' : 'less than last week',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SMART QUICK-ADD (auto-learned top categories + generic add)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSmartQuickAdd(
      bool isDark, ExpenseProvider provider, String symbol) {
    final topCats = provider.topCategories;

    // If user has no history, show generic quick actions
    if (topCats.isEmpty) {
      return _buildGenericQuickActions(isDark);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ADD',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Top categories (auto-learned)
              ...topCats.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SpringButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => AddExpenseScreen(
                              preselectedCategory: cat,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cat.color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 18, color: cat.color),
                            const SizedBox(width: 8),
                            Text(
                              cat.label,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cat.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
              const Spacer(),
              // Generic "+" button
              SpringButton(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => const AddExpenseScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.floatingShadow(AppColors.primary),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenericQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QuickAction(
            icon: Icons.add_rounded,
            label: 'Add',
            color: AppColors.primary,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const AddExpenseScreen(),
              ),
            ),
          ),
          _QuickAction(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Analytics',
            color: AppColors.heroMint,
            isDark: isDark,
            onTap: () {},
          ),
          _QuickAction(
            icon: Icons.savings_outlined,
            label: 'Budget',
            color: AppColors.heroCream,
            isDark: isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
          ),
          _QuickAction(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            color: AppColors.heroSky,
            isDark: isDark,
            onTap: () => AppToast.info(context, 'Coming soon'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INSIGHT CARD (contextual, month-over-month)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInsightCard(
      bool isDark, ExpenseProvider provider, String symbol) {
    final monthChange = provider.monthOverMonthChange;
    final thisMonth = provider.thisMonthTotal;
    final lastMonth = provider.lastMonthTotal;

    // Don't show if there's no data to compare
    if (lastMonth == 0 && thisMonth == 0) return const SizedBox.shrink();

    final isSpendingMore = monthChange > 0;
    final changeStr = monthChange.abs().toStringAsFixed(0);
    final diffAmount = (thisMonth - lastMonth).abs();

    String insight;
    IconData insightIcon;
    Color insightColor;

    if (lastMonth == 0) {
      insight = 'First month! You\'ve spent $symbol${thisMonth.toStringAsFixed(0)} so far';
      insightIcon = Icons.celebration_rounded;
      insightColor = AppColors.heroCream;
    } else if (isSpendingMore) {
      insight =
          'You\'re spending $changeStr% more than last month (+$symbol${diffAmount.toStringAsFixed(0)})';
      insightIcon = Icons.trending_up_rounded;
      insightColor = AppColors.error;
    } else {
      insight =
          'Great! You\'re spending $changeStr% less than last month (-$symbol${diffAmount.toStringAsFixed(0)})';
      insightIcon = Icons.trending_down_rounded;
      insightColor = AppColors.success;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: insightColor.withValues(alpha: isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: insightColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: insightColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(insightIcon, size: 18, color: insightColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                insight,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'TODAY';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'YESTERDAY';
    }
    return DateFormat('MMM dd, yyyy').format(date).toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════
// BALANCE PILL (inside gradient card)
// ═══════════════════════════════════════════════════════════════

class _BalancePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _BalancePill({
    required this.icon,
    required this.label,
    required this.amount,
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
                amount,
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

// ═══════════════════════════════════════════════════════════════
// QUICK ACTION (generic fallback)
// ═══════════════════════════════════════════════════════════════

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpringButton(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.12 : 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
