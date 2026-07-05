import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../constants/strings.dart';
import 'mascot.dart';

/// A centered error display with optional retry button.
///
/// Replaces the ad-hoc `Column` + error-icon + `ElevatedButton` pattern that
/// was duplicated across dashboard/progress/teacher/admin screens.
///
/// Now uses Hakeem (sad pose) instead of a generic error icon — the empty
/// state feels like the mascot is consoling the kid rather than the app
/// shouting "ERROR".
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = AppStrings.actionRetry,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(mood: MascotMood.sad, size: 140),
            const AppGap.v4(),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const AppGap.v5(),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(retryLabel),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusPill),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
