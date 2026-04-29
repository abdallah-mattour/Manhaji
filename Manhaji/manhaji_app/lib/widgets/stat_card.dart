import 'package:flutter/material.dart';
import '../app/theme.dart';

/// A small tinted card showing a single statistic (points, streak, score, etc.).
///
/// Replaces three near-duplicate `_buildStatCard` helpers that used to live in
/// `progress_screen.dart`, `home_screen.dart`, and `learning_completion_screen.dart`.
/// The visual differences across those sites (emoji vs icon, padding, font size)
/// are exposed as optional parameters so each caller keeps its original look.
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
    this.borderRadius = 16,
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
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          if (emoji != null)
            Text(emoji!, style: TextStyle(fontSize: emojiSize))
          else
            Icon(icon, color: color, size: iconSize),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: labelFontSize,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );

    return expanded ? Expanded(child: content) : content;
  }
}
