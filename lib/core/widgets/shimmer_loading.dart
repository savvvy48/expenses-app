import 'package:flutter/material.dart';

/// Shimmer / skeleton loading placeholder.
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final bool isDark;
  final EdgeInsetsGeometry? margin;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    required this.isDark,
    this.margin,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFE5E5E5);
    final highlightColor = widget.isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _ctrl.value, 0),
              end: Alignment(-1.0 + 2.0 * _ctrl.value + 1.0, 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

/// Full skeleton screen for the home view
class HomeSkeletonScreen extends StatelessWidget {
  final bool isDark;
  const HomeSkeletonScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(height: 28, width: 180, isDark: isDark),
          const SizedBox(height: 8),
          ShimmerLoading(height: 18, width: 120, isDark: isDark),
          const SizedBox(height: 16),
          ShimmerLoading(height: 140, isDark: isDark),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ShimmerLoading(height: 70, isDark: isDark)),
            const SizedBox(width: 8),
            Expanded(child: ShimmerLoading(height: 70, isDark: isDark)),
            const SizedBox(width: 8),
            Expanded(child: ShimmerLoading(height: 70, isDark: isDark)),
          ]),
          const SizedBox(height: 20),
          ShimmerLoading(height: 16, width: 120, isDark: isDark),
          const SizedBox(height: 12),
          for (int i = 0; i < 5; i++) ...[
            ShimmerLoading(
                height: 72, isDark: isDark, margin: const EdgeInsets.only(bottom: 8)),
          ],
        ],
      ),
    );
  }
}
