import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:badminton_ai/core/design_system/design_system.dart';

/// Full-screen elegant loading overlay
class LoadingSpinner extends StatefulWidget {
  final String message;
  const LoadingSpinner({super.key, this.message = 'Đang tải...'});

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo ──
            Image.asset(
              'assets/images/logo1.png',
              width: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),

            // ── Custom arc spinner ──
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return CustomPaint(
                  size: const Size(56, 56),
                  painter: _ArcSpinnerPainter(
                    progress: _ctrl.value,
                    color: VColors.brandPrimary,
                    trackColor: VColors.brandPrimary.withValues(alpha: 0.12),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // ── Text ──
            Text(
              widget.message,
              style: const TextStyle(
                color: VColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vẽ arc spinner (vòng tròn với đuôi mờ dần)
class _ArcSpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _ArcSpinnerPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final strokeWidth = 4.5;

    // Track (vòng nền)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Arc xoay
    final paintArc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [color.withValues(alpha: 0.0), color.withValues(alpha: 0.6), color],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(math.pi * 2 * progress),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 2 * progress - math.pi / 2,
      math.pi * 1.5,
      false,
      paintArc,
    );
  }

  @override
  bool shouldRepaint(_ArcSpinnerPainter old) => old.progress != progress;
}
