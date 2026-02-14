import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';

import '../../core/widgets/spring_button.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/toast.dart';
import '../../models/person.dart';
import '../../providers/people_provider.dart';
import '../../providers/expense_provider.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final peopleProv = context.watch<PeopleProvider>();
    final expProv = context.watch<ExpenseProvider>();
    final active = peopleProv.activeMembers;
    final pending = peopleProv.pendingInvites;

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('People', style: theme.textTheme.headlineMedium),
                      Text('${active.length + pending.length} members',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                  SpringButton(
                    onTap: () => _showAddPerson(context, peopleProv, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        boxShadow: AppColors.sharpShadow(isDark),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person_add, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text('Add Person',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Members
            if (active.isNotEmpty) ...[
              Text('Active Members',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...active.asMap().entries.map((e) => AnimatedListItem(
                    index: e.key + 1,
                    child: _SwipeablePersonTile(
                      person: e.value,
                      isDark: isDark,
                      theme: theme,
                      expenseCount: _expenseCount(expProv, e.value.id),
                      onDelete: () {
                        HapticFeedback.heavyImpact();
                        peopleProv.deletePerson(e.value.id);
                        AppToast.success(context, '${e.value.name} removed');
                      },
                    ),
                  )),
            ],

            if (pending.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Pending Invites',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.warning, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...pending.asMap().entries.map((e) => AnimatedListItem(
                    index: e.key + active.length + 1,
                    child: _SwipeablePersonTile(
                      person: e.value,
                      isDark: isDark,
                      theme: theme,
                      expenseCount: 0,
                      onDelete: () {
                        HapticFeedback.heavyImpact();
                        peopleProv.deletePerson(e.value.id);
                        AppToast.success(context, '${e.value.name} removed');
                      },
                    ),
                  )),
            ],

            if (active.isEmpty && pending.isEmpty)
              AnimatedListItem(
                index: 1,
                child: const EmptyStateWidget(
                  title: 'No people yet',
                  subtitle: 'Add people to split expenses with',
                  icon: Icons.people_outline,
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  int _expenseCount(ExpenseProvider prov, String personId) {
    return prov.allExpenses
        .where((e) => e.splits.any((s) => s.personId == personId))
        .length;
  }

  void _showAddPerson(
      BuildContext context, PeopleProvider provider, bool isDark) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = 'Member';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) => ClipRect(
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
                    Center(child: Container(width: 40, height: 4,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    const SizedBox(height: 16),
                    Text('Add New Person',
                        style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: TextField(
                        controller: nameCtrl,
                        decoration:
                            const InputDecoration(hintText: 'Full name'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Email (optional)'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Role',
                        style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Admin', 'Member', 'Viewer']
                          .map((r) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SpringButton(
                                    onTap: () => setLocal(() => role = r),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: role == r
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                            color: role == r
                                                ? AppColors.primary
                                                : isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.lightBorder),
                                      ),
                                      child: Center(
                                        child: Text(r,
                                            style: TextStyle(
                                                color: role == r
                                                    ? Colors.white
                                                    : null,
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w500)),
                                      ),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: SpringButton(
                        onTap: () {
                          if (nameCtrl.text.trim().isEmpty) {
                            AppToast.error(ctx, 'Name is required');
                            return;
                          }
                          HapticFeedback.mediumImpact();
                          provider.addPerson(Person(
                            id: UniqueKey().toString(),
                            name: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim().isEmpty
                                ? ''
                                : emailCtrl.text.trim(),
                            role: role,
                          ));
                          Navigator.pop(ctx);
                          AppToast.success(
                              context, '${nameCtrl.text.trim()} added!');
                        },
                        child: Container(
                          height: 48,
                          color: AppColors.primary,
                          child: const Center(
                            child: Text('Add Person',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Swipeable Person Tile ---
class _SwipeablePersonTile extends StatelessWidget {
  final Person person;
  final bool isDark;
  final ThemeData theme;
  final int expenseCount;
  final VoidCallback onDelete;

  const _SwipeablePersonTile({
    required this.person,
    required this.isDark,
    required this.theme,
    required this.expenseCount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(person.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        confirmDismiss: (_) async {
          HapticFeedback.mediumImpact();
          return true;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: AppColors.error,
          child: const Icon(Icons.delete_forever,
              color: Colors.white, size: 28),
        ),
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
                color: person.avatarColor,
                child: Center(
                  child: Text(person.initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontSize: 14)),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: _roleColor(person.role)
                            .withValues(alpha: 0.1),
                        child: Text(person.role,
                            style: TextStyle(
                                color: _roleColor(person.role),
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text('$expenseCount expenses',
                          style: theme.textTheme.bodySmall),
                    ]),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                color: person.status == PersonStatus.active
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.primary;
      case 'viewer':
        return AppColors.transport;
      default:
        return AppColors.food;
    }
  }
}


