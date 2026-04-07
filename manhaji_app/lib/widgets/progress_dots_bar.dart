import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/learning_step.dart';

class ProgressDotsBar extends StatelessWidget {
  final List<LearningStep> steps;
  final int currentIndex;
  final bool isRetryRound;

  const ProgressDotsBar({
    super.key,
    required this.steps,
    required this.currentIndex,
    this.isRetryRound = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isRetryRound) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔄', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text(
                'جولة المراجعة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(steps.length, (i) {
            final step = steps[i];
            final isCompleted = i < currentIndex;
            final isCurrent = i == currentIndex;
            final isTeaching = step.isTeaching;

            final size = isTeaching ? 8.0 : 14.0;

            Color color;
            if (isCompleted) {
              color = AppTheme.primaryGreen;
            } else if (isCurrent) {
              color = AppTheme.primaryOrange;
            } else {
              color = Colors.grey.shade300;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? size + 4 : size,
                height: isCurrent ? size + 4 : size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
