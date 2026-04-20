import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

class TrueFalseWidget extends StatelessWidget {
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const TrueFalseWidget({
    super.key,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    this.correctAnswer,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TfButton(
            value: 'صح',
            icon: Icons.check_circle_outline,
            accentColor: AppTheme.primaryGreen,
            isSelected: selectedAnswer == 'صح',
            isAnswered: isAnswered,
            isCorrect: isCorrect,
            correctAnswer: correctAnswer,
            onSelect: onSelect,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TfButton(
            value: 'خطأ',
            icon: Icons.cancel_outlined,
            accentColor: AppTheme.primaryRed,
            isSelected: selectedAnswer == 'خطأ',
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

class _TfButton extends StatefulWidget {
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const _TfButton({
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onSelect,
  });

  @override
  State<_TfButton> createState() => _TfButtonState();
}

class _TfButtonState extends State<_TfButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE0E0E0);

    if (widget.isAnswered) {
      if (widget.value == widget.correctAnswer) {
        bgColor = AppTheme.primaryGreen.withValues(alpha: 0.12);
        borderColor = AppTheme.primaryGreen;
      } else if (widget.isSelected && !widget.isCorrect) {
        bgColor = AppTheme.primaryRed.withValues(alpha: 0.12);
        borderColor = AppTheme.primaryRed;
      }
    } else if (widget.isSelected) {
      bgColor = widget.accentColor.withValues(alpha: 0.1);
      borderColor = widget.accentColor;
    }

    return GestureDetector(
      onTapDown: widget.isAnswered ? null : (_) => setState(() => _pressed = true),
      onTapCancel: widget.isAnswered ? null : () => setState(() => _pressed = false),
      onTapUp: widget.isAnswered ? null : (_) => setState(() => _pressed = false),
      onTap: widget.isAnswered
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onSelect(widget.value);
            },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            children: [
              Icon(
                widget.icon,
                size: 40,
                color: widget.isSelected ? widget.accentColor : AppTheme.textLight,
              ),
              const SizedBox(height: 8),
              Text(
                widget.value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.isSelected ? widget.accentColor : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
