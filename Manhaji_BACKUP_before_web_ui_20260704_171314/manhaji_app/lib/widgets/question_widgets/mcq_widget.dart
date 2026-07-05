import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';
import '../../utils/text_direction.dart';

class McqWidget extends StatelessWidget {
  final Question question;
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const McqWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    this.correctAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = question.options ?? const <String>[];

    return Column(
      children: [
        for (int i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _McqOption(
              option: options[i],
              isSelected: selectedAnswer == options[i],
              isAnswered: isAnswered,
              isCorrect: isCorrect,
              correctAnswer: correctAnswer,
              onSelect: onSelect,
            ),
          ),
      ],
    );
  }
}

class _McqOption extends StatefulWidget {
  final String option;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const _McqOption({
    required this.option,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onSelect,
  });

  @override
  State<_McqOption> createState() => _McqOptionState();
}

class _McqOptionState extends State<_McqOption> {
  // Sticker-style press "boop" — scales down slightly while held, springs back.
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.cardWhite;
    Color borderColor = AppTheme.surfaceMuted;
    Color textColor = AppTheme.textDark;

    if (widget.isAnswered) {
      if (widget.option == widget.correctAnswer) {
        color = AppTheme.successContainer;
        borderColor = AppTheme.primaryGreen;
        textColor = AppTheme.primaryGreenDeep;
      } else if (widget.isSelected && !widget.isCorrect) {
        color = AppTheme.errorContainer;
        borderColor = AppTheme.primaryRed;
        textColor = AppTheme.primaryRedDeep;
      } else {
        color = AppTheme.surfaceSubtle;
        borderColor = AppTheme.surfaceMuted;
        textColor = AppTheme.textLight;
      }
    } else if (widget.isSelected) {
      color = AppTheme.infoContainer;
      borderColor = AppTheme.primaryBlue;
      textColor = AppTheme.primaryBlueDeep;
    }

    final enabled = !widget.isAnswered;

    return GestureDetector(
      onTap: enabled ? () => widget.onSelect(widget.option) : null,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppTheme.motionInstant,
        curve: AppTheme.motionCurve,
        child: AnimatedContainer(
          duration: AppTheme.motionFast,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: borderColor,
              width: 3,
            ),
            // Hard-offset "sticker" shadow — no blur, sits below the tile and
            // collapses on press for a tactile feel.
            boxShadow: [
              BoxShadow(
                color: borderColor,
                offset: Offset(0, _pressed ? 1 : 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.option,
                  // Per-option direction so English options keep their "?" on
                  // the right under the app's ambient RTL; Arabic stays RTL.
                  textDirection: directionOf(widget.option),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight:
                        widget.isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              if (widget.isAnswered &&
                  (widget.option == widget.correctAnswer ||
                      (widget.isSelected && !widget.isCorrect)))
                Icon(
                  widget.option == widget.correctAnswer
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: borderColor,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
