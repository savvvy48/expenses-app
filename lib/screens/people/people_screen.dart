import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/animated_list_item.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/spring_button.dart';
import '../../core/widgets/toast.dart';
import '../../core/utils/app_haptics.dart';
import 'package:uuid/uuid.dart';
import '../../models/person.dart';
import '../../providers/people_provider.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PeopleProvider>();
    final people = provider.people;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Column(
        children: [
          // ─── Custom Header ───
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'People',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      letterSpacing: -0.5,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  SpringButton(
                    onTap: () => _showAddPersonSheet(context, provider, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppColors.glowShadow(AppColors.primary),
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

          // ─── Body ───
          Expanded(
            child: people.isEmpty
                ? const Center(
                    child: EmptyStateWidget(
                      icon: Icons.people_outline_rounded,
                      title: 'No people added',
                      subtitle: 'Add people to track split expenses',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    physics: const BouncingScrollPhysics(),
                    itemCount: people.length,
                    itemBuilder: (context, index) {
                      final person = people[index];
                      return AnimatedListItem(
                        index: index,
                        child: _PersonTile(
                            person: person, isDark: isDark),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddPersonSheet(
      BuildContext context, PeopleProvider provider, bool isDark) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

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
              child: SingleChildScrollView(
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
                      'Add Person',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name Field
                    _buildInputField('Name', nameController, isDark, autofocus: true),
                    const SizedBox(height: 12),
                    // Email Field
                    _buildInputField('Email', emailController, isDark, 
                      keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    // Phone Field
                    _buildInputField('Phone (Optional)', phoneController, isDark, 
                      keyboardType: TextInputType.phone),
                    const SizedBox(height: 20),
                    SpringButton(
                      onTap: () {
                        final name = nameController.text.trim();
                        final email = emailController.text.trim();
                        final phone = phoneController.text.trim();

                        if (name.isNotEmpty && email.isNotEmpty) {
                          provider.addPerson(Person(
                            id: const Uuid().v4(),
                            name: name,
                            email: email,
                            phone: phone.isEmpty ? null : phone,
                          ));
                          AppToast.success(
                              context, '$name added!');
                          Navigator.pop(ctx);
                        } else {
                          AppToast.error(context, 'Name and Email are required');
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
                            'Add Person',
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
          ),
        );
      },
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller, bool isDark, 
      {bool autofocus = false, TextInputType? keyboardType}) {
    return Container(
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
        autofocus: autofocus,
        keyboardType: keyboardType,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final Person person;
  final bool isDark;
  const _PersonTile({required this.person, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SpringButton(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(14),
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
              // Rounded-square avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: person.avatarColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    person.initials,
                    style: TextStyle(
                      color: person.avatarColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      person.email,
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
