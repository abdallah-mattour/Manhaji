import 'package:flutter/material.dart';
import '../app/theme.dart';

class DuolingoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double depth;
  final VoidCallback? onTap;

  const DuolingoCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = AppTheme.radiusL,
    this.backgroundColor = AppTheme.cardWhite,
    this.borderColor = AppTheme.surfaceMuted,
    this.borderWidth = 2.0,
    this.depth = 2.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: depth),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: Offset(0, depth),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppTheme.space4),
          child: child,
        ),
      ),
    );
  }
}
