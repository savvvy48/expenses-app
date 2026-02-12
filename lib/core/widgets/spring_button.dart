import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A button with spring-scale physics, ripple effect, and haptic feedback.
class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final bool enableHaptic;

  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
    this.enableHaptic = true,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 300),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleFactor)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();

  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    if (widget.enableHaptic) HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
