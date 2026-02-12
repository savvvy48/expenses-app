import 'package:flutter/material.dart';

/// Card with hover/press lift effect — scales up slightly and adds shadow.
class HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BoxDecoration? decoration;

  const HoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.decoration,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _elevation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.02)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _elevation = Tween<double>(begin: 0.0, end: 8.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              decoration: (widget.decoration ?? const BoxDecoration()).copyWith(
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.08),
                    offset: Offset(2 + _elevation.value / 2, 2 + _elevation.value / 2),
                    blurRadius: _elevation.value,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
