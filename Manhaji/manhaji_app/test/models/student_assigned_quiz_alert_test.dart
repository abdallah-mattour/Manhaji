import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/student_assigned_quiz.dart';
import 'package:manhaji_app/models/student_assigned_quiz_alert.dart';

StudentAssignedQuizSummary _quiz({
  int assignmentId = 70,
  String title = 'اختبار الحروف',
  String? dueAt,
  String status = 'ASSIGNED',
  bool canStart = true,
  int attemptsUsed = 0,
  int? maxAttempts = 2,
}) {
  return StudentAssignedQuizSummary(
    assignmentId: assignmentId,
    quizId: assignmentId + 100,
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

  test('builds ending-soon alert for startable quiz due within 24 hours', () {
    final alerts = buildStudentAssignedQuizAlerts([
      _quiz(dueAt: '2026-07-07T09:00:00'),
    ], now: now);

    expect(alerts.single.type, StudentAssignedQuizAlertType.endingSoon);
    expect(alerts.single.title, 'اختبار "اختبار الحروف" ينتهي قريبًا');
    expect(alerts.single.description, 'ينتهي خلال 23 ساعة');
    expect(alerts.single.canAct, isTrue);
  });

  test('builds expired alert for past due quiz', () {
    final alerts = buildStudentAssignedQuizAlerts([
      _quiz(dueAt: '2026-07-06T09:00:00', status: 'EXPIRED', canStart: false),
    ], now: now);

    expect(alerts.single.type, StudentAssignedQuizAlertType.expired);
    expect(alerts.single.title, 'انتهى وقت اختبار "اختبار الحروف"');
    expect(alerts.single.description, 'لم يعد متاحًا للبدء');
    expect(alerts.single.canAct, isFalse);
  });

  test('builds max-attempts alert when all attempts are used', () {
    final alerts = buildStudentAssignedQuizAlerts([
      _quiz(attemptsUsed: 2, maxAttempts: 2, canStart: false),
    ], now: now);

    expect(alerts.single.type, StudentAssignedQuizAlertType.maxAttemptsUsed);
    expect(alerts.single.title, 'استُخدمت جميع المحاولات');
    expect(alerts.single.description, 'لاختبار "اختبار الحروف"');
    expect(alerts.single.canAct, isFalse);
  });

  test('builds available alert for a new startable quiz', () {
    final alerts = buildStudentAssignedQuizAlerts([
      _quiz(dueAt: '2026-07-08T10:00:00'),
    ], now: now);

    expect(alerts.single.type, StudentAssignedQuizAlertType.available);
    expect(alerts.single.title, 'اختبار جديد: اختبار الحروف');
    expect(alerts.single.description, 'لديك اختبار جديد من المعلم');
    expect(alerts.single.canAct, isTrue);
  });

  test('orders alerts by priority before due date', () {
    final alerts = buildStudentAssignedQuizAlerts([
      _quiz(
        assignmentId: 4,
        title: 'اختبار جديد',
        dueAt: '2026-07-08T10:00:00',
      ),
      _quiz(
        assignmentId: 2,
        title: 'اختبار قريب',
        dueAt: '2026-07-07T09:00:00',
      ),
      _quiz(
        assignmentId: 1,
        title: 'اختبار منتهي',
        dueAt: '2026-07-06T09:00:00',
        status: 'EXPIRED',
        canStart: false,
      ),
      _quiz(
        assignmentId: 3,
        title: 'اختبار محاولات',
        attemptsUsed: 1,
        maxAttempts: 1,
        canStart: false,
      ),
    ], now: now);

    expect(alerts.map((alert) => alert.type), [
      StudentAssignedQuizAlertType.expired,
      StudentAssignedQuizAlertType.maxAttemptsUsed,
      StudentAssignedQuizAlertType.endingSoon,
      StudentAssignedQuizAlertType.available,
    ]);
  });

  test('does not create noisy alert for completed quiz without action', () {
    final alerts = buildStudentAssignedQuizAlerts([
      _quiz(status: 'COMPLETED', canStart: false, attemptsUsed: 0),
    ], now: now);

    expect(alerts, isEmpty);
  });
}
