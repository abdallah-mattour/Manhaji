import 'package:flutter/material.dart';
import '../app/theme.dart';

class DuolingoButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final Color color;
  final Color? shadowColor;
  final double? width;
  final double height;
  final double borderRadius;
  final double depth;

  const DuolingoButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.color = AppTheme.primaryTerracotta,
    this.shadowColor,
    this.width,
    this.height = 56,
    this.borderRadius = AppTheme.radiusL,
    this.depth = AppTheme.buttonDepth,
  }) : assert(text != null || child != null);

  @override
  State<DuolingoButton> createState() => _DuolingoButtonState();
}

class _DuolingoButtonState extends State<DuolingoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveShadowColor = widget.shadowColor ?? _getDarkerColor(widget.color);
    final isEnabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onPressed,
      child: SizedBox(
        width: widget.width,
        height: widget.height + widget.depth,
        child: Stack(
          children: [
            // Shadow layer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: isEnabled ? effectiveShadowColor : AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
              ),
            ),
            // Top layer
            AnimatedPositioned(
              duration: AppTheme.motionInstant,
              top: _isPressed ? widget.depth : 0,
              left: 0,
              right: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: isEnabled ? widget.color : AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: widget.text != null
                      ? Text(
                          widget.text!,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isEnabled ? Colors.white : AppTheme.textLight,
                          ),
                        )
                      : widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDarkerColor(Color color) {
    // Basic heuristic to get a deeper shade for the shadow
    if (color == AppTheme.primaryTerracotta) return AppTheme.primaryTerracottaDeep;
    if (color == AppTheme.primaryGreen) return AppTheme.primaryGreenDeep;
    if (color == AppTheme.primaryBlue) return AppTheme.primaryBlueDeep;
    if (color == AppTheme.primaryYellow) return AppTheme.primaryYellowDeep;
    if (color == AppTheme.primaryOrange) return AppTheme.primaryOrangeDeep;
    if (color == AppTheme.primaryRed) return AppTheme.primaryRedDeep;
    
    // Fallback: darken slightly
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }
}
