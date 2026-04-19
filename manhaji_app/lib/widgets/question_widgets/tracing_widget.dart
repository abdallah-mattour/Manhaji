import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';

class TracingResult {
  final int score;
  final int stars;
  final String rating;
  final String feedback;

  const TracingResult({
    required this.score,
    required this.stars,
    required this.rating,
    required this.feedback,
  });

  bool get isCorrect => score >= 60;
}

class TracingWidget extends StatefulWidget {
  final Question question;
  final bool isAnswered;
  final TracingResult? lastResult;
  final Future<void> Function(TracingResult result) onComplete;

  const TracingWidget({
    super.key,
    required this.question,
    required this.isAnswered,
    required this.lastResult,
    required this.onComplete,
  });

  @override
  State<TracingWidget> createState() => _TracingWidgetState();
}

class _TracingWidgetState extends State<TracingWidget> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void _onPanStart(DragStartDetails d, Size canvas) {
    if (widget.isAnswered) return;
    setState(() {
      _currentStroke = [d.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (widget.isAnswered) return;
    setState(() {
      _currentStroke.add(d.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails _) {
    if (widget.isAnswered) return;
    if (_currentStroke.length < 3) return;
    setState(() {
      _strokes.add(List.of(_currentStroke));
      _currentStroke = [];
    });
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  Future<void> _submit() async {
    final allPoints = _strokes.expand((s) => s).toList();
    if (allPoints.isEmpty) return;
    final result = _score(allPoints, _strokes.length);
    await widget.onComplete(result);
  }

  TracingResult _score(List<Offset> points, int strokeCount) {
    if (points.length < 5) {
      return const TracingResult(
        score: 20,
        stars: 0,
        rating: 'حاول مرة أخرى',
        feedback: 'ارسم الحرف كاملاً',
      );
    }

    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;
    for (final p in points) {
      minX = min(minX, p.dx);
      maxX = max(maxX, p.dx);
      minY = min(minY, p.dy);
      maxY = max(maxY, p.dy);
    }
    final extent = max(maxX - minX, maxY - minY);

    int score = 60;
    if (extent > 120) score += 15;
    if (extent > 160) score += 10;
    if (points.length > 40) score += 10;
    if (strokeCount == 1 || strokeCount == 2) score += 5;
    score = min(100, score);

    final stars = score >= 90
        ? 3
        : score >= 75
            ? 2
            : score >= 60
                ? 1
                : 0;

    return TracingResult(
      score: score,
      stars: stars,
      rating: stars == 3
          ? 'ممتاز'
          : stars == 2
              ? 'جيد جداً'
              : stars == 1
                  ? 'جيد'
                  : 'حاول مرة أخرى',
      feedback: stars >= 2
          ? 'أحسنت الكتابة!'
          : stars == 1
              ? 'استمر في التدريب، أنت تتحسن.'
              : 'ارسم الحرف بخط واضح.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.question.questionText;
    return Column(
      children: [
        const Text(
          'تتبّع الحرف بإصبعك',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: AppTheme.textGray,
          ),
        ),
        const SizedBox(height: 8),
        _TracingCanvas(
          target: target,
          strokes: _strokes,
          currentStroke: _currentStroke,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
        ),
        const SizedBox(height: 12),
        if (!widget.isAnswered)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _strokes.isEmpty ? null : _clear,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('مسح', style: TextStyle(fontFamily: 'Cairo')),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _strokes.isEmpty ? null : _submit,
                icon: const Icon(Icons.check_rounded),
                label: const Text('تحقق',
                    style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        if (widget.lastResult != null) ...[
          const SizedBox(height: 16),
          _TracingResultCard(result: widget.lastResult!),
        ],
      ],
    );
  }
}

class _TracingCanvas extends StatelessWidget {
  final String target;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final void Function(DragStartDetails d, Size canvas) onPanStart;
  final void Function(DragUpdateDetails d) onPanUpdate;
  final void Function(DragEndDetails d) onPanEnd;

  const _TracingCanvas({
    required this.target,
    required this.strokes,
    required this.currentStroke,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, 280.0);
        return Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GestureDetector(
              onPanStart: (d) => onPanStart(d, Size(side, side)),
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: CustomPaint(
                painter: _TemplatePainter(
                  target: target,
                  strokes: [...strokes, currentStroke],
                ),
                size: Size(side, side),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TemplatePainter extends CustomPainter {
  final String target;
  final List<List<Offset>> strokes;

  _TemplatePainter({required this.target, required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final template = TextPainter(
      text: TextSpan(
        text: target,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: size.height * 0.75,
          fontWeight: FontWeight.w300,
          color: AppTheme.primaryBlue.withValues(alpha: 0.18),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: size.width);
    template.paint(
      canvas,
      Offset(
        (size.width - template.width) / 2,
        (size.height - template.height) / 2,
      ),
    );

    final paint = Paint()
      ..color = AppTheme.primaryOrange
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TemplatePainter old) =>
      old.strokes != strokes || old.target != target;
}

class _TracingResultCard extends StatelessWidget {
  final TracingResult result;

  const _TracingResultCard({required this.result});

  Color _color() {
    if (result.stars == 3) return AppTheme.primaryGreen;
    if (result.stars == 2) return AppTheme.primaryBlue;
    if (result.stars == 1) return AppTheme.primaryOrange;
    return AppTheme.primaryRed;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  i < result.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < result.stars ? AppTheme.primaryYellow : Colors.grey,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            result.rating,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: c,
            ),
          ),
          Text(
            result.feedback,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
