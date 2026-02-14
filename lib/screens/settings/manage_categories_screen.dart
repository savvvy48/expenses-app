import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/widgets/toast.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();
    // provider.allCategories includes defaults + custom.
    // We should probably filter them to separate sections.
    final allCats = provider.allCategories;
    final defaults = allCats.where((c) => !c.isCustom).toList();
    final custom = allCats.where((c) => c.isCustom).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Category',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (custom.isNotEmpty) ...[
            _SectionHeader('My Categories'),
            const SizedBox(height: 8),
            ...custom.map((c) => _CategoryTile(category: c, isCustom: true)),
            const SizedBox(height: 24),
          ],
          _SectionHeader('Default Categories'),
          const SizedBox(height: 8),
          ...defaults.map((c) => _CategoryTile(category: c, isCustom: false)),
          const SizedBox(height: 80), // Fab space
        ],
      ),
    );
  }

  void _showEditor(BuildContext context, ExpenseCategory? category) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryEditor(expenseCategory: category),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ExpenseCategory category;
  final bool isCustom;
  const _CategoryTile({required this.category, required this.isCustom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(category.icon, color: category.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(category.label,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          if (isCustom) ...[
            SpringButton(
              onTap: () => _edit(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.edit,
                    size: 18,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
              ),
            ),
            SpringButton(
              onTap: () => _delete(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.delete,
                    size: 18, color: AppColors.error),
              ),
            ),
          ] else
            const Icon(Icons.lock, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  void _edit(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryEditor(expenseCategory: category),
    );
  }

  void _delete(BuildContext context) {
    AppFeedback.onSelection();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Delete "${category.label}"? Existing expenses will be kept but functionality might be affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<ExpenseProvider>().deleteCategory(category.id);
              Navigator.pop(ctx);
              AppFeedback.onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _CategoryEditor extends StatefulWidget {
  final ExpenseCategory? expenseCategory;
  const _CategoryEditor({this.expenseCategory});

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late TextEditingController _nameCtrl;
  late int _selectedColor;
  late int _selectedIcon;

  final List<int> _colors = [
    0xFFFF7675, 0xFF6C5CE7, 0xFF00B894, 0xFFFDCB6E, 
    0xFFE17055, 0xFF55EFC4, 0xFFA29BFE, 0xFFFD79A8,
    0xFF636E72, 0xFF0984E3, 0xFFD63031, 0xFFE84393
  ];

  final List<IconData> _icons = [
    Icons.grid_view_rounded, Icons.restaurant_rounded, Icons.directions_car_rounded,
    Icons.sports_esports_rounded, Icons.subscriptions_rounded, Icons.favorite_rounded,
    Icons.shopping_bag_rounded, Icons.school_rounded, Icons.flight_rounded,
    Icons.pets_rounded, Icons.work_rounded, Icons.home_rounded,
    Icons.local_cafe_rounded, Icons.fitness_center_rounded, Icons.build_rounded,
    Icons.local_grocery_store_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.expenseCategory?.label ?? '');
    _selectedColor = widget.expenseCategory?.colorValue ?? _colors[0];
    _selectedIcon = widget.expenseCategory?.iconCodePoint ?? _icons[0].codePoint;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.expenseCategory == null ? 'New Category' : 'Edit Category', style: theme.textTheme.titleLarge),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'Category Name',
              filled: true,
              fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          Text('Color', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: _colors.map((c) => GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: _selectedColor == c ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2) : null,
                ),
                child: _selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Text('Icon', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: GridView.count(
              crossAxisCount: 6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _icons.map((icon) => GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon.codePoint),
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedIcon == icon.codePoint 
                        ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: _selectedIcon == icon.codePoint 
                        ? Border.all(color: Color(_selectedColor)) 
                        : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Icon(icon, color: _selectedIcon == icon.codePoint ? Color(_selectedColor) : Colors.grey, size: 20),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save Category', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppToast.error(context, 'Enter a category name');
      return;
    }

    final cat = ExpenseCategory(
      id: widget.expenseCategory?.id ?? const Uuid().v4(),
      label: name,
      iconCodePoint: _selectedIcon,
      colorValue: _selectedColor,
      isCustom: true,
    );

    context.read<ExpenseProvider>().saveCategory(cat);
    AppFeedback.onSuccess();
    Navigator.pop(context);
    AppToast.success(context, widget.expenseCategory == null ? 'Category created' : 'Category updated');
  }
}
