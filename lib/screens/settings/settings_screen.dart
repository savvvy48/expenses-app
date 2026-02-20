import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/app_haptics.dart';
import '../../providers/settings_provider.dart';
import '../../providers/expense_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/widgets/toast.dart';
import 'manage_categories_screen.dart';
import 'budget_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProv = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          // ─── Custom Header ───
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  letterSpacing: -0.5,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ),

          // ─── Appearance ───
          _SectionHeader(title: 'Appearance', isDark: isDark),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            iconBg: AppColors.primary,
            title: 'Dark Mode',
            subtitle: 'Toggle dark appearance',
            trailing: Switch.adaptive(
              value: settingsProv.themeMode == ThemeMode.dark,
              activeTrackColor: AppColors.primary,
              onChanged: (val) {
                AppFeedback.onSelection();
                settingsProv.setThemeMode(
                    val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
            isDark: isDark,
          ),

          const SizedBox(height: 8),

          // ─── Localization ───
          _SectionHeader(title: 'Localization', isDark: isDark),
          _SettingsTile(
            icon: Icons.payments_rounded,
            iconBg: AppColors.success,
            title: 'Currency',
            subtitle:
                'Current: ${settingsProv.currencyCode} (${settingsProv.currencySymbol})',
            onTap: () =>
                _showCurrencyPicker(context, settingsProv, isDark),
            isDark: isDark,
          ),

          const SizedBox(height: 8),

          // ─── Data & Privacy ───
          _SectionHeader(title: 'Data & Privacy', isDark: isDark),
          _SettingsTile(
            icon: Icons.category_rounded,
            iconBg: AppColors.heroLavender,
            title: 'Manage Categories',
            subtitle: 'Add or edit your expense categories',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ManageCategoriesScreen())),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.account_balance_wallet_rounded, 
            iconBg: AppColors.success,
            title: 'Monthly Budget',
            subtitle: 'Set your spending limits',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BudgetScreen()),
            ),
            isDark: isDark,
          ),
          _SettingsTile(
            icon: Icons.ios_share_rounded,
            iconBg: AppColors.heroSky,
            title: 'Export Data',
            subtitle: 'Share your expenses as CSV/PDF',
            onTap: () => _exportData(context),
            isDark: isDark,
          ),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            iconBg: AppColors.error,
            title: 'Clear All Data',
            subtitle: 'Permanently delete all records',
            titleColor: AppColors.error,
            onTap: () => _showConfirmClearDialog(context, isDark),
            isDark: isDark,
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final expenses = context.read<ExpenseProvider>().allExpenses;
      if (expenses.isEmpty) {
        // AppToast.error(context, 'No data to export'); // Assuming AppToast exists or replace
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('Date,Title,Amount,Category,PaymentMethod,Notes');

      for (var e in expenses) {
        final date = DateFormat('yyyy-MM-dd').format(e.date);
        final cleanTitle = e.title.replaceAll(',', ' ');
        final cleanNotes = (e.notes ?? '').replaceAll(',', ' ');
        buffer.writeln('$date,$cleanTitle,${e.amount},${e.category.label},${e.paymentMethod.name},$cleanNotes');
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/expenses_export.csv';
      final file = File(path);
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(path)], text: 'My Expenses Data');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider provider, bool isDark) {
    final currencies = [
      ('USD', '\$', 'US Dollar'),
      ('INR', '₹', 'Indian Rupee'),
      ('EUR', '€', 'Euro'),
      ('GBP', '£', 'British Pound'),
      ('JPY', '¥', 'Japanese Yen'),
      ('AED', 'د.إ', 'UAE Dirham'),
      ('CAD', 'C\$', 'Canadian Dollar'),
    ];

    AppHaptics.onSelection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Currency',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...currencies.map((c) {
                    final sel = c.$1 == provider.currencyCode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SpringButton(
                        onTap: () {
                          AppFeedback.onSelection();
                          provider.setCurrency(c.$1);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary
                                    .withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                          .withValues(alpha: 0.15)
                                      : (isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder)
                                          .withValues(alpha: 0.5),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    c.$2,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: sel
                                          ? AppColors.primary
                                          : isDark
                                              ? AppColors
                                                  .darkTextPrimary
                                              : AppColors
                                                  .lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.$3,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: sel
                                            ? AppColors.primary
                                            : isDark
                                                ? AppColors
                                                    .darkTextPrimary
                                                : AppColors
                                                    .lightTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      c.$1,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors
                                                .darkTextTertiary
                                            : AppColors
                                                .lightTextTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (sel)
                                const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 22),
                            ],
                          ),
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



  void _showConfirmClearDialog(BuildContext context, bool isDark) {
    AppHaptics.onSelection();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Clear All Data?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is irreversible. Are you sure?',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SpringButton(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBg : const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SpringButton(
                          onTap: () {
                            context.read<ExpenseProvider>().clearAllData();
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
        );
      },
    );
  }
}

// ───────────────────────── SECTION HEADER ─────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
        ),
      ),
    );
  }
}

// ───────────────────────── SETTINGS TILE ─────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: SpringButton(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Rounded-square icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconBg, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: titleColor ??
                            (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
              trailing ??
                  Icon(Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
