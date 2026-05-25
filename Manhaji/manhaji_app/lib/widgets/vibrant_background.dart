import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

enum BackgroundPattern { dots, wavy, shapes, none }

class VibrantBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final BackgroundPattern pattern;
  final Color? patternColor;
  final bool animate;

  const VibrantBackground({
    super.key,
    required this.child,
    this.backgroundColor = AppTheme.backgroundLight,
    this.pattern = BackgroundPattern.shapes,
    this.patternColor,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Solid background color
        Container(color: backgroundColor),
        
        // Pattern layer
        if (pattern != BackgroundPattern.none)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: _PatternPainter(
                  pattern: pattern,
                  color: patternColor ?? AppTheme.textLight,
                ),
              ),
            ),
          ),
          
        // Foreground content
        child,
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  final BackgroundPattern pattern;
  final Color color;

  _PatternPainter({required this.pattern, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent pattern

    if (pattern == BackgroundPattern.dots) {
      for (int i = 0; i < 100; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        canvas.drawCircle(Offset(x, y), 2 + random.nextDouble() * 2, paint);
      }
    } else if (pattern == BackgroundPattern.shapes) {
      for (int i = 0; i < 40; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final s = 10 + random.nextDouble() * 20;
        
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(random.nextDouble() * math.pi);
        
        if (i % 3 == 0) {
          // Triangle
          final path = Path();
          path.moveTo(0, -s/2);
          path.lineTo(s/2, s/2);
          path.lineTo(-s/2, s/2);
          path.close();
          canvas.drawPath(path, paint);
        } else if (i % 3 == 1) {
          // Circle
          canvas.drawCircle(Offset.zero, s/2, paint);
        } else {
          // Square
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s, height: s), paint);
        }
        canvas.restore();
      }
    } else if (pattern == BackgroundPattern.wavy) {
      final wavePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
        
      for (int i = 0; i < 10; i++) {
        final y = (size.height / 10) * i + 20;
        final path = Path();
        path.moveTo(0, y);
        for (double x = 0; x <= size.width; x += 20) {
          path.relativeQuadraticBezierTo(10, (i % 2 == 0 ? 10 : -10), 20, 0);
        }
        canvas.drawPath(path, wavePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
