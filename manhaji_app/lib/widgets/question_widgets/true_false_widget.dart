import 'package:flutter/material.dart';
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
          child: _buildButton('صح', Icons.check_circle_outline, Colors.green),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildButton('خطأ', Icons.cancel_outlined, Colors.red),
        ),
      ],
    );
  }

  Widget _buildButton(String value, IconData icon, Color color) {
    final isSelected = selectedAnswer == value;
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE0E0E0);

    if (isAnswered) {
      if (value == correctAnswer) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      bgColor = color.withValues(alpha: 0.1);
      borderColor = color;
    }

    return GestureDetector(
      onTap: isAnswered ? null : () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? color : AppTheme.textLight),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
