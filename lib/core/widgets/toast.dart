import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Custom toast notifications — success and error.
class AppToast {
  /// Show a success toast (green, with checkmark)
  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.success, Icons.check);
  }

  /// Show an error toast (red, with X)
  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.error, Icons.close);
  }

  /// Show a warning toast
  static void warning(BuildContext context, String message) {
    _show(context, message, AppColors.warning, Icons.warning_amber);
  }

  /// Show an info toast (blue, with info icon)
  static void info(BuildContext context, String message) {
    _show(context, message, AppColors.info, Icons.info_outline);
  }

  static void _show(
      BuildContext context, String message, Color color, IconData icon) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) =>
          _ToastWidget(message: message, color: color, icon: icon, onDismiss: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    // Auto-dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _ctrl.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.color,
              boxShadow: AppColors.sharpShadow(isDark),
            ),
            child: Row(children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              GestureDetector(
                onTap: () {
                  _ctrl.reverse().then((_) {
                    if (mounted) widget.onDismiss();
                  });
                },
                child: Icon(Icons.close,
                    color: Colors.white.withValues(alpha: 0.7), size: 18),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
