// Regression test for the 2026-07-05 bug: every TRACING question rendered
// as a blank page. Root cause: AppTheme gives buttons
// `minimumSize: Size(double.infinity, 56)`; the tracing widget's action Row
// then demanded infinite width and the whole learning screen failed layout.
// The REAL app theme is essential here — with the default Material theme the
// bug is invisible.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/quiz.dart';
import 'package:manhaji_app/widgets/question_widgets/tracing_widget.dart';

Question _squareTracing() => Question.fromJson({
      'id': 999,
      'type': 'TRACING',
      'questionText': 'ارسم: □',
      'correctAnswer': '□',
      'options': null,
      'difficultyLevel': 1,
      'subSkill': 'handwriting',
      'points': 10,
    });

/// Exactly as served by GET /api/quiz/lesson/330 (no points, no answer).
Question _numberTracing() => Question.fromJson({
      'id': 2595,
      'type': 'TRACING',
      'questionText': 'اكتب العدد ٤٧',
      'options': null,
      'difficultyLevel': 1,
      'subSkill': 'handwriting',
      'imageUrl': null,
      'audioUrl': null,
      'optionImages': null,
      'pairsJson': null,
    });

void main() {
  testWidgets('TracingWidget renders standalone for square question',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TracingWidget(
            question: _squareTracing(),
            isAnswered: false,
            lastResult: null,
            onComplete: (_) async {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(TracingWidget), findsOneWidget);
  });

  testWidgets('TracingWidget renders the served number-tracing question',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TracingWidget(
            question: _numberTracing(),
            isAnswered: false,
            lastResult: null,
            onComplete: (_) async {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(TracingWidget), findsOneWidget);
  });

  testWidgets('Full learning-screen content tree renders for TRACING',
      (tester) async {
    final q = _squareTracing();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        TracingWidget(
                          question: q,
                          isAnswered: false,
                          lastResult: null,
                          onComplete: (_) async {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(TracingWidget), findsOneWidget);
  });
}
