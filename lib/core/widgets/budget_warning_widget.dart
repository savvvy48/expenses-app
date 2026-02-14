import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../providers/budget_provider.dart';

class BudgetWarningWidget extends StatelessWidget {
  final BudgetStatus status;
  final double usage; // 0.0 to 1.0+

  const BudgetWarningWidget({
    super.key,
    required this.status,
    required this.usage,
  });

  @override
  Widget build(BuildContext context) {
    if (status == BudgetStatus.safe) return const SizedBox.shrink();

    final color = _statusColor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(status), color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusTitle(status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _statusMessage(status),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (status == BudgetStatus.exceeded || status == BudgetStatus.critical)
            _PulseIcon(color: color),
        ],
      ),
    );
  }

  Color _statusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.exceeded:
        return const Color(0xFFD63031);
      case BudgetStatus.critical:
        return const Color(0xFFFF7675);
      case BudgetStatus.warning:
        return const Color(0xFFFD9644);
      case BudgetStatus.notice:
        return const Color(0xFFFDCB6E);
      default:
        return AppColors.success;
    }
  }

  IconData _statusIcon(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.exceeded:
        return Icons.error_outline;
      case BudgetStatus.critical:
        return Icons.warning_amber_rounded;
      case BudgetStatus.warning:
        return Icons.info_outline;
      case BudgetStatus.notice:
        return Icons.insights;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _statusTitle(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.exceeded:
        return 'Budget Exceeded';
      case BudgetStatus.critical:
        return 'Critical Budget Alert';
      case BudgetStatus.warning:
        return 'Budget Warning';
      case BudgetStatus.notice:
        return 'Budget Notice';
      default:
        return 'On Track';
    }
  }

  String _statusMessage(BudgetStatus status) {
    final pct = (usage * 100).toStringAsFixed(0);
    switch (status) {
      case BudgetStatus.exceeded:
        return 'You have used $pct% of your budget.';
      case BudgetStatus.critical:
        return 'You have used $pct% of your budget.';
      case BudgetStatus.warning:
        return 'You have used $pct% of your budget.';
      case BudgetStatus.notice:
        return 'You can do it! $pct% used.';
      default:
        return '';
    }
  }
}

class _PulseIcon extends StatefulWidget {
  final Color color;
  const _PulseIcon({required this.color});
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() {  _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
