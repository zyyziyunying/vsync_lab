import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class ScrollStressScene extends StatelessWidget {
  const ScrollStressScene({
    required this.controller,
    required this.itemCount,
    required this.enableBlur,
    super.key,
  });

  final ScrollController controller;
  final int itemCount;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ListView.builder(
        controller: controller,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final tile = _StressTile(index: index);
          if (!enableBlur || index.isOdd) {
            return tile;
          }
          return ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
            child: tile,
          );
        },
      ),
    );
  }
}

class _StressTile extends StatelessWidget {
  const _StressTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colorA = Colors.primaries[index % Colors.primaries.length];
    final colorB = Colors.primaries[(index + 5) % Colors.primaries.length];

    final syntheticScore = _syntheticScore(index);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorA.shade400, colorB.shade400],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text('${index % 99}'.padLeft(2, '0')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Synthetic feed item #$index',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Derived stress score: ${syntheticScore.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }

  double _syntheticScore(int seed) {
    var score = 0.0;
    for (var index = 0; index < 32; index++) {
      score += math.sin(seed * (index + 1)) * math.cos(seed + index * 0.5);
    }
    return score.abs();
  }
}
