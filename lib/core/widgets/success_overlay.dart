
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Full-screen overlay showing an animated checkmark on success.
class SuccessOverlay {
  static Future<void> show(BuildContext context, {String? message}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, a1, a2) => _SuccessContent(message: message),
    );
  }
}

class _SuccessContent extends StatefulWidget {
  final String? message;
  const _SuccessContent({this.message});
  @override
  State<_SuccessContent> createState() => _SuccessContentState();
}

class _SuccessContentState extends State<_SuccessContent>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _checkCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);

    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _checkCtrl.forward();
    });
    // Auto-dismiss
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            boxShadow: AppColors.softShadow(isDark),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _checkCtrl,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(48, 48),
                    painter: _CheckPainter(_checkCtrl.value),
                  );
                },
              ),
              if (widget.message != null) ...[
                const SizedBox(height: 8),
                Text(widget.message!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;

    final path = Path();
    // Checkmark path: two lines
    final p1 = Offset(size.width * 0.2, size.height * 0.5);
    final p2 = Offset(size.width * 0.4, size.height * 0.7);
    final p3 = Offset(size.width * 0.8, size.height * 0.3);

    if (progress <= 0.5) {
      // First stroke
      final t = progress / 0.5;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(
          p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      // Full first stroke + second stroke
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      final t = (progress - 0.5) / 0.5;
      path.lineTo(
          p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
