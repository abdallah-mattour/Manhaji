import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/student_assigned_quiz.dart';
import 'package:manhaji_app/widgets/student_assigned_quiz_alerts_section.dart';

Widget _wrap(StudentAssignedQuizAlertsSection child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

StudentAssignedQuizSummary _quiz({
  int assignmentId = 70,
  int? quizId,
  String title = 'اختبار الحروف',
  String? dueAt,
  String status = 'ASSIGNED',
  bool canStart = true,
  int attemptsUsed = 0,
  int? maxAttempts = 2,
}) {
  return StudentAssignedQuizSummary(
    assignmentId: assignmentId,
    quizId: quizId ?? assignmentId + 100,
    title: title,
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
  final now = DateTime(2026, 7, 6, 10);

  testWidgets('renders compact alert titles and overflow count', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        StudentAssignedQuizAlertsSection(
          quizzes: [
            _quiz(
              assignmentId: 1,
              title: 'اختبار منتهي',
              dueAt: '2026-07-06T09:00:00',
              status: 'EXPIRED',
              canStart: false,
            ),
            _quiz(
              assignmentId: 2,
              title: 'اختبار قريب',
              dueAt: '2026-07-07T09:00:00',
            ),
            _quiz(
              assignmentId: 3,
              title: 'اختبار جديد',
              dueAt: '2026-07-08T10:00:00',
            ),
            _quiz(
              assignmentId: 4,
              title: 'اختبار آخر',
              dueAt: '2026-07-08T11:00:00',
            ),
          ],
          now: now,
          onAction: (_) async {},
        ),
      ),
    );

    expect(find.text('تنبيهات الاختبارات'), findsOneWidget);
    expect(find.text('انتهى وقت اختبار "اختبار منتهي"'), findsOneWidget);
    expect(find.text('اختبار "اختبار قريب" ينتهي قريبًا'), findsOneWidget);
    expect(find.text('اختبار جديد: اختبار جديد'), findsOneWidget);
    expect(find.text('+1 تنبيهات أخرى'), findsOneWidget);
    expect(find.text('اختبار جديد: اختبار آخر'), findsNothing);
  });

  testWidgets('hides section when there are no alerts', (tester) async {
    await tester.pumpWidget(
      _wrap(
        StudentAssignedQuizAlertsSection(
          quizzes: [
            _quiz(status: 'COMPLETED', canStart: false, attemptsUsed: 0),
          ],
          now: now,
          onAction: (_) async {},
        ),
      ),
    );

    expect(find.text('تنبيهات الاختبارات'), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('safe alert action passes assignment quiz to assigned flow', (
    tester,
  ) async {
    int? startedAssignmentId;
    int? startedQuizId;

    await tester.pumpWidget(
      _wrap(
        StudentAssignedQuizAlertsSection(
          quizzes: [_quiz(assignmentId: 70, quizId: 44)],
          now: now,
          onAction: (quiz) async {
            startedAssignmentId = quiz.assignmentId;
            startedQuizId = quiz.quizId;
          },
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('assigned_quiz_alert_action_70')),
    );
    await tester.pump();

    expect(startedAssignmentId, 70);
    expect(startedQuizId, 44);
  });
}
