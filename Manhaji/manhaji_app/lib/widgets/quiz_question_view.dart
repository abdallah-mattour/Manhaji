import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/quiz.dart';
import '../utils/text_direction.dart';
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
///
/// Palestinian Playful edition: an eight-pointed star (Levantine tilework
/// motif) sits at the top corner as a subtle brand accent, and the card
/// enters with a spring bounce so the moment of "new question" reads as
/// energetic without being noisy.
class QuizQuestionView extends StatefulWidget {
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
    this.english = false,
  });

  /// Full English experience (2026-07-03): chrome (type pill, hint button,
  /// retry banner, media labels) in English inside English-subject lessons.
  final bool english;

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
  State<QuizQuestionView> createState() => _QuizQuestionViewState();
}

class _QuizQuestionViewState extends State<QuizQuestionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.elasticOut),
    );
    _opacity = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _entrance.forward();
  }

  @override
  void didUpdateWidget(covariant QuizQuestionView old) {
    super.didUpdateWidget(old);
    // Re-bounce when the question identity changes — gives every "new
    // question" its own little entrance moment instead of static swaps.
    if (old.question.id != widget.question.id) {
      _entrance.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = AppTheme.colorForQuestionType(widget.question.type);
    // Avoid two "listen" controls: when the question carries its own authored
    // audio clip, QuestionMediaHeader already renders a "Listen"/"استمع" button,
    // so we suppress the TTS speaker chip on the prompt (it would be a second,
    // redundant audio button — the double-button seen in English lessons).
    final hasAudioClip = (widget.question.audioUrl ?? '').isNotEmpty;

    final card = AnimatedBuilder(
      animation: widget.shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.shakeAnimation.value, 0),
          child: child,
        );
      },
      child: AppCard(
        radius: AppTheme.radiusXXL,
        tint: typeColor,
        borderColor: widget.showFeedbackBorder
            ? widget.borderColor
            : AppTheme.surfaceMuted,
        borderWidth: 3,
        padding: const EdgeInsets.fromLTRB(
            AppTheme.space5, AppTheme.space6, AppTheme.space5, AppTheme.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TypePill(
                type: widget.question.type,
                color: typeColor,
                english: widget.english),
            const AppGap.v4(),
            QuestionMediaHeader(
              imageUrl: widget.question.imageUrl,
              audioUrl: widget.question.audioUrl,
              english: widget.english,
            ),
            _Prompt(
              text: widget.question.questionText,
              onSpeak: hasAudioClip ? null : widget.onSpeak,
            ),
            if (widget.isRetry) ...[
              const AppGap.v3(),
              _RetryBanner(english: widget.english),
            ],
            if (!widget.isAnswered && !widget.isRetry) ...[
              const AppGap.v4(),
              _HintButton(
                hintLevel: widget.hintLevel,
                maxHintLevel: widget.maxHintLevel,
                isLoading: widget.isLoadingHint,
                onRequest: widget.onRequestHint,
                english: widget.english,
              ),
            ],
            if (widget.currentHint != null) ...[
              const AppGap.v3(),
              _HintBubble(text: widget.currentHint!),
            ],
          ],
        ),
      ),
    );

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: card),
    );
  }
}

// ============================================================
// Type pill — emoji + label in the brand color
// ============================================================
class _TypePill extends StatelessWidget {
  final String type;
  final Color color;
  final bool english;
  const _TypePill(
      {required this.type, required this.color, this.english = false});

  @override
  Widget build(BuildContext context) {
    final emoji = AppTheme.emojiForQuestionType(type);
    final label = AppTheme.labelForQuestionType(type, english: english);
    return Align(
      alignment: Directionality.of(context) == TextDirection.rtl
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
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
            // Direction from the question's own script so English prompts
            // flow LTR (trailing "?" on the right) even under the app's
            // ambient RTL. Arabic prompts stay RTL.
            textDirection: directionOf(text),
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
  final bool english;
  const _RetryBanner({this.english = false});

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
        children: [
          const Text('💪', style: TextStyle(fontSize: 22)),
          const AppGap.h3(),
          Expanded(
            child: Text(
              english ? "It's okay! Try again" : 'لا بأس! حاول مرة أخرى',
              style: const TextStyle(
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
  final bool english;

  const _HintButton({
    required this.hintLevel,
    required this.maxHintLevel,
    required this.isLoading,
    required this.onRequest,
    this.english = false,
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
                exhausted
                    ? (english ? 'No more hints' : 'لا مزيد من التلميحات')
                    : (english ? 'Get a hint' : 'احصل على مساعدة'),
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
