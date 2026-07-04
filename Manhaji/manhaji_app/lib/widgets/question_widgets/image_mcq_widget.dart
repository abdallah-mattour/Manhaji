import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';
import '../../utils/text_direction.dart';
import 'option_image.dart';

/// IMAGE_MCQ — multiple-choice where each option is a picture (with text
/// underneath). Best for early-grade pre-readers. Scoring is identical to MCQ
/// (the picture is just a presentation layer over the same option text), so it
/// shares the exact callback contract `McqWidget` uses — `learning_screen`
/// wires it the same way.
///
/// Image-ready with fallback: when a given `optionImages` entry is null/empty
/// the tile shows just the option text, so the question still works before
/// images ship.
class ImageMcqWidget extends StatefulWidget {
  final Question question;
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const ImageMcqWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    this.correctAnswer,
    required this.onSelect,
  });

  @override
  State<ImageMcqWidget> createState() => _ImageMcqWidgetState();
}

class _ImageMcqWidgetState extends State<ImageMcqWidget> {
  String? _pressed;

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options ?? const <String>[];
    final images = widget.question.optionImages;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: options.length,
      itemBuilder: (context, i) {
        final option = options[i];
        final imagePath =
            (images != null && i < images.length) ? images[i] : null;
        return _ImageOptionTile(
          label: option,
          imagePath: imagePath,
          isSelected: widget.selectedAnswer == option,
          isAnswered: widget.isAnswered,
          isCorrect: widget.isCorrect,
          isCorrectAnswer: option == widget.correctAnswer,
          pressed: _pressed == option,
          onTapDown: () => setState(() => _pressed = option),
          onTapEnd: () => setState(() => _pressed = null),
          onSelect: () => widget.onSelect(option),
        );
      },
    );
  }
}

class _ImageOptionTile extends StatelessWidget {
  final String label;
  final String? imagePath;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final bool isCorrectAnswer;
  final bool pressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapEnd;
  final VoidCallback onSelect;

  const _ImageOptionTile({
    required this.label,
    required this.imagePath,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.isCorrectAnswer,
    required this.pressed,
    required this.onTapDown,
    required this.onTapEnd,
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
        border = AppTheme.surfaceMuted;
        text = AppTheme.textLight;
      }
    } else if (isSelected) {
      bg = AppTheme.infoContainer;
      border = AppTheme.primaryBlue;
      text = AppTheme.primaryBlueDeep;
    }

    final enabled = !isAnswered;

    return GestureDetector(
      onTap: enabled ? onSelect : null,
      onTapDown: enabled ? (_) => onTapDown() : null,
      onTapUp: enabled ? (_) => onTapEnd() : null,
      onTapCancel: enabled ? onTapEnd : null,
      child: AnimatedScale(
        scale: pressed ? 0.97 : 1.0,
        duration: AppTheme.motionInstant,
        curve: AppTheme.motionCurve,
        child: AnimatedContainer(
          duration: AppTheme.motionFast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(color: border, width: 3),
            boxShadow: [
              BoxShadow(color: border, offset: Offset(0, pressed ? 1 : 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OptionImage(path: imagePath, size: 84),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      textDirection: directionOf(label),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: text,
                      ),
                    ),
                  ),
                  if (isAnswered && isCorrectAnswer) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.primaryGreen, size: 20),
                  ] else if (isAnswered && isSelected && !isCorrect) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.cancel_rounded,
                        color: AppTheme.primaryRed, size: 20),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
