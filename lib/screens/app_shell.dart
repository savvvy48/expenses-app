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
    SizedBox(), // placeholder for center FAB
    PeopleScreen(),
    SettingsScreen(),
  ];

  void _onTabTap(int index) {
    if (index == 2) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AddExpenseScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutQuart)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          fullscreenDialog: true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goingRight = _currentIndex > _previousIndex;

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuart,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(goingRight ? 0.08 : -0.08, 0),
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
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _currentIndex,
        isDark: isDark,
        onTabTap: _onTabTap,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// BOTTOM NAV BAR
// ═══════════════════════════════════════════════════════════════════

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTabTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.isDark,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCard.withOpacity(0.95)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: AppColors.softShadow(isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            _NavIcon(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              isActive: currentIndex == 0,
              isDark: isDark,
              onTap: () => onTabTap(0),
            ),
            _NavIcon(
              icon: Icons.pie_chart_outline_rounded,
              activeIcon: Icons.pie_chart_rounded,
              isActive: currentIndex == 1,
              isDark: isDark,
              onTap: () => onTabTap(1),
            ),
            // ─── Center FAB ───
            Expanded(
              child: _CenterFAB(
                onTap: () => onTabTap(2),
              ),
            ),
            _NavIcon(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              isActive: currentIndex == 3,
              isDark: isDark,
              onTap: () => onTabTap(3),
            ),
            _NavIcon(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              isActive: currentIndex == 4,
              isDark: isDark,
              onTap: () => onTabTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// NAV ICON (icon only + dot indicator)
// ═══════════════════════════════════════════════════════════════════

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.primary
        : isDark
            ? AppColors.darkTextTertiary
            : AppColors.lightTextTertiary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            // Dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: isActive ? 6 : 0,
              height: isActive ? 6 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CENTER FAB
// ═══════════════════════════════════════════════════════════════════

class _CenterFAB extends StatefulWidget {
  final VoidCallback onTap;
  const _CenterFAB({required this.onTap});

  @override
  State<_CenterFAB> createState() => _CenterFABState();
}

class _CenterFABState extends State<_CenterFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: Center(
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.88).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
          ),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: AppColors.glowShadow(AppColors.primary),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
