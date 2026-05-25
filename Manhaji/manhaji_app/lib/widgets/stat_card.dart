import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'duolingo_card.dart';

/// A small tinted card showing a single statistic (points, streak, score, etc.).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    this.emoji,
    this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.expanded = true,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    this.emojiSize = 24,
    this.iconSize = 28,
    this.valueFontSize = 20,
    this.labelFontSize = 12,
    this.borderRadius = AppTheme.radiusL,
  }) : assert(emoji != null || icon != null,
            'StatCard requires either an emoji or an icon');

  final String? emoji;
  final IconData? icon;
  final String value;
  final String label;
  final Color color;
  final bool expanded;
  final EdgeInsetsGeometry padding;
  final double emojiSize;
  final double iconSize;
  final double valueFontSize;
  final double labelFontSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final content = DuolingoCard(
      padding: padding,
      backgroundColor: AppTheme.cardWhite,
      borderColor: color,
      borderRadius: borderRadius,
      depth: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null)
            Text(emoji!, style: TextStyle(fontSize: emojiSize))
          else
            Icon(icon, color: color, size: iconSize),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: valueFontSize,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: labelFontSize,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );

    return expanded ? Expanded(child: content) : content;
  }
}
