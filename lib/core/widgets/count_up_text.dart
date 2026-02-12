import 'package:flutter/material.dart';

/// Animates a number counting up from 0 (or a start value) to an end value.
class CountUpText extends StatefulWidget {
  final double end;
  final double begin;
  final Duration duration;
  final String prefix;
  final String suffix;
  final int decimals;
  final TextStyle? style;

  const CountUpText({
    super.key,
    required this.end,
    this.begin = 0,
    this.duration = const Duration(milliseconds: 800),
    this.prefix = '',
    this.suffix = '',
    this.decimals = 2,
    this.style,
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: widget.begin, end: widget.end)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(CountUpText old) {
    super.didUpdateWidget(old);
    if (old.end != widget.end) {
      _animation = Tween<double>(begin: old.end, end: widget.end)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${widget.prefix}${_animation.value.toStringAsFixed(widget.decimals)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
