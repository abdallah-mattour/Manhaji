import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';
import '../../utils/text_direction.dart';
import 'option_image.dart';

/// LISTEN_CHOOSE — the question is heard, not read. A big pulsing speaker plays
/// the prompt audio (auto-played once on entry, replayable on tap), and the
/// child picks the option that matches what they heard. Options may carry
/// pictures (via `optionImages`) or just text.
///
/// Scoring is identical to MCQ (same `onSelect`/selection contract), so the
/// `learning_screen` wires it like MCQ. Audio playback is delegated to the
/// parent via `onReplay` (which uses the app's TTS/audio service).
class ListenChooseWidget extends StatefulWidget {
  final Question question;
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;
  final VoidCallback onReplay;

  /// Full English experience (2026-07-03).
  final bool english;

  const ListenChooseWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    this.correctAnswer,
    required this.onSelect,
    required this.onReplay,
    this.english = false,
  });

  @override
  State<ListenChooseWidget> createState() => _ListenChooseWidgetState();
}

class _ListenChooseWidgetState extends State<ListenChooseWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.96,
    upperBound: 1.06,
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    // Auto-play once on entry so the child hears the prompt immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReplay();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options ?? const <String>[];
    final images = widget.question.optionImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Big tappable speaker.
        GestureDetector(
          onTap: widget.onReplay,
          child: ScaleTransition(
            scale: _pulse,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlueDeep.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 56),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.english ? 'Tap to listen again' : 'اضغط للاستماع مرة أخرى',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textGray,
          ),
        ),
        const SizedBox(height: 20),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ListenOption(
              label: option,
              imagePath: () {
                final i = options.indexOf(option);
                return (images != null && i < images.length) ? images[i] : null;
              }(),
              isSelected: widget.selectedAnswer == option,
              isAnswered: widget.isAnswered,
              isCorrect: widget.isCorrect,
              isCorrectAnswer: option == widget.correctAnswer,
              onSelect: () => widget.onSelect(option),
            ),
          ),
      ],
    );
  }
}

class _ListenOption extends StatelessWidget {
  final String label;
  final String? imagePath;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final bool isCorrectAnswer;
  final VoidCallback onSelect;

  const _ListenOption({
    required this.label,
    required this.imagePath,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.isCorrectAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppTheme.cardWhite;
    Color border = AppTheme.surfaceMuted;
    Color text = AppTheme.textDark;

    if (isAnswered) {
      if (isCorrectAnswer) {
        bg = AppTheme.successContainer;
        border = AppTheme.primaryGreen;
        text = AppTheme.primaryGreenDeep;
      } else if (isSelected && !isCorrect) {
        bg = AppTheme.errorContainer;
        border = AppTheme.primaryRed;
        text = AppTheme.primaryRedDeep;
      } else {
        bg = AppTheme.surfaceSubtle;
        text = AppTheme.textLight;
      }
    } else if (isSelected) {
      bg = AppTheme.infoContainer;
      border = AppTheme.primaryBlue;
      text = AppTheme.primaryBlueDeep;
    }

    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;

    return GestureDetector(
      onTap: isAnswered ? null : onSelect,
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: border, width: 3),
          boxShadow: [BoxShadow(color: border, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            if (hasImage) ...[
              OptionImage(path: imagePath, size: 48),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                textDirection: directionOf(label),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: text,
                ),
              ),
            ),
            if (isAnswered && isCorrectAnswer)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primaryGreen, size: 24)
            else if (isAnswered && isSelected && !isCorrect)
              const Icon(Icons.cancel_rounded,
                  color: AppTheme.primaryRed, size: 24),
          ],
        ),
      ),
    );
  }
}
