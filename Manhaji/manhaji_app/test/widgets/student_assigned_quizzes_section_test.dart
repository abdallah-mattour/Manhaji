import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/student_assigned_quiz.dart';
import 'package:manhaji_app/widgets/student_assigned_quizzes_section.dart';

Widget _wrap(StudentAssignedQuizzesSection child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

StudentAssignedQuizSummary _quiz({
  String dueAt = '2026-07-07T09:00:00',
  String status = 'ASSIGNED',
  bool canStart = true,
  int attemptsUsed = 0,
  int? maxAttempts = 2,
}) {
  return StudentAssignedQuizSummary(
    assignmentId: 70,
    quizId: 44,
    title: 'اختبار الحروف',
    subjectName: 'اللغة العربية',
    questionCount: 3,
    dueAt: dueAt,
    status: status,
    attemptsUsed: attemptsUsed,
    maxAttempts: maxAttempts,
    canStart: canStart,
  );
}

void main() {
  testWidgets('renders empty state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        StudentAssignedQuizzesSection(
          quizzes: const [],
          isLoading: false,
          errorMessage: null,
          onRetry: () {},
          onStart: (_) async {},
          now: DateTime(2026, 7, 6, 10),
        ),
      ),
    );

    expect(find.text('اختبارات المعلم'), findsOneWidget);
    expect(find.text('لا توجد اختبارات مخصصة حاليًا'), findsOneWidget);
  });

  testWidgets('card shows title, subject, due and attempt info', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        StudentAssignedQuizzesSection(
          quizzes: [_quiz()],
          isLoading: false,
          errorMessage: null,
          onRetry: () {},
          onStart: (_) async {},
          now: DateTime(2026, 7, 6, 10),
        ),
      ),
    );

    expect(find.text('اختبار الحروف'), findsOneWidget);
    expect(find.text('اللغة العربية'), findsOneWidget);
    expect(find.text('3 سؤال'), findsOneWidget);
    expect(find.text('ينتهي خلال 23 ساعة'), findsOneWidget);
    expect(find.text('المحاولات: 0 / 2'), findsOneWidget);
    expect(find.text('متاح'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assigned_quiz_start_70')),
      findsOneWidget,
    );
  });

  testWidgets('expired quiz disables start and shows deadline message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        StudentAssignedQuizzesSection(
          quizzes: [
            _quiz(
              dueAt: '2026-07-06T09:00:00',
              status: 'EXPIRED',
              canStart: false,
            ),
          ],
          isLoading: false,
          errorMessage: null,
          onRetry: () {},
          onStart: (_) async {},
          now: DateTime(2026, 7, 6, 10),
        ),
      ),
    );

    expect(find.text('انتهى وقت التسليم'), findsOneWidget);
    expect(find.text('انتهى الوقت'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('assigned_quiz_start_70')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('closed quiz disables start and shows closed status', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        StudentAssignedQuizzesSection(
          quizzes: [_quiz(status: 'CLOSED', canStart: false)],
          isLoading: false,
          errorMessage: null,
          onRetry: () {},
          onStart: (_) async {},
          now: DateTime(2026, 7, 6, 10),
        ),
      ),
    );

    expect(find.text('مغلق'), findsOneWidget);
    expect(find.text('غير متاح'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('assigned_quiz_start_70')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('max attempts used disables start and shows attempt state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        StudentAssignedQuizzesSection(
          quizzes: [_quiz(attemptsUsed: 2, maxAttempts: 2, canStart: false)],
          isLoading: false,
          errorMessage: null,
          onRetry: () {},
          onStart: (_) async {},
          now: DateTime(2026, 7, 6, 10),
        ),
      ),
    );

    expect(find.text('المحاولات: 2 / 2'), findsOneWidget);
    expect(find.text('مكتمل'), findsOneWidget);
    expect(find.text('غير متاح'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('assigned_quiz_start_70')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('compact mode keeps action info without repeating deadline', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        StudentAssignedQuizzesSection(
          quizzes: [_quiz()],
          isLoading: false,
          errorMessage: null,
          onRetry: () {},
          onStart: (_) async {},
          now: DateTime(2026, 7, 6, 10),
          compact: true,
        ),
      ),
    );

    expect(find.text('اختبار الحروف'), findsOneWidget);
    expect(find.text('3 سؤال'), findsOneWidget);
    expect(find.text('المحاولات: 0 / 2'), findsOneWidget);
    expect(find.text('ينتهي خلال 23 ساعة'), findsNothing);
    expect(
      find.byKey(const ValueKey('assigned_quiz_start_70')),
      findsOneWidget,
    );
  });
}
