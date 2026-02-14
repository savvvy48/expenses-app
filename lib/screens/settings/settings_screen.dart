import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProv = context.watch<ThemeProvider>();
    final budgetProv = context.watch<BudgetProvider>();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AnimatedListItem(
            index: 0,
            child: Text('Settings', style: theme.textTheme.headlineMedium),
          ),
          const SizedBox(height: 20),

          // Appearance section
          AnimatedListItem(index: 1, child: _SectionLabel('Appearance')),
          const SizedBox(height: 8),
          AnimatedListItem(
            index: 2,
            child: _SettingsTile(
              icon: Icons.dark_mode,
              iconColor: AppColors.housing,
              title: 'Dark Mode',
              subtitle: isDark ? 'On' : 'Off',
              isDark: isDark,
              theme: theme,
              trailing: Switch.adaptive(
                value: isDark,
                activeTrackColor: AppColors.primary,
                onChanged: (_) {
                  AppFeedback.onSelection();
                  themeProv.toggleTheme();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notifications
          AnimatedListItem(index: 3, child: _SectionLabel('Notifications')),
          const SizedBox(height: 8),
          AnimatedListItem(
            index: 4,
            child: _SettingsTile(
              icon: Icons.notifications_none,
              iconColor: AppColors.primary,
              title: 'Daily Reminder',
              subtitle: 'Get reminded to log expenses',
              isDark: isDark,
              theme: theme,
              trailing: Switch.adaptive(
                value: false,
                activeTrackColor: AppColors.primary,
                onChanged: (_) {
                  AppFeedback.info(context, 'Reminders coming soon');
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedListItem(
            index: 5,
            child: _SettingsTile(
              icon: Icons.info_outline,
              iconColor: AppColors.primary,
              title: 'Budget Alerts',
              subtitle: 'Alerts appear automatically when near limits',
              isDark: isDark,
              theme: theme,
              onTap: () {
                HapticFeedback.lightImpact();
                AppToast.info(context, 'Alerts are enabled by default');
              },
            ),
          ),
          const SizedBox(height: 8),
          // Currency Setting (Issue #6)
          AnimatedListItem(
            index: 6,
            child: _SettingsTile(
              icon: Icons.attach_money,
              iconColor: AppColors.success,
              title: 'Currency',
              subtitle: 'Select your preferred currency', // In real app, bind to provider
              isDark: isDark,
              theme: theme,
              onTap: () {
                AppFeedback.onSelection();
                // TODO: Show currency picker dialog and save to settings
                AppFeedback.info(context, 'Global currency setting coming soon');
              },
            ),
          ),
          const SizedBox(height: 16),

          // Budget section
          AnimatedListItem(index: 6, child: _SectionLabel('Budget Settings')),
          const SizedBox(height: 8),
          AnimatedListItem(
            index: 7,
            child: _SettingsTile(
              icon: Icons.calendar_month,
              iconColor: AppColors.transport,
              title: 'Monthly Limit',
              subtitle: '\$${budgetProv.monthlyLimit.toStringAsFixed(0)}',
              isDark: isDark,
              theme: theme,
              onTap: () => _editBudget(context, budgetProv, 'monthly', isDark),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedListItem(
            index: 8,
            child: _SettingsTile(
              icon: Icons.today,
              iconColor: AppColors.food,
              title: 'Daily Limit',
              subtitle: '\$${budgetProv.dailyLimit.toStringAsFixed(0)}',
              isDark: isDark,
              theme: theme,
              onTap: () => _editBudget(context, budgetProv, 'daily', isDark),
            ),
          ),
          const SizedBox(height: 16),

          // Data Management
          AnimatedListItem(
              index: 9, child: _SectionLabel('Data Management')),
          const SizedBox(height: 8),
          AnimatedListItem(
            index: 10,
            child: _SettingsTile(
              icon: Icons.share,
              iconColor: AppColors.primary,
              title: 'Share Data',
              subtitle: 'Export and share your expenses',
              isDark: isDark,
              theme: theme,
              onTap: () {
                AppFeedback.warning(context, 'Share feature coming soon');
              },
            ),
          ),
          const SizedBox(height: 8),
          AnimatedListItem(
            index: 11,
            child: _SettingsTile(
              icon: Icons.file_download,
              iconColor: AppColors.transport,
              title: 'Export CSV',
              subtitle: 'Download expenses as spreadsheet',
              isDark: isDark,
              theme: theme,
              onTap: () {
                AppFeedback.warning(context, 'Export feature coming soon');
              },
            ),
          ),
          const SizedBox(height: 8),
          AnimatedListItem(
            index: 12,
            child: _SettingsTile(
              icon: Icons.cloud_upload_outlined,
              iconColor: AppColors.shopping,
              title: 'Auto Backup',
              subtitle: 'Automatically backup your data',
              isDark: isDark,
              theme: theme,
              trailing: Switch.adaptive(
                value: false,
                activeTrackColor: AppColors.primary,
                onChanged: (_) {
                  AppFeedback.warning(context, 'Backup coming soon');
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Danger zone
          AnimatedListItem(
            index: 13,
            child: _SectionLabel('Danger Zone'),
          ),
          const SizedBox(height: 8),
          AnimatedListItem(
            index: 14,
            child: SpringButton(
              onTap: () => _confirmClear(context, isDark),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.error, width: 2),
                ),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    color: AppColors.error.withValues(alpha: 0.1),
                    child: const Icon(Icons.delete_forever,
                        color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clear All Data',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.error, fontSize: 14)),
                      Text('Permanently delete all expenses',
                          style: theme.textTheme.bodySmall),
                    ],
                  )),
                  const Icon(Icons.chevron_right, color: AppColors.error),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Version info
          Center(
            child: Text('Daily Expenses v1.0.0',
                style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 100),
        ]),
      ),
    );
  }

  void _editBudget(BuildContext context, BudgetProvider prov, String type,
      bool isDark) {
    HapticFeedback.selectionClick();
    final ctrl = TextEditingController(
      text: type == 'monthly'
          ? prov.monthlyLimit.toStringAsFixed(0)
          : prov.dailyLimit.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRect(
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 40,
                height: 4,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              const SizedBox(height: 16),
              Text('Edit ${type == 'monthly' ? 'Monthly' : 'Daily'} Limit',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'Enter amount', prefixText: '\$ '),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: SpringButton(
                  onTap: () {
                    final val = double.tryParse(ctrl.text);
                    if (val != null && val > 0) {
                      if (type == 'monthly') {
                        prov.setMonthlyLimit(val);
                      } else {
                        prov.setDailyLimit(val);
                      }
                      Navigator.pop(ctx);
                      AppFeedback.success(context, 'Budget updated!');
                    } else {
                      AppFeedback.error(ctx, 'Enter a valid amount');
                    }
                  },
                  child: Container(
                    height: 48,
                    color: AppColors.primary,
                    child: const Center(
                      child: Text('Save',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, bool isDark) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          shape:
              const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('Clear All Data'),
          content: const Text(
              'This will permanently delete all your expenses. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            SpringButton(
              onTap: () {
                final expProv = context.read<ExpenseProvider>();
                final ids = expProv.allExpenses.map((e) => e.id).toList();
                for (final id in ids) {
                  expProv.deleteExpense(id);
                }
                Navigator.pop(ctx);
                AppFeedback.success(context, 'All data cleared');
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.error,
                child: const Text('Delete Everything',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Section Label ---
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary));
  }
}

// --- Settings Tile ---
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final ThemeData theme;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.theme,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          color: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 14)),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ],
        )),
        ?trailing,
        if (onTap != null && trailing == null)
          const Icon(Icons.chevron_right, size: 20),
      ]),
    );

    if (onTap != null) {
      return SpringButton(onTap: onTap, child: tile);
    }
    return tile;
  }
}
