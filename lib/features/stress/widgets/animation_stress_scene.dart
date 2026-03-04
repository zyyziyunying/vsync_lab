import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class AnimationStressScene extends StatefulWidget {
  const AnimationStressScene({
    required this.particleCount,
    required this.workloadLevel,
    required this.colorShift,
    super.key,
  });

  final int particleCount;
  final int workloadLevel;
  final bool colorShift;

  @override
  State<AnimationStressScene> createState() => _AnimationStressSceneState();
}

class _AnimationStressSceneState extends State<AnimationStressScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _OrbitPainter(
              progress: _controller.value,
              particleCount: widget.particleCount,
              workloadLevel: widget.workloadLevel,
              colorShift: widget.colorShift,
            ),
            child: child,
          );
        },
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.progress,
    required this.particleCount,
    required this.workloadLevel,
    required this.colorShift,
  });

  final double progress;
  final int particleCount;
  final int workloadLevel;
  final bool colorShift;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0F172A),
    );

    final center = size.center(Offset.zero);
    final maxRadius = math.min(size.width, size.height).toDouble() / 2;
    final particlePaint = Paint()..style = PaintingStyle.fill;

    var sink = 0.0;
    for (var index = 0; index < particleCount; index++) {
      final ratio = index / particleCount;
      final angle =
          progress * 2 * math.pi * workloadLevel + ratio * 10 * math.pi;
      final radius = maxRadius * (0.2 + ratio * 0.8);
      final dx = center.dx + math.cos(angle) * radius;
      final dy = center.dy + math.sin(angle) * radius;

      final hue = colorShift ? (ratio * 360 + progress * 360) % 360 : 210.0;
      particlePaint.color = HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor();
      canvas.drawCircle(Offset(dx, dy), 2 + ratio * 2, particlePaint);

      for (var spin = 0; spin < workloadLevel * 24; spin++) {
        sink += math.sin(angle + spin) * math.cos(ratio + spin * 0.1);
      }
    }

    if (sink > 999999999) {
      canvas.drawPoints(
          ui.PointMode.points, const [Offset.zero], particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        particleCount != oldDelegate.particleCount ||
        workloadLevel != oldDelegate.workloadLevel ||
        colorShift != oldDelegate.colorShift;
  }
}
