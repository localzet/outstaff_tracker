import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppGoalProgressBar extends StatelessWidget {
  const AppGoalProgressBar({
    required this.trackedSeconds,
    required this.targetSeconds,
    this.height = 8,
    super.key,
  });

  final int trackedSeconds;
  final int targetSeconds;
  final double height;

  @override
  Widget build(BuildContext context) {
    final target = math.max(1, targetSeconds);
    final normalRatio = (trackedSeconds / target).clamp(0, 1).toDouble();
    final overworkSeconds = math.max(0, trackedSeconds - target);
    final warningRatio = overworkSeconds <= target
        ? (overworkSeconds / target).clamp(0, 1).toDouble()
        : 1.0;
    final dangerRatio = overworkSeconds > target
        ? ((overworkSeconds - target) / target).clamp(0, 1).toDouble()
        : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: AppColors.surfaceElevated),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: constraints.maxWidth * normalRatio,
                  child: const ColoredBox(color: AppColors.accent),
                ),
                if (warningRatio > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * warningRatio,
                    child: const ColoredBox(color: AppColors.warning),
                  ),
                if (dangerRatio > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * dangerRatio,
                    child: const ColoredBox(color: AppColors.danger),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
