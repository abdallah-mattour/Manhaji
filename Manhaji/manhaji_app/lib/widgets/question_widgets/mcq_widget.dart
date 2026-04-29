import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';

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
    final options = question.options ?? [];

    return Column(
      children: options
          .map((option) => _McqOption(
                option: option,
                isSelected: selectedAnswer == option,
                isAnswered: isAnswered,
                isCorrect: isCorrect,
                correctAnswer: correctAnswer,
                onSelect: onSelect,
              ))
          .toList(),
    );
  }
}

/// Tap-scaled MCQ option with AppTheme-based colors and RTL-aware Row.
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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE0E0E0);
    IconData? icon;
    Color iconColor = AppTheme.primaryGreen;

    if (widget.isAnswered) {
      if (widget.option == widget.correctAnswer) {
        bgColor = AppTheme.primaryGreen.withValues(alpha: 0.12);
        borderColor = AppTheme.primaryGreen;
        icon = Icons.check_circle;
        iconColor = AppTheme.primaryGreen;
      } else if (widget.isSelected && !widget.isCorrect) {
        bgColor = AppTheme.primaryRed.withValues(alpha: 0.12);
        borderColor = AppTheme.primaryRed;
        icon = Icons.cancel;
        iconColor = AppTheme.primaryRed;
      }
    } else if (widget.isSelected) {
      bgColor = AppTheme.primaryBlue.withValues(alpha: 0.08);
      borderColor = AppTheme.primaryBlue;
    }

    return GestureDetector(
      onTapDown: widget.isAnswered ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget.isAnswered ? null : () => setState(() => _pressed = false),
      onTapUp: widget.isAnswered ? null : (_) => setState(() => _pressed = false),
      onTap: widget.isAnswered
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onSelect(widget.option);
            },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  widget.option,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
