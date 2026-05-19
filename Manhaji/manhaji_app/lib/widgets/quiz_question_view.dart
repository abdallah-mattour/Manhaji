import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/quiz.dart';
import 'question_media_header.dart';

/// Hero card rendering for the currently-active quiz question.
///
/// Visual structure (top to bottom):
///
///   ┌─────────────────────────────────────────────┐
///   │  [🎯 اختر الإجابة]    ←  type pill (top-right) │
///   │                                              │
///   │              [question image]                │
///   │                                              │
///   │     ما عاصمة فلسطين؟       ←  big prompt     │
///   │            [🔊]            ←  speaker chip   │
///   │                                              │
///   │   [💡 احصل على مساعدة]    ←  hint button     │
///   └─────────────────────────────────────────────┘
///
/// The card itself is white with a soft subject-tinted glow shadow so it
/// reads as friendly without being garish. On wrong answer it shakes via
/// the parent-provided `shakeAnimation` and the border briefly tints red.
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

  /// When null the speaker chip is hidden — used by PRONUNCIATION which
  /// renders its own target card with its own speaker.
  final VoidCallback? onSpeak;
  final int maxHintLevel;

  @override
  Widget build(BuildContext context) {
    final typeColor = AppTheme.colorForQuestionType(question.type);

    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(shakeAnimation.value, 0),
          child: child,
        );
      },
      child: AppCard(
        radius: AppTheme.radiusXXL,
        tint: typeColor,
        borderColor: showFeedbackBorder ? borderColor : Colors.transparent,
        borderWidth: showFeedbackBorder ? 2 : 0,
        padding: const EdgeInsets.all(AppTheme.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TypePill(type: question.type, color: typeColor),
            const AppGap.v4(),
            QuestionMediaHeader(
              imageUrl: question.imageUrl,
              audioUrl: question.audioUrl,
            ),
            _Prompt(text: question.questionText, onSpeak: onSpeak),
            if (isRetry) ...const [
              AppGap.v3(),
              _RetryBanner(),
            ],
            if (!isAnswered && !isRetry) ...[
              const AppGap.v4(),
              _HintButton(
                hintLevel: hintLevel,
                maxHintLevel: maxHintLevel,
                isLoading: isLoadingHint,
                onRequest: onRequestHint,
              ),
            ],
            if (currentHint != null) ...[
              const AppGap.v3(),
              _HintBubble(text: currentHint!),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Type pill — emoji + label in the brand color
// ============================================================
class _TypePill extends StatelessWidget {
  final String type;
  final Color color;
  const _TypePill({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    final emoji = AppTheme.emojiForQuestionType(type);
    final label = AppTheme.labelForQuestionType(type);
    return Align(
      alignment: Directionality.of(context) == TextDirection.rtl
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space3,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const AppGap.h2(),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Question prompt with optional inline speaker chip
// ============================================================
class _Prompt extends StatelessWidget {
  final String text;
  final VoidCallback? onSpeak;
  const _Prompt({required this.text, this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final hasSpeaker = onSpeak != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasSpeaker) ...[
          _SpeakerChip(onTap: onSpeak!),
          const AppGap.h3(),
        ],
        Expanded(
          child: Text(
            text,
            textAlign: hasSpeaker ? TextAlign.start : TextAlign.center,
            style: AppTheme.questionPrompt,
          ),
        ),
        if (hasSpeaker)
          // Keep visual balance — invisible mirror of the speaker chip.
          const SizedBox(width: 0),
      ],
    );
  }
}

/// 44dp circle button with a speaker icon. Kept distinct from a generic
/// IconButton because we want a soft brand-blue fill that reads as
/// "tap me — I'll read this".
class _SpeakerChip extends StatelessWidget {
  final VoidCallback onTap;
  const _SpeakerChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.volume_up_rounded,
          color: AppTheme.primaryBlue,
          size: 24,
        ),
      ),
    );
  }
}

// ============================================================
// Retry banner — friendly, encouraging
// ============================================================
class _RetryBanner extends StatelessWidget {
  const _RetryBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        color: AppTheme.warningContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        children: const [
          Text('💪', style: TextStyle(fontSize: 22)),
          AppGap.h3(),
          Expanded(
            child: Text(
              'لا بأس! حاول مرة أخرى',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Hint button — pill button with emoji
// ============================================================
class _HintButton extends StatelessWidget {
  final int hintLevel;
  final int maxHintLevel;
  final bool isLoading;
  final VoidCallback onRequest;

  const _HintButton({
    required this.hintLevel,
    required this.maxHintLevel,
    required this.isLoading,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final exhausted = hintLevel >= maxHintLevel;
    final disabled = exhausted || isLoading;
    return Align(
      alignment: Alignment.center,
      child: InkWell(
        onTap: disabled ? null : onRequest,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space5,
            vertical: AppTheme.space3,
          ),
          decoration: BoxDecoration(
            color: exhausted
                ? AppTheme.surfaceSubtle
                : AppTheme.warningContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: exhausted
                  ? AppTheme.surfaceStrong
                  : AppTheme.warning.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Text('💡', style: TextStyle(fontSize: 18)),
              const AppGap.h2(),
              Text(
                exhausted ? 'لا مزيد من التلميحات' : 'احصل على مساعدة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color:
                      exhausted ? AppTheme.textLight : AppTheme.warning,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Hint bubble — when a hint is revealed
// ============================================================
class _HintBubble extends StatelessWidget {
  final String text;
  const _HintBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppTheme.motionBase,
      curve: AppTheme.motionCurve,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.warningContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: AppTheme.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡', style: TextStyle(fontSize: 22)),
            const AppGap.h3(),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
