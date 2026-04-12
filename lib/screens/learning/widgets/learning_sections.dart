import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/quiz.dart';
import '../../../providers/learning_provider.dart';
import '../../../widgets/star_display_widget.dart';

class LearningLoadingSection extends StatelessWidget {
  final String message;

  const LearningLoadingSection({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class LearningErrorSection extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const LearningErrorSection({
    super.key,
    required this.message,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBack,
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }
}

class LearningTopBarSection extends StatelessWidget {
  final String lessonTitle;
  final int totalStars;
  final VoidCallback onClose;

  const LearningTopBarSection({
    super.key,
    required this.lessonTitle,
    required this.totalStars,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              lessonTitle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          StarDisplayWidget(totalStars: totalStars),
        ],
      ),
    );
  }
}

class LearningQuestionCardSection extends StatelessWidget {
  final Question question;
  final bool isRetry;
  final bool showFeedback;
  final Color borderColor;
  final String? currentHint;
  final int hintLevel;
  final bool isLoadingHint;
  final Color Function(String type) getTypeColor;
  final String Function(String type) getTypeLabel;
  final VoidCallback? onRequestHint;

  const LearningQuestionCardSection({
    super.key,
    required this.question,
    required this.isRetry,
    required this.showFeedback,
    required this.borderColor,
    required this.currentHint,
    required this.hintLevel,
    required this.isLoadingHint,
    required this.getTypeColor,
    required this.getTypeLabel,
    required this.onRequestHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: showFeedback ? 2 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: getTypeColor(question.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              getTypeLabel(question.type),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: getTypeColor(question.type),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          if (isRetry)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'لا بأس! حاول مرة أخرى 💪',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
          if (!showFeedback && !isRetry) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRequestHint,
              icon: isLoadingHint
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('💡', style: TextStyle(fontSize: 18)),
              label: Text(
                hintLevel >= 3 ? 'لا مزيد من التلميحات' : 'مساعدة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: hintLevel >= 3 ? AppColors.textLight : AppColors.accent,
                ),
              ),
            ),
          ],
          if (currentHint != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class LearningFeedbackSection extends StatelessWidget {
  final SubmitAnswerResult result;
  final bool isRetryPrompt;
  final int starsEarned;
  final Animation<double> animation;

  const LearningFeedbackSection({
    super.key,
    required this.result,
    required this.isRetryPrompt,
    required this.starsEarned,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    if (isRetryPrompt) {
      return ScaleTransition(
        scale: animation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
          child: const Row(
            children: [
              Text('💪', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لا بأس! حاول مرة أخرى',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: animation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: result.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: result.isCorrect ? Colors.green : Colors.red,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              result.isCorrect ? '🎉' : '😔',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.isCorrect ? 'أحسنت! ممتاز!' : 'الإجابة الصحيحة:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: result.isCorrect
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  if (!result.isCorrect)
                    Text(
                      result.correctAnswer,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  if (result.isCorrect)
                    Text(
                      '+$starsEarned ⭐',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
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
}

class LearningActionButtonSection extends StatelessWidget {
  final LearningPhase phase;
  final bool canSubmit;
  final bool isLastMainStep;
  final bool isInRetryRound;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const LearningActionButtonSection({
    super.key,
    required this.phase,
    required this.canSubmit,
    required this.isLastMainStep,
    required this.isInRetryRound,
    required this.onRetry,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (phase == LearningPhase.stepRetry) {
      return ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'حاول مرة أخرى 💪',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      );
    }

    if (phase == LearningPhase.stepFeedback) {
      final isLast = isInRetryRound ? false : isLastMainStep;

      return ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLast ? AppColors.primary : AppColors.secondary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'التالي ←',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: canSubmit ? onSubmit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        'تأكيد الإجابة',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
