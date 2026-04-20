import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';

/// Card rendering for an active quiz question.
///
/// Extracted from `learning_screen.dart`'s `_buildQuestionCard` so the screen
/// can focus on flow/animation orchestration. Handles the type badge, question
/// text, retry banner, hint button, and hint content.
class QuizQuestionView extends StatelessWidget {
  const QuizQuestionView({
    super.key,
    required this.question,
    required this.isRetry,
    required this.showFeedbackBorder,
    required this.borderColor,
    required this.isAnswered,
    required this.shakeAnimation,
    required this.hintLevel,
    required this.currentHint,
    required this.isLoadingHint,
    required this.onRequestHint,
    this.onSpeak,
    this.maxHintLevel = 3,
  });

  final Question question;
  final bool isRetry;
  final bool showFeedbackBorder;
  final Color borderColor;
  final bool isAnswered;
  final Animation<double> shakeAnimation;
  final int hintLevel;
  final String? currentHint;
  final bool isLoadingHint;
  final VoidCallback onRequestHint;
  /// Reads the question text aloud. When null the speaker icon is hidden —
  /// pronunciation widgets render their own target card with its own speaker.
  final VoidCallback? onSpeak;
  final int maxHintLevel;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: showFeedbackBorder ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Question type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _typeColor(question.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _typeLabel(question.type),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _typeColor(question.type),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Question text (+ optional speaker button so young learners who
            // can't read yet can tap to hear the prompt).
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (onSpeak != null)
                  IconButton(
                    onPressed: onSpeak,
                    icon: const Icon(Icons.volume_up_rounded,
                        size: 28, color: AppTheme.primaryBlue),
                    tooltip: 'استمع للسؤال',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  )
                else
                  const SizedBox(width: 36),
                Expanded(
                  child: Text(
                    question.questionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                      height: 1.6,
                    ),
                  ),
                ),
                // Spacer to keep the text visually centered when the speaker is on.
                const SizedBox(width: 36),
              ],
            ),
            // Retry banner
            if (isRetry)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'لا بأس! حاول مرة أخرى 💪',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            // Hint section
            if (!isAnswered && !isRetry) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: isLoadingHint ? null : onRequestHint,
                icon: isLoadingHint
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('💡', style: TextStyle(fontSize: 18)),
                label: Text(
                  hintLevel >= maxHintLevel
                      ? 'لا مزيد من التلميحات'
                      : 'مساعدة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: hintLevel >= maxHintLevel
                        ? AppTheme.textLight
                        : AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
            if (currentHint != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentHint!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'MCQ':
        return AppTheme.primaryBlue;
      case 'TRUE_FALSE':
        return AppTheme.primaryPurple;
      case 'SHORT_ANSWER':
        return AppTheme.primaryOrange;
      case 'FILL_BLANK':
        return const Color(0xFF00897B);
      case 'ORDERING':
        return const Color(0xFF7B1FA2);
      default:
        return AppTheme.primaryGreen;
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'MCQ':
        return 'اختيار من متعدد';
      case 'TRUE_FALSE':
        return 'صح أو خطأ';
      case 'SHORT_ANSWER':
        return 'إجابة قصيرة';
      case 'FILL_BLANK':
        return 'أكمل الفراغ';
      case 'ORDERING':
        return 'رتّب العناصر';
      default:
        return '';
    }
  }
}
