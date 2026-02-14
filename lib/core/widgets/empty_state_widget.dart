import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class EmptyStateWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.receipt_long,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (ctx, child) {
                return Transform.translate(
                  offset: Offset(0, -8 * _ctrl.value),
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : AppColors.lightBorder.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon,
                    size: 36,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary),
              ),
            ),
            const SizedBox(height: 24),
            Text(widget.title,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 8),
            Text(widget.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
