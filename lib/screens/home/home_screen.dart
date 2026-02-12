import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/count_up_text.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/widgets/toast.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../add_expense/add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final expenses = expProvider.expenses;
    final monthlyUtilization =
        budgetProvider.monthlyUtilization(expProvider.thisMonthTotal);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: AnimatedListItem(
                index: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Expenses',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800, fontSize: 28)),
                            const SizedBox(height: 4),
                            CountUpText(
                              end: expProvider.thisMonthTotal,
                              prefix: 'Total: \$',
                              decimals: 2,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      SpringButton(
                        onTap: () => setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchController.clear();
                            expProvider.setSearch('');
                          }
                        }),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                            color:
                                isDark ? AppColors.darkCard : AppColors.lightCard,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _showSearch ? Icons.close : Icons.search,
                              key: ValueKey(_showSearch),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Animated search bar
            SliverToBoxAdapter(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _showSearch
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: expProvider.setSearch,
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: 'Search expenses...',
                                    prefixIcon:
                                        const Icon(Icons.search, size: 20),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide: BorderSide(width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SpringButton(
                              onTap: () =>
                                  _showFilterSheet(context, expProvider),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: expProvider.hasActiveFilters
                                        ? AppColors.primary
                                        : isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder,
                                    width: 2,
                                  ),
                                  color: expProvider.hasActiveFilters
                                      ? AppColors.primary
                                          .withValues(alpha: 0.1)
                                      : isDark
                                          ? AppColors.darkCard
                                          : AppColors.lightCard,
                                ),
                                child: Icon(Icons.tune,
                                    size: 20,
                                    color: expProvider.hasActiveFilters
                                        ? AppColors.primary
                                        : null),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // Budget card with animated progress bar
            SliverToBoxAdapter(
              child: AnimatedListItem(
                index: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      boxShadow: AppColors.sharpShadow(isDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('This Month',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              color: Colors.white.withValues(alpha: 0.15),
                              child: Text(
                                DateFormat('MMMM y').format(DateTime.now()),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CountUpText(
                          end: expProvider.thisMonthTotal,
                          prefix: '\$',
                          decimals: 2,
                          duration: const Duration(milliseconds: 1200),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Budget used',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          fontSize: 11)),
                                  const SizedBox(height: 6),
                                  // Animated progress bar
                                  Container(
                                    height: 6,
                                    color:
                                        Colors.white.withValues(alpha: 0.15),
                                    child: AnimatedFractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor:
                                          monthlyUtilization.clamp(0.0, 1.0),
                                      duration:
                                          const Duration(milliseconds: 800),
                                      curve: Curves.easeOutCubic,
                                      child: Container(
                                        color: budgetProvider
                                            .budgetColor(monthlyUtilization),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                  begin: 0,
                                  end: monthlyUtilization * 100),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (ctx, val, _) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                color: budgetProvider
                                    .budgetColor(monthlyUtilization)
                                    .withValues(alpha: 0.2),
                                child: Text(
                                  '${val.toInt()}%',
                                  style: TextStyle(
                                      color: budgetProvider
                                          .budgetColor(monthlyUtilization),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (monthlyUtilization >= 0.8) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            color: budgetProvider
                                .budgetColor(monthlyUtilization)
                                .withValues(alpha: 0.15),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    monthlyUtilization >= 1
                                        ? Icons.warning
                                        : Icons.info_outline,
                                    color: budgetProvider
                                        .budgetColor(monthlyUtilization),
                                    size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  monthlyUtilization >= 1
                                      ? 'Over budget!'
                                      : 'Approaching budget limit',
                                  style: TextStyle(
                                      color: budgetProvider
                                          .budgetColor(monthlyUtilization),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Quick Stats Row
            SliverToBoxAdapter(
              child: AnimatedListItem(
                index: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                          child: _QuickStat(
                        icon: Icons.today,
                        label: 'Today',
                        value: expProvider.todayTotal,
                        isDark: isDark,
                        theme: theme,
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _QuickStat(
                        icon: Icons.repeat,
                        label: 'Recurring',
                        value: expProvider.recurringCount.toDouble(),
                        isDark: isDark,
                        theme: theme,
                        isInt: true,
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _QuickStat(
                        icon: Icons.receipt_long,
                        label: 'Total',
                        value: expenses.length.toDouble(),
                        isDark: isDark,
                        theme: theme,
                        isInt: true,
                      )),
                    ],
                  ),
                ),
              ),
            ),

            // Recent Activity Header
            SliverToBoxAdapter(
              child: AnimatedListItem(
                index: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Activity',
                          style: theme.textTheme.titleMedium),
                      if (expProvider.hasActiveFilters)
                        SpringButton(
                          onTap: expProvider.clearFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: const Text('Clear Filters',
                                style: TextStyle(
                                    color: AppColors.primary, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Transaction List — with swipe-to-delete and scroll reveal
            expenses.isEmpty
                ? SliverToBoxAdapter(
                    child: AnimatedListItem(
                      index: 4,
                      child: _EmptyState(isDark: isDark, theme: theme),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final expense = expenses[index];
                          return AnimatedListItem(
                            index: index,
                            delay: const Duration(milliseconds: 40),
                            child: _SwipeableTransactionTile(
                              expense: expense,
                              isDark: isDark,
                              theme: theme,
                              onDelete: () =>
                                  _deleteExpense(context, expense),
                              onTap: () => _viewExpense(context, expense),
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

  void _deleteExpense(BuildContext context, Expense expense) {
    HapticFeedback.heavyImpact();
    context.read<ExpenseProvider>().deleteExpense(expense.id);
    AppToast.success(context, '${expense.title} deleted');
  }

  void _viewExpense(BuildContext context, Expense expense) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, a, _) =>
            _ExpenseDetailSheet(expense: expense),
        transitionsBuilder: (context, a, _, child) =>
            SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(provider: provider),
    );
  }
}

// --- Animated Fractionaly Sized Box ---
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final AlignmentGeometry alignment;
  final double widthFactor;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.alignment,
    required this.widthFactor,
    required this.child,
    required super.duration,
    super.curve,
  });

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFSBState();
}

class _AnimatedFSBState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(_widthFactor, widget.widthFactor,
        (dynamic value) => Tween<double>(begin: value as double)) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: widget.alignment,
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      child: widget.child,
    );
  }
}

// --- Quick Stat with CountUp ---
class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final bool isDark;
  final ThemeData theme;
  final bool isInt;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.theme,
    this.isInt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: AppColors.subtleShadow(isDark),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          CountUpText(
            end: value,
            prefix: isInt ? '' : '\$',
            decimals: isInt ? 0 : 0,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// --- Swipeable Transaction Tile (Swipe to Delete) ---
class _SwipeableTransactionTile extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SwipeableTransactionTile({
    required this.expense,
    required this.isDark,
    required this.theme,
    required this.onDelete,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(expense.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: AppColors.error,
          child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  color: expense.category.color.withValues(alpha: 0.12),
                  child: Icon(expense.category.icon,
                      color: expense.category.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(expense.title,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontSize: 14)),
                          ),
                          if (expense.isRecurring)
                            const Icon(Icons.repeat,
                                size: 14, color: AppColors.housing),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            color:
                                expense.category.color.withValues(alpha: 0.1),
                            child: Text(expense.category.label,
                                style: TextStyle(
                                    color: expense.category.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Text(_formatDate(expense.date),
                              style: theme.textTheme.bodySmall),
                          if (expense.splits.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: const Text('Split',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('-\$${expense.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(expense.paymentMethod.icon,
                            size: 12,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary),
                        const SizedBox(width: 3),
                        Text(expense.paymentMethod.label,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Empty State with Animated Icon ---
class _EmptyState extends StatefulWidget {
  final bool isDark;
  final ThemeData theme;
  const _EmptyState({required this.isDark, required this.theme});
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (ctx, child) {
                return Transform.translate(
                  offset: Offset(0, -8 * _ctrl.value),
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                color: widget.isDark
                    ? AppColors.darkCard
                    : AppColors.lightBorder,
                child: Icon(Icons.receipt_long,
                    size: 40,
                    color: widget.isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
              ),
            ),
            const SizedBox(height: 16),
            Text('No expenses yet',
                style: widget.theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap the + button to add your first expense',
                style: widget.theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// --- Expense Detail Sheet ---
class _ExpenseDetailSheet extends StatelessWidget {
  final Expense expense;
  const _ExpenseDetailSheet({required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AddExpenseScreen(editExpense: expense),
              ));
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  AnimatedListItem(
                    index: 0,
                    child: Container(
                      width: 64,
                      height: 64,
                      color: expense.category.color.withValues(alpha: 0.15),
                      child: Icon(expense.category.icon,
                          color: expense.category.color, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedListItem(
                    index: 1,
                    child: Text(expense.title,
                        style: theme.textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 8),
                  AnimatedListItem(
                    index: 2,
                    child: CountUpText(
                      end: expense.amount,
                      prefix: '-\$',
                      decimals: 2,
                      style: theme.textTheme.headlineLarge?.copyWith(
                          color: AppColors.error,
                          fontSize: 36,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...[
              _DetailRow('Category', expense.category.label,
                  expense.category.icon, expense.category.color, isDark, theme),
              _DetailRow(
                  'Date',
                  DateFormat('EEEE, MMM d, y').format(expense.date),
                  Icons.calendar_today,
                  AppColors.primary,
                  isDark,
                  theme),
              _DetailRow('Payment', expense.paymentMethod.label,
                  expense.paymentMethod.icon, AppColors.transport, isDark, theme),
              if (expense.isRecurring)
                _DetailRow('Recurring', expense.recurringType.label,
                    Icons.repeat, AppColors.housing, isDark, theme),
              if (expense.notes != null && expense.notes!.isNotEmpty)
                _DetailRow('Notes', expense.notes!, Icons.note,
                    AppColors.fun, isDark, theme),
            ].asMap().entries.map((e) => AnimatedListItem(
                  index: e.key + 3,
                  child: e.value,
                )),
            if (expense.splits.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Split Between', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...expense.splits.asMap().entries.map((e) => AnimatedListItem(
                    index: e.key + 6,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.darkCard : AppColors.lightCard,
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            color: AppColors.primary,
                            child: Center(
                              child: Text(e.value.personName[0],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(e.value.personName,
                                  style: theme.textTheme.bodyLarge)),
                          Text('\$${e.value.amount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final ThemeData theme;

  const _DetailRow(
      this.label, this.value, this.icon, this.color, this.isDark, this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            color: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(value,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Filter Sheet ---
class _FilterSheet extends StatelessWidget {
  final ExpenseProvider provider;
  const _FilterSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          const SizedBox(height: 20),
          Text('Filter by Category', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                  label: 'All',
                  selected: provider.searchQuery.isEmpty,
                  onTap: () {
                    provider.setFilterCategory(null);
                    Navigator.pop(context);
                  },
                  isDark: isDark),
              ...ExpenseCategory.defaults.map((cat) => _FilterChip(
                    label: cat.label,
                    selected: false,
                    color: cat.color,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      provider.setFilterCategory(cat.id);
                      Navigator.pop(context);
                    },
                    isDark: isDark,
                  )),
            ],
          ),
          const SizedBox(height: 24),
          Text('Filter by Payment', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PaymentMethod.values
                .map((m) => _FilterChip(
                      label: m.label,
                      selected: false,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider.setFilterPaymentMethod(m);
                        Navigator.pop(context);
                      },
                      isDark: isDark,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SpringButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : isDark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
          border: Border.all(
            color: selected
                ? AppColors.primary
                : color ??
                    (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? AppColors.primary : color,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}
