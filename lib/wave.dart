import 'dart:math';
import 'package:flutter/material.dart';

class WaveCircle extends StatefulWidget {
  final double size;
  final double speed;
  final double amplitude;
  final int rings;
  final Color color;

  const WaveCircle({
    Key? key,
    this.size = 100,
    this.speed = 0.4,
    this.amplitude = 8,
    this.rings = 1,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  State<WaveCircle> createState() => _WaveCircleState();
}

class _WaveCircleState extends State<WaveCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (5000 ~/ widget.speed)),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _WavePainter(
              progress: _controller.value,
              amplitude: widget.amplitude,
              rings: widget.rings,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final double amplitude;
  final int rings;
  final Color color;

  _WavePainter({
    required this.progress,
    required this.amplitude,
    required this.rings,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    // 🔹 Anillo blanco fijo central
    final fixedPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(center, baseRadius * 0.7, fixedPaint);

    // 🔹 Anillos animados con glow volumétrico
    for (int i = 0; i < rings; i++) {
      final waveRadius = baseRadius * 0.655 +
          sin(progress * 2 * pi + i * pi / rings) * amplitude;

      for (int glow = 0; glow < 6; glow++) {
        final opacity = (0.03 * (6 - glow)).clamp(0.0, 0.6);
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 + glow * 0.5
          ..color = color.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawCircle(center, waveRadius + glow * 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => true;
}
