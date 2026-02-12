import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/shake_widget.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/widgets/success_overlay.dart';
import '../../core/widgets/toast.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/people_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? editExpense;
  const AddExpenseScreen({super.key, this.editExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  final _shakeKey = GlobalKey<ShakeWidgetState>();

  // Form state
  bool _isIncome = false;
  String _selectedCategoryId = ExpenseCategory.defaults.first.id;
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  String _currency = 'USD';
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  RecurringType _recurringType = RecurringType.monthly;
  final List<ExpenseSplit> _splits = [];
  bool _isEditing = false;

  // Animation
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerScale;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.editExpense != null;
    _titleCtrl = TextEditingController(text: widget.editExpense?.title ?? '');
    _amountCtrl = TextEditingController(
        text: widget.editExpense != null
            ? widget.editExpense!.amount.toString()
            : '');
    _notesCtrl = TextEditingController(text: widget.editExpense?.notes ?? '');

    if (_isEditing) {
      _isIncome = widget.editExpense!.isIncome;
      _selectedCategoryId = widget.editExpense!.category.id;
      _selectedPayment = widget.editExpense!.paymentMethod;
      _currency = widget.editExpense!.currency;
      _selectedDate = widget.editExpense!.date;
      _isRecurring = widget.editExpense!.isRecurring;
      _recurringType = widget.editExpense!.recurringType;
      _splits.addAll(widget.editExpense!.splits);
    }

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerScale = CurvedAnimation(parent: _headerCtrl, curve: Curves.elasticOut);
    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor =>
      _isIncome ? AppColors.success : AppColors.primary;

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());

    if (title.isEmpty || amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      _shakeKey.currentState?.shake();
      AppToast.error(context, 'Please fill in title and valid amount');
      return;
    }

    final provider = context.read<ExpenseProvider>();
    final cat = provider.allCategories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => ExpenseCategory.defaults.first);

    final expense = Expense(
      id: _isEditing ? widget.editExpense!.id : const Uuid().v4(),
      title: title,
      amount: amount,
      date: _selectedDate,
      category: cat,
      paymentMethod: _selectedPayment,
      currency: _currency,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isRecurring: _isRecurring,
      recurringType: _recurringType,
      splits: List.from(_splits),
      isIncome: _isIncome,
    );

    if (_isEditing) {
      provider.updateExpense(expense);
    } else {
      provider.addExpense(expense);
    }

    HapticFeedback.mediumImpact();
    SuccessOverlay.show(context,
        message: _isEditing
            ? 'Updated!'
            : _isIncome
                ? 'Income Added!'
                : 'Expense Added!');
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    final peopleProv = context.watch<PeopleProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Custom Header ───
          SliverToBoxAdapter(
            child: ScaleTransition(
              scale: _headerScale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.3),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    child: Column(
                      children: [
                        // Top bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SpringButton(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                color: Colors.white.withValues(alpha: 0.15),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                            Text(
                              _isEditing
                                  ? 'Edit Transaction'
                                  : 'New Transaction',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ─── Expense / Income Toggle ───
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          child: Row(
                            children: [
                              _TypeToggleTab(
                                label: 'Expense',
                                icon: Icons.arrow_upward,
                                isSelected: !_isIncome,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isIncome = false);
                                },
                              ),
                              _TypeToggleTab(
                                label: 'Income',
                                icon: Icons.arrow_downward,
                                isSelected: _isIncome,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isIncome = true);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ─── Amount Display ───
                        Text(
                          _isIncome ? 'Amount Received' : 'Amount Spent',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SpringButton(
                              onTap: () => _selectCurrency(context, isDark),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                color: Colors.white.withValues(alpha: 0.15),
                                child: Text(_currency,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IntrinsicWidth(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(minWidth: 80, maxWidth: 200),
                                child: TextField(
                                  controller: _amountCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Form Body ───
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 4),

                // ─── Title + Date Row ───
                AnimatedListItem(
                  index: 0,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ShakeWidget(
                          key: _shakeKey,
                          child: _FormSection(
                            isDark: isDark,
                            child: TextField(
                              controller: _titleCtrl,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: _isIncome
                                    ? 'Income source...'
                                    : 'What did you spend on?',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: isDark
                                        ? AppColors.darkTextTertiary
                                        : AppColors.lightTextTertiary,
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                    minWidth: 0, minHeight: 0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: SpringButton(
                          onTap: () => _pickDate(context),
                          child: _FormSection(
                            isDark: isDark,
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: _accentColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('MMM d, y').format(_selectedDate),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Category ───
                AnimatedListItem(
                  index: 1,
                  child: _FormSection(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category_outlined,
                                size: 16, color: _accentColor),
                            const SizedBox(width: 8),
                            Text('Category',
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              provider.allCategories.map((cat) {
                            final sel = cat.id == _selectedCategoryId;
                            return SpringButton(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategoryId = cat.id);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? cat.color.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  border: Border.all(
                                      color: sel
                                          ? cat.color
                                          : isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder,
                                      width: sel ? 2 : 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      color: cat.color
                                          .withValues(alpha: sel ? 0.2 : 0.1),
                                      child:
                                          Icon(cat.icon, size: 14, color: cat.color),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(cat.label,
                                        style: TextStyle(
                                            color: sel ? cat.color : null,
                                            fontSize: 12,
                                            fontWeight: sel
                                                ? FontWeight.w700
                                                : FontWeight.w500)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Payment Method ───
                AnimatedListItem(
                  index: 2,
                  child: _FormSection(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined,
                                size: 16, color: _accentColor),
                            const SizedBox(width: 8),
                            Text('Payment Method',
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: PaymentMethod.values.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (ctx, i) {
                              final m = PaymentMethod.values[i];
                              final sel = m == _selectedPayment;
                              return SpringButton(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedPayment = m);
                                },
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? _accentColor.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    border: Border.all(
                                        color: sel
                                            ? _accentColor
                                            : isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder,
                                        width: sel ? 2 : 1),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                            milliseconds: 200),
                                        width: 32,
                                        height: 32,
                                        color: sel
                                            ? _accentColor
                                                .withValues(alpha: 0.15)
                                            : (isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.lightBorder)
                                                .withValues(alpha: 0.4),
                                        child: Icon(m.icon,
                                            size: 16,
                                            color: sel
                                                ? _accentColor
                                                : isDark
                                                    ? AppColors
                                                        .darkTextSecondary
                                                    : AppColors
                                                        .lightTextSecondary),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(m.label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: sel
                                                  ? _accentColor
                                                  : null,
                                              fontSize: 10,
                                              fontWeight: sel
                                                  ? FontWeight.w700
                                                  : FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Notes ───
                AnimatedListItem(
                  index: 3,
                  child: _FormSection(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 16, color: _accentColor),
                            const SizedBox(width: 8),
                            Text('Notes',
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          style: theme.textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            hintText: 'Add a note... (optional)',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Recurring Toggle ───
                AnimatedListItem(
                  index: 4,
                  child: _FormSection(
                    isDark: isDark,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Container(
                                width: 32,
                                height: 32,
                                color: AppColors.housing.withValues(alpha: 0.12),
                                child: const Icon(Icons.repeat,
                                    color: AppColors.housing, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Text('Recurring',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                            ]),
                            Switch.adaptive(
                              value: _isRecurring,
                              activeTrackColor: _accentColor,
                              onChanged: (v) {
                                HapticFeedback.selectionClick();
                                setState(() => _isRecurring = v);
                              },
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: _isRecurring
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    children: RecurringType.values.map((t) {
                                      final sel = t == _recurringType;
                                      return Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: SpringButton(
                                            onTap: () => setState(
                                                () => _recurringType = t),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: sel
                                                    ? _accentColor
                                                    : Colors.transparent,
                                                border: Border.all(
                                                    color: sel
                                                        ? _accentColor
                                                        : isDark
                                                            ? AppColors
                                                                .darkBorder
                                                            : AppColors
                                                                .lightBorder),
                                              ),
                                              child: Center(
                                                child: Text(t.label,
                                                    style: TextStyle(
                                                        color: sel
                                                            ? Colors.white
                                                            : null,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ─── Split with People (only for expenses) ───
                if (!_isIncome)
                  AnimatedListItem(
                    index: 5,
                    child: _FormSection(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  color:
                                      AppColors.transport.withValues(alpha: 0.12),
                                  child: const Icon(Icons.people_outline,
                                      color: AppColors.transport, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Text('Split Expense',
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600)),
                              ]),
                              if (peopleProv.activeMembers.isNotEmpty)
                                SpringButton(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _showSplitModal(
                                        context, peopleProv, isDark);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: _accentColor, width: 1.5),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add,
                                            size: 14, color: _accentColor),
                                        const SizedBox(width: 4),
                                        Text('Add',
                                            style: TextStyle(
                                                color: _accentColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_splits.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ..._splits.asMap().entries.map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkBg
                                          : AppColors.lightBg,
                                      border: Border.all(
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder),
                                    ),
                                    child: Row(children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        color: _accentColor,
                                        child: Center(
                                          child: Text(
                                              e.value.personName[0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Text(e.value.personName,
                                              style: theme.textTheme.bodyMedium)),
                                      Text(
                                          '\$${e.value.amount.toStringAsFixed(2)}',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _splits.removeAt(e.key)),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          color:
                                              AppColors.error.withValues(alpha: 0.1),
                                          child: const Icon(Icons.close,
                                              size: 14, color: AppColors.error),
                                        ),
                                      ),
                                    ]),
                                  ),
                                )),
                          ] else if (peopleProv.activeMembers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Add people first to split expenses',
                                  style: theme.textTheme.bodySmall),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 28),

                // ─── Action Buttons ───
                AnimatedListItem(
                  index: 6,
                  child: Row(children: [
                    Expanded(
                      child: SpringButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text('Cancel',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SpringButton(
                        onTap: _save,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 54,
                          color: _accentColor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isIncome
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isEditing
                                    ? 'Update'
                                    : _isIncome
                                        ? 'Add Income'
                                        : 'Add Expense',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _selectCurrency(BuildContext context, bool isDark) {
    final currencies = [
      ('USD', '\$', 'US Dollar'),
      ('EUR', '€', 'Euro'),
      ('GBP', '£', 'British Pound'),
      ('INR', '₹', 'Indian Rupee'),
      ('JPY', '¥', 'Japanese Yen'),
      ('CAD', 'C\$', 'Canadian Dollar'),
      ('AUD', 'A\$', 'Australian Dollar'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.85)
                    : AppColors.lightSurface.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  const SizedBox(height: 16),
                  Text('Select Currency',
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...currencies.map((c) {
                    final sel = c.$1 == _currency;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SpringButton(
                        onTap: () {
                          setState(() => _currency = c.$1);
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel
                                ? _accentColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            border: Border.all(
                                color: sel
                                    ? _accentColor
                                    : isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                width: sel ? 2 : 1),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              color: sel
                                  ? _accentColor.withValues(alpha: 0.15)
                                  : (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder)
                                      .withValues(alpha: 0.5),
                              child: Center(
                                child: Text(c.$2,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: sel ? _accentColor : null,
                                        fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.$1,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: sel ? _accentColor : null)),
                                  Text(c.$3,
                                      style: Theme.of(ctx).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            if (sel)
                              Icon(Icons.check, color: _accentColor, size: 20),
                          ]),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSplitModal(
      BuildContext context, PeopleProvider peopleProv, bool isDark) {
    final members = peopleProv.activeMembers;
    final amtCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.85)
                    : AppColors.lightSurface.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  const SizedBox(height: 16),
                  Text('Split with', style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: amtCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                          hintText: 'Split amount', prefixText: '\$ '),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...members.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SpringButton(
                          onTap: () {
                            final amt = double.tryParse(amtCtrl.text.trim());
                            if (amt != null && amt > 0) {
                              setState(() => _splits.add(ExpenseSplit(
                                  personId: p.id,
                                  personName: p.name,
                                  amount: amt)));
                              Navigator.pop(ctx);
                            } else {
                              AppToast.error(ctx, 'Enter a valid amount first');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                            ),
                            child: Row(children: [
                              Container(
                                width: 32,
                                height: 32,
                                color: p.avatarColor,
                                child: Center(
                                  child: Text(p.initials,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(p.name,
                                  style: Theme.of(ctx).textTheme.bodyLarge)),
                              Icon(Icons.chevron_right,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.darkTextTertiary
                                      : AppColors.lightTextTertiary),
                            ]),
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Expense/Income Toggle Tab ───
class _TypeToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeToggleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SpringButton(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: Colors.white
                      .withValues(alpha: isSelected ? 1.0 : 0.5)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: Colors.white
                          .withValues(alpha: isSelected ? 1.0 : 0.5),
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Form Section Container ───
class _FormSection extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _FormSection({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: child,
    );
  }
}
