import 'dart:math';
import 'package:flutter/material.dart';

/// Wraps a child and shakes it horizontally when [shake()] is called.
class ShakeWidget extends StatefulWidget {
  final Widget child;
  const ShakeWidget({super.key, required this.child});

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Call this to trigger the shake animation.
  void shake() {
    _ctrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final sineVal =
            sin(4 * 2 * pi * _ctrl.value) * (1 - _ctrl.value) * 10;
        return Transform.translate(
          offset: Offset(sineVal, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
