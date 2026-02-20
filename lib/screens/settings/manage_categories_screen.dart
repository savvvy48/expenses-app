import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/utils/app_haptics.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    final categories = provider.allCategories;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF5F5F7),
      body: Column(
        children: [
          // ─── Custom Header ───
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  SpringButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppColors.subtleShadow(isDark),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  SpringButton(
                    onTap: () => _showAddCategorySheet(
                        context, provider, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow:
                            AppColors.floatingShadow(AppColors.primary),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text('Add',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Category List ───
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return AnimatedListItem(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SpringButton(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: AppColors.subtleShadow(isDark),
                        ),
                        child: Row(
                          children: [
                            // Rounded-square icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: cat.color
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: Icon(cat.icon,
                                  color: cat.color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.label,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  if (cat.isCustom)
                                    Text(
                                      'Custom',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.darkTextTertiary
                                            : AppColors
                                                .lightTextTertiary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (cat.isCustom)
                              SpringButton(
                                onTap: () =>
                                    provider.deleteCategory(cat.id),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.error
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                      size: 18),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategorySheet(
      BuildContext context, ExpenseProvider provider, bool isDark) {
    final controller = TextEditingController();
    AppHaptics.onSelection();
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
                  24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
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
                    'New Category',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Category name',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.lightTextTertiary,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SpringButton(
                    onTap: () {
                      if (controller.text.trim().isNotEmpty) {
                        provider.saveCategory(ExpenseCategory(
                          id: DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                          label: controller.text.trim(),
                          iconCodePoint:
                              Icons.category_rounded.codePoint,
                          colorValue:
                              AppColors.primary.toARGB32(),
                          isCustom: true,
                        ));
                        Navigator.pop(ctx);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1A1B2E),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          'Add Category',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF1A1B2E)
                                : Colors.white,
                            fontSize: 16,
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
      },
    );
  }
}
