import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/expense.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/widgets/success_overlay.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/toast.dart';
import '../../providers/expense_provider.dart';
import '../../providers/people_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/settings_provider.dart';
import '../templates/templates_screen.dart';
import '../../core/utils/nlp_parser.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? editExpense;
  final Expense? template;
  final ExpenseCategory? preselectedCategory;
  const AddExpenseScreen({super.key, this.editExpense, this.template, this.preselectedCategory});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;

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
  final List<String> _receiptPaths = [];
  bool _isTemplate = false;

  // Amount via custom keypad
  String _amountText = '';

  // Expanded sections
  bool _showExtras = false;
  bool _nlpMode = false;
  final _nlpCtrl = TextEditingController();

  // Animation
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    final initialData = widget.editExpense ?? widget.template;
    _isEditing = widget.editExpense != null;

    _titleCtrl = TextEditingController(text: initialData?.title ?? '');
    _notesCtrl = TextEditingController(text: initialData?.notes ?? '');

    if (initialData != null) {
      _isIncome = initialData.isIncome;
      _selectedCategoryId = initialData.category.id;
      _selectedPayment = initialData.paymentMethod;
      _currency = initialData.currency;
      _selectedDate = widget.editExpense != null ? initialData.date : DateTime.now();
      _isRecurring = initialData.isRecurring;
      _recurringType = initialData.recurringType;
      _splits.addAll(initialData.splits);
      _receiptPaths.addAll(initialData.receiptPaths);
      _isTemplate = widget.editExpense != null ? initialData.isTemplate : false;
      _amountText = initialData.amount.toStringAsFixed(
          initialData.amount == initialData.amount.roundToDouble() ? 0 : 2);
    } else {
      _currency = context.read<SettingsProvider>().currencyCode;
      if (widget.preselectedCategory != null) {
        _selectedCategoryId = widget.preselectedCategory!.id;
      }
    }

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _nlpCtrl.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  // ─── Amount formatting ───
  String get _formattedAmount {
    if (_amountText.isEmpty) return '0.00';
    final val = double.tryParse(_amountText);
    if (val == null) return _amountText;
    if (_amountText.contains('.')) return _amountText;
    return _amountText;
  }

  String get _currencySymbol => SettingsProvider.getSymbolForCode(_currency);

  Color get _accentBg => _isIncome ? AppColors.heroLavender : AppColors.heroMint;

  void _handleNLPInput(String input) {
    final parsed = NLPExpenseParser.parse(input);
    if (parsed == null) {
      AppToast.error(context, 'Couldn\'t parse — try "Spent 200 on food"');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _amountText = parsed.amount.toStringAsFixed(
          parsed.amount == parsed.amount.roundToDouble() ? 0 : 2);
      if (parsed.title != null && parsed.title!.isNotEmpty) {
        _titleCtrl.text = parsed.title!;
      }
      if (parsed.category != null) {
        _selectedCategoryId = parsed.category!.id;
      }
      _nlpMode = false;
      _nlpCtrl.clear();
    });

    AppToast.success(context, 'Parsed! ${_currencySymbol}${parsed.amount.toStringAsFixed(0)} for ${parsed.title ?? "expense"}');
  }

  void _onKeyTap(String key) {
    AppHaptics.onTap();
    setState(() {
      if (key == '⌫') {
        if (_amountText.isNotEmpty) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        }
      } else if (key == '.') {
        if (!_amountText.contains('.') && _amountText.length < 10) {
          _amountText = _amountText.isEmpty ? '0.' : '$_amountText.';
        }
      } else {
        // Limit decimal places to 2
        if (_amountText.contains('.')) {
          final parts = _amountText.split('.');
          if (parts.length > 1 && parts[1].length >= 2) return;
        }
        if (_amountText.length < 12) {
          _amountText += key;
        }
      }
    });
  }

  Future<void> _pickImage() async {
    AppHaptics.onSelection();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = '${const Uuid().v4()}_${path.basename(pickedFile.path)}';
        final savedImage =
            await File(pickedFile.path).copy('${appDir.path}/$fileName');
        setState(() {
          _receiptPaths.add(savedImage.path);
        });
      } catch (e) {
        if (mounted) {
           AppToast.error(context, 'Failed to save image');
        }
      }
    }
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountText);

    if (title.isEmpty || amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      AppToast.error(context, 'Please fill in title and valid amount');
      return;
    }

    if (!_isIncome && _splits.isNotEmpty) {
      final splitTotal = _splits.fold<double>(0, (sum, s) => sum + s.amount);
      if (splitTotal > amount) {
        AppFeedback.error(context,
            'Split total (\$${splitTotal.toStringAsFixed(2)}) exceeds amount (\$${amount.toStringAsFixed(2)})');
        return;
      }
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
      receiptPaths: List.from(_receiptPaths),
      isTemplate: _isTemplate,
    );

    if (!_isIncome && !_isEditing) {
      final dailyLimit = context.read<BudgetProvider>().dailyLimit;
      if (provider.isDailyLimitExceeded(amount, dailyLimit)) {
        AppFeedback.onDelete();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Daily Limit Exceeded'),
            content: Text(
                'This expense will push your daily spending over the limit of \$${dailyLimit.toStringAsFixed(0)}.\n\nDo you still want to proceed?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _processSave(provider, expense);
                },
                child: const Text('Proceed',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        return;
      }
    }

    _processSave(provider, expense);
  }

  void _processSave(ExpenseProvider provider, Expense expense) {
    if (_isEditing) {
      provider.updateExpense(expense);
    } else {
      provider.addExpense(expense);
    }

    AppFeedback.onSuccess();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    final peopleProv = context.watch<PeopleProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF5F5F7),
      body: FadeTransition(
        opacity: _headerFade,
        child: Column(
          children: [
            // ═══════════════════════════════════════════
            // ZONE 1 — Hero Amount Header
            // ═══════════════════════════════════════════
            _buildHeroHeader(isDark),

            // ═══════════════════════════════════════════
            // ZONE 2 — Scrollable Card Selectors
            // ═══════════════════════════════════════════
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildCategoryCard(isDark, provider),
                  const SizedBox(height: 12),
                  _buildTitleCard(isDark),
                  const SizedBox(height: 12),
                  _buildDateCard(isDark),
                  const SizedBox(height: 12),

                  // Expandable extras toggle
                  SpringButton(
                    onTap: () {
                      AppHaptics.onTap();
                      setState(() => _showExtras = !_showExtras);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.subtleShadow(isDark),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                          const SizedBox(width: 12),
                          Text('More Options',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary)),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _showExtras ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(Icons.keyboard_arrow_down_rounded,
                                color: isDark
                                    ? AppColors.darkTextTertiary
                                    : AppColors.lightTextTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expandable extras
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: _showExtras
                        ? _buildExtrasSection(
                            isDark, provider, peopleProv)
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // ═══════════════════════════════════════════
            // ZONE 3 — Bottom Keypad + CTA
            // ═══════════════════════════════════════════
            _buildBottomSection(isDark),
          ],
        ),
      ),
    );
  }

  // ─── HERO HEADER ───
  Widget _buildHeroHeader(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _accentBg,
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: _accentBg.withValues(alpha: 0.3),
            offset: const Offset(0, 12),
            blurRadius: 28,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SpringButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Colors.black87, size: 24),
                    ),
                  ),
                  Text(
                    _isEditing ? 'Edit Transaction' : 'New Transaction',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  _isEditing
                      ? const SizedBox(width: 40)
                      : SpringButton(
                          onTap: () {
                            AppHaptics.onSelection();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TemplatesScreen()),
                            );
                          },
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.copy_all_rounded,
                                color: Colors.black87, size: 20),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 20),

              // Expense/Income toggle pill
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTogglePill('Expense', Icons.arrow_upward_rounded,
                        !_isIncome, () {
                      AppFeedback.onTap();
                      setState(() => _isIncome = false);
                    }),
                    _buildTogglePill('Income', Icons.arrow_downward_rounded,
                        _isIncome, () {
                      AppFeedback.onTap();
                      setState(() => _isIncome = true);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Large centered amount
              Text(
                '$_currencySymbol$_formattedAmount',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              // ─── NLP Quick Input ───
              GestureDetector(
                onTap: () => setState(() => _nlpMode = !_nlpMode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: _nlpMode ? 0.1 : 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _nlpMode
                      ? Row(
                          children: [
                            const Icon(Icons.text_fields_rounded,
                                size: 18, color: Colors.black54),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _nlpCtrl,
                                autofocus: true,
                                style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Spent 450 on lunch...',
                                  hintStyle: TextStyle(
                                    fontSize: 14, color: Colors.black38,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: _handleNLPInput,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _handleNLPInput(_nlpCtrl.text),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.check_rounded,
                                    size: 18, color: Colors.black87),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                size: 16, color: Colors.black.withValues(alpha: 0.4)),
                            const SizedBox(width: 8),
                            Text(
                              'Type naturally: "Spent 450 on lunch"',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTogglePill(
      String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return SpringButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? Colors.black87
                    : Colors.black.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected
                        ? Colors.black87
                        : Colors.black.withValues(alpha: 0.4),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─── ACCOUNT CARD ───
  Widget _buildAccountCard(bool isDark) {
    return SpringButton(
      onTap: () => _selectCurrency(context, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.subtleShadow(isDark),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.currency_exchange_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Currency',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currency,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary)),
                ],
              ),
            ),
            Icon(Icons.unfold_more_rounded,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
                size: 20),
          ],
        ),
      ),
    );
  }

  // ─── CATEGORY CARD ───
  Widget _buildCategoryCard(bool isDark, ExpenseProvider provider) {
    final cat = provider.allCategories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => ExpenseCategory.defaults.first);

    return SpringButton(
      onTap: () => _showCategoryPicker(context, isDark, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.subtleShadow(isDark),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(cat.icon, color: cat.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)),
                  const SizedBox(height: 2),
                  Text(_isIncome ? 'Income · Category' : 'Expense · Category',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary)),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary),
          ],
        ),
      ),
    );
  }

  // ─── TITLE CARD ───
  Widget _buildTitleCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.subtleShadow(isDark),
      ),
      child: TextField(
        controller: _titleCtrl,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary),
        decoration: InputDecoration(
          hintText: _isIncome ? 'Income source...' : 'What did you spend on?',
          hintStyle: TextStyle(
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary),
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(Icons.edit_note_rounded,
                size: 22,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }

  // ─── DATE CARD ───
  Widget _buildDateCard(bool isDark) {
    return SpringButton(
      onTap: () => _pickDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.subtleShadow(isDark),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.heroCream.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.calendar_today_rounded,
                  color: AppColors.fun, size: 20),
            ),
            const SizedBox(width: 14),
            Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary),
          ],
        ),
      ),
    );
  }

  // ─── EXTRAS (Notes, Recurring, Splits, Attachments, Template) ───
  Widget _buildExtrasSection(
      bool isDark, ExpenseProvider provider, PeopleProvider peopleProv) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          // Notes
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.subtleShadow(isDark),
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: 2,
              style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
              decoration: InputDecoration(
                hintText: 'Add a note... (optional)',
                hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
                border: InputBorder.none,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.sticky_note_2_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Payment Method selector
          _buildPaymentMethodRow(isDark),
          const SizedBox(height: 12),

          // Currency (auto-detected, only show if user wants to change)
          _buildAccountCard(isDark),
          const SizedBox(height: 12),

          // Recurring toggle
          _buildRecurringCard(isDark),
          const SizedBox(height: 12),

          // Split with people
          if (!_isIncome) ...[
            _buildSplitCard(isDark, peopleProv),
            const SizedBox(height: 12),
          ],

          // Attachments
          _buildAttachmentCard(isDark),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(bool isDark) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: PaymentMethod.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final m = PaymentMethod.values[i];
          final sel = m == _selectedPayment;
          return SpringButton(
            onTap: () {
              AppHaptics.onSelection();
              setState(() => _selectedPayment = m);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              decoration: BoxDecoration(
                color: sel
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : isDark
                        ? AppColors.darkCard
                        : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? AppColors.primary : Colors.transparent,
                    width: 2),
                boxShadow: AppColors.subtleShadow(isDark),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(m.icon,
                      size: 22,
                      color: sel
                          ? AppColors.primary
                          : isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                  const SizedBox(height: 6),
                  Text(m.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? AppColors.primary : null)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecurringCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.subtleShadow(isDark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.repeat_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Recurring',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary))),
              Switch.adaptive(
                value: _isRecurring,
                activeTrackColor: AppColors.primary,
                onChanged: (v) {
                  AppHaptics.onToggle();
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
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: RecurringType.values.map((t) {
                        final sel = t == _recurringType;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: SpringButton(
                              onTap: () =>
                                  setState(() => _recurringType = t),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: sel
                                          ? AppColors.primary
                                          : isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder),
                                ),
                                child: Center(
                                  child: Text(t.label,
                                      style: TextStyle(
                                          color: sel
                                              ? Colors.white
                                              : null,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
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
          // ─── Save as Template (merged here) ───
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Row(
            children: [
              Icon(Icons.bookmark_border_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Save as Template',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)),
              ),
              Switch.adaptive(
                value: _isTemplate,
                activeTrackColor: AppColors.primary,
                onChanged: (v) {
                  AppHaptics.onToggle();
                  setState(() => _isTemplate = v);
                },
              ),
            ],
          ),
          // ─── Load from Templates ───
          if (!_isEditing)
            GestureDetector(
              onTap: () {
                AppHaptics.onSelection();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TemplatesScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.file_copy_outlined,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Load from Templates',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSplitCard(bool isDark, PeopleProvider peopleProv) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.subtleShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Split Expense',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary))),
              if (peopleProv.activeMembers.isNotEmpty)
                SpringButton(
                  onTap: () {
                    AppHaptics.onSelection();
                    _showSplitModal(context, peopleProv, isDark);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('+ Add',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
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
                      color: isDark ? AppColors.darkBg : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(e.value.personName[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.value.personName)),
                      Text('\$${e.value.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _splits.removeAt(e.key)),
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary)),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.subtleShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attachment_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Attachments',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary))),
              SpringButton(
                onTap: _pickImage,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('+ Add',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          if (_receiptPaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _receiptPaths.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  return Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: DecorationImage(
                            image: FileImage(File(_receiptPaths[i])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () {
                            AppFeedback.onDelete();
                            setState(() => _receiptPaths.removeAt(i));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── BOTTOM KEYPAD + CTA ───
  Widget _buildBottomSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Numeric keypad
              _buildKeypadRow(['1', '2', '3'], isDark),
              _buildKeypadRow(['4', '5', '6'], isDark),
              _buildKeypadRow(['7', '8', '9'], isDark),
              _buildKeypadRow(['.', '0', '⌫'], isDark),
              const SizedBox(height: 12),

              // CTA Button
              SpringButton(
                onTap: _save,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : const Color(0xFF1A1B2E),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.white : const Color(0xFF1A1B2E))
                            .withValues(alpha: 0.3),
                        offset: const Offset(0, 6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isEditing
                          ? 'Update Transaction'
                          : _isIncome
                              ? 'Add Income'
                              : 'Add Expense',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF1A1B2E) : Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SpringButton(
                scaleFactor: 0.92,
                onTap: () => _onKeyTap(key),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: key == '⌫'
                        ? Icon(Icons.backspace_outlined,
                            size: 22,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary)
                        : Text(key,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Modals ───
  Future<void> _pickDate(BuildContext context) async {
    AppHaptics.onSelection();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select transaction date',
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
        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
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
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Text('Select Currency',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)),
                  const SizedBox(height: 16),
                  ...currencies.map((c) {
                    final sel = c.$1 == _currency;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SpringButton(
                        onTap: () {
                          setState(() => _currency = c.$1);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                width: sel ? 2 : 1),
                          ),
                          child: Row(children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primary
                                        .withValues(alpha: 0.15)
                                    : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder)
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(c.$2,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: sel
                                            ? AppColors.primary
                                            : null,
                                        fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(c.$1,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: sel
                                              ? AppColors.primary
                                              : null)),
                                  Text(c.$3,
                                      style: Theme.of(ctx)
                                          .textTheme
                                          .bodySmall),
                                ],
                              ),
                            ),
                            if (sel)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 20),
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

  void _showCategoryPicker(
      BuildContext context, bool isDark, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
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
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Text('Select Category',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: provider.allCategories.map((cat) {
                      final sel = cat.id == _selectedCategoryId;
                      return SpringButton(
                        onTap: () {
                          AppHaptics.onSelection();
                          setState(() => _selectedCategoryId = cat.id);
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? cat.color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
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
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: cat.color
                                      .withValues(alpha: sel ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(cat.icon,
                                    size: 16, color: cat.color),
                              ),
                              const SizedBox(width: 8),
                              Text(cat.label,
                                  style: TextStyle(
                                      color: sel ? cat.color : null,
                                      fontSize: 13,
                                      fontWeight: sel
                                          ? FontWeight.w700
                                          : FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.92)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Text('Split Equally (50/50)',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)),
                  const SizedBox(height: 6),
                  Text('Quickly split this expense with someone',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                  const SizedBox(height: 20),
                  ...members.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SpringButton(
                          onTap: () {
                            final total = double.tryParse(_amountText);
                            if (total != null && total > 0) {
                              setState(() => _splits.add(ExpenseSplit(
                                  personId: p.id,
                                  personName: p.name,
                                  amount: total / 2)));
                              Navigator.pop(ctx);
                            } else {
                              AppToast.error(
                                  ctx, 'Enter a total amount first');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCard
                                  : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                            ),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: p.avatarColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(p.initials,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(p.name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary))),
                              const Icon(Icons.call_split_rounded,
                                  size: 20, color: AppColors.primary),
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
