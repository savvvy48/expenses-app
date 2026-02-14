import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/count_up_text.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/utils/app_feedback.dart';
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
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    AppFeedback.onSelection();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _enterSelectionMode(String id) {
    AppFeedback.onSelection();
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }
  
  void _deleteSelected() {
    final count = _selectedIds.length;
    if (count == 0) return;
    
    AppFeedback.onDelete();
    final provider = context.read<ExpenseProvider>();
    final idsToDelete = _selectedIds.toList();
    
    provider.deleteExpenses(idsToDelete);
    _exitSelectionMode();
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count transactions deleted'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () {
            AppFeedback.onTap();
            provider.undoDelete();
          },
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // Header with Net Balance
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
                            Text('Net Balance',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.textTheme.bodySmall?.color)),
                            const SizedBox(height: 4),
                            CountUpText(
                              end: expProvider.netBalance,
                              prefix: '\$',
                              decimals: 2,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 32,
                                  color: expProvider.netBalance >= 0 
                                    ? AppColors.success 
                                    : AppColors.error),
                            ),
                          ],
                        ),
                      ),
                      SpringButton(
                        semanticLabel: 'Filter expenses',
                        onTap: () =>
                            _showFilterSheet(context, expProvider),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: expProvider.hasActiveFilters
                                  ? AppColors.primary
                                  : isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                            ),
                            color: expProvider.hasActiveFilters
                                ? AppColors.primary.withValues(alpha: 0.1)
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
                      const SizedBox(width: 8),
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
            
            // ... Search Bar (Unchanged) ...
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
                            // Filter button moved to header
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            
            // Sort Options
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text('Sort:', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 8),
                    ...[
                      (label: 'Date ↓', opt: SortOption.dateNewest),
                      (label: 'Date ↑', opt: SortOption.dateOldest),
                      (label: 'Amt ↓', opt: SortOption.amountHighLow),
                      (label: 'Amt ↑', opt: SortOption.amountLowHigh),
                      (label: 'Cat', opt: SortOption.categoryAZ),
                    ].map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(e.label),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: expProvider.currentSort == e.opt
                                  ? Colors.white
                                  : isDark
                                      ? Colors.white
                                      : Colors.black,
                            ),
                            selected: expProvider.currentSort == e.opt,
                            selectedColor: AppColors.primary,
                            backgroundColor: isDark
                                ? AppColors.darkCard
                                : AppColors.lightCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: expProvider.currentSort == e.opt
                                    ? Colors.transparent
                                    : isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                              ),
                            ),
                            onSelected: (_) {
                              AppFeedback.onSelection();
                              expProvider.setSortOption(e.opt);
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ),
            // Income vs Expense Row (Replaces Budget Card temporarily or complements it)
            // For now, let's keep budget card but maybe shrink it or move it? 
            // The plan said "Update HomeScreen to show income vs expense breakdown"
            // Let's replace the large budget card with a summary row of Income | Expense
            SliverToBoxAdapter(
              child: AnimatedListItem(
                index: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_downward, size: 16, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text('Income', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CountUpText(
                                end: expProvider.totalIncome,
                                prefix: '+\$',
                                decimals: 2,
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.arrow_upward, size: 16, color: AppColors.error),
                                  const SizedBox(width: 4),
                                  Text('Expense', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CountUpText(
                                end: expProvider.totalSpent,
                                prefix: '-\$',
                                decimals: 2,
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Budget Summary (Condensed)
            SliverToBoxAdapter(
              child: AnimatedListItem(
                index: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Monthly Budget', style: theme.textTheme.titleSmall),
                            Text('${(monthlyUtilization * 100).toInt()}% Used', 
                              style: TextStyle(fontWeight: FontWeight.bold, color: budgetProvider.budgetColor(monthlyUtilization))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: monthlyUtilization.clamp(0.0, 1.0),
                            backgroundColor: isDark ? Colors.black26 : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(budgetProvider.budgetColor(monthlyUtilization)),
                            minHeight: 8,
                          ),
                        ),
                        if (monthlyUtilization >= 0.9)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlyUtilization >= 1 ? 'Budget Exceeded!' : 'Approaching Limit',
                              style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
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
                      child: const EmptyStateWidget(
                        title: 'No expenses yet',
                        subtitle: 'Tap + to add your first expense',
                        icon: Icons.receipt_long,
                      ),
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
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedIds.contains(expense.id),
                              onDelete: () => _deleteExpense(context, expense),
                              onTap: () {
                                if (_isSelectionMode) {
                                  _toggleSelection(expense.id);
                                } else {
                                  _viewExpense(context, expense);
                                }
                              },
                              onLongPress: () => _enterSelectionMode(expense.id),
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
    ),
    floatingActionButton: _isSelectionMode
          ? null
          : Semantics(
              label: 'Add new expense',
              button: true,
              child: FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AddExpenseScreen()),
              ),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
      bottomNavigationBar: _isSelectionMode
          ? BottomAppBar(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _exitSelectionMode,
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    Text('${_selectedIds.length} selected',
                        style: theme.textTheme.titleMedium),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Selected?'),
                            content: Text(
                                'Are you sure you want to delete ${_selectedIds.length} transaction(s)?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _deleteSelected();
                                  },
                                  child: const Text('Delete',
                                      style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        );
                      },
                      child: const Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            )
          : null,
  );
}

  void _deleteExpense(BuildContext context, Expense expense) {
    
    // Optimistic remove from UI is handled by Dismissible, but we need to tell provider
    // However, provider.deleteExpense() removes it from the list. 
    // If we want to support undo, we should keep a reference or rely on provider's undo.
    
    context.read<ExpenseProvider>().deleteExpense(expense.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${expense.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () {
            AppFeedback.onTap();
            context.read<ExpenseProvider>().undoDelete();
          },
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

// ... (AnimatedFractionallySizedBox removed as it's no longer used in the main view, or keep if needed elsewhere) ...

// --- Quick Stat with CountUp (Removed as replaced by Income/Expense summary) ---

// --- Swipeable Transaction Tile (Swipe to Delete) ---
class _SwipeableTransactionTile extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  final ThemeData theme;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SwipeableTransactionTile({
    required this.expense,
    required this.isDark,
    required this.theme,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onDelete,
    required this.onTap,
    required this.onLongPress,
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
    final isIncome = expense.isIncome;
    final amountColor = isIncome ? AppColors.success : AppColors.error;
    final prefix = isIncome ? '+\$' : '-\$';

    if (isSelectionMode) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : (isDark ? AppColors.darkCard : AppColors.lightCard),
            border: _getBorder(),
          ),
          child: Row(
            children: [
              // Checkbox Overlay
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : Icon(expense.category.icon,
                        color: expense.category.color.withValues(alpha: 0.5), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildContent(amountColor, prefix)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(expense.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          AppFeedback.onSelection();
          return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Expense?'),
              content: Text('Are you sure you want to delete "${expense.title}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Delete',
                        style: TextStyle(color: AppColors.error))),
              ],
            ),
          );
        },
        onDismissed: (_) {
          AppFeedback.heavyImpact();
          onDelete();
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: AppColors.error,
          child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: _buildTileContent(amountColor, prefix),
        ),
      ),
    );
  }

  BoxBorder _getBorder() {
    if (isSelected) return Border.all(color: AppColors.primary, width: 2);
    return Border(
      top: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      bottom: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      right: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      left: expense.isRecurring
          ? const BorderSide(color: AppColors.housing, width: 4)
          : BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
    );
  }

  Widget _buildTileContent(Color amountColor, String prefix) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: _getBorder(),
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
          Expanded(child: _buildContent(amountColor, prefix)),
        ],
      ),
    );
  }

  Widget _buildContent(Color amountColor, String prefix) {
    return Row(
      children: [
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
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.repeat,
                          size: 16, color: AppColors.housing),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: expense.category.color.withValues(alpha: 0.1),
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
            Text('$prefix${expense.amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(expense.paymentMethod.icon,
                    size: 16,
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
    );
  }
}

// --- Empty State replaced by shared widget ---

// --- Expense Detail Sheet ---
class _ExpenseDetailSheet extends StatelessWidget {
  final Expense expense;
  const _ExpenseDetailSheet({required this.expense});

  void _shareExpense(BuildContext context) {
    final date = DateFormat.yMMMMEEEEd().format(expense.date);
    final text = 'Expense Details:\n\n'
        'Title: ${expense.title}\n'
        'Amount: \$${expense.amount.toStringAsFixed(2)}\n'
        'Category: ${expense.category.label}\n'
        'Date: $date\n'
        'Payment: ${expense.paymentMethod.label}\n'
        '${expense.notes != null ? 'Notes: ${expense.notes}\n' : ''}';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            onPressed: () => _shareExpense(context),
            icon: const Icon(Icons.share),
          ),
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
                  isSelected: !provider.hasActiveFilters,
                  onTap: () {
                    AppFeedback.onSelection();
                    provider.clearFilters();
                    Navigator.pop(context);
                  },
                  isDark: isDark),
              ...provider.allCategories.map((cat) => _FilterChip(
                    label: cat.label,
                    isSelected: provider.filterCategoryId == cat.id,
                    color: cat.color,
                    onTap: () {
                      AppFeedback.onSelection();
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
                      isSelected: provider.filterPaymentMethod == m,
                      onTap: () {
                        AppFeedback.onSelection();
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
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isSelected,
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
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : isDark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : color ??
                    (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : color,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}
