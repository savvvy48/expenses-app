import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'analytics/analytics_screen.dart';
import 'add_expense/add_expense_screen.dart';
import 'people/people_screen.dart';
import 'settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final _screens = const [
    HomeScreen(),
    AnalyticsScreen(),
    SizedBox(),
    PeopleScreen(),
    SettingsScreen(),
  ];

  void _onTabTap(int index) {
    if (index == 2) {
      HapticFeedback.mediumImpact();
      // Backdrop blur + slide up modal
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black38,
          barrierDismissible: true,
          pageBuilder: (context, animation, _) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10 * animation.value,
                sigmaY: 10 * animation.value,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
                child: const AddExpenseScreen(),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Smooth fade + slide transition between pages
    final goingRight = _currentIndex > _previousIndex;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(goingRight ? 0.05 : -0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavButton(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTabTap(0),
                  isDark: isDark,
                ),
                _NavButton(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'Analytics',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTabTap(1),
                  isDark: isDark,
                ),
                _AddButton(onTap: () => _onTabTap(2), isDark: isDark),
                _NavButton(
                  icon: Icons.people_outlined,
                  activeIcon: Icons.people,
                  label: 'People',
                  isActive: _currentIndex == 3,
                  onTap: () => _onTabTap(3),
                  isDark: isDark,
                ),
                _NavButton(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  isActive: _currentIndex == 4,
                  onTap: () => _onTabTap(4),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated nav button with scale feedback
class _NavButton extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _NavButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? AppColors.primary
        : widget.isDark
            ? AppColors.darkTextTertiary
            : AppColors.lightTextTertiary;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.9)
              .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 64,
            decoration: widget.isActive
                ? BoxDecoration(
                    border: const Border(
                      top: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    color: AppColors.primary.withValues(alpha: 0.06),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.isActive ? widget.activeIcon : widget.icon,
                    key: ValueKey(widget.isActive),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight:
                        widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated add button with spring scale
class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isDark;
  const _AddButton({required this.onTap, required this.isDark});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 0.88)
                .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: AppColors.sharpShadow(widget.isDark),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
