import 'student_assigned_quiz.dart';

enum StudentAssignedQuizAlertType {
  expired,
  maxAttemptsUsed,
  unavailable,
  endingSoon,
  available,
}

class StudentAssignedQuizAlert {
  final StudentAssignedQuizAlertType type;
  final StudentAssignedQuizSummary quiz;
  final String title;
  final String description;
  final int priority;
  final bool canAct;
  final String? actionLabel;

  const StudentAssignedQuizAlert({
    required this.type,
    required this.quiz,
    required this.title,
    required this.description,
    required this.priority,
    required this.canAct,
    this.actionLabel,
  });
}

List<StudentAssignedQuizAlert> buildStudentAssignedQuizAlerts(
  List<StudentAssignedQuizSummary> quizzes, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final alerts = <StudentAssignedQuizAlert>[];

  for (final quiz in quizzes) {
    final alert = _alertForQuiz(quiz, currentTime);
    if (alert != null) alerts.add(alert);
  }

  alerts.sort((a, b) {
    final priority = a.priority.compareTo(b.priority);
    if (priority != 0) return priority;
    final aDue = a.quiz.dueAtDate;
    final bDue = b.quiz.dueAtDate;
    if (aDue != null && bDue != null) {
      final due = aDue.compareTo(bDue);
      if (due != 0) return due;
    } else if (aDue != null) {
      return -1;
    } else if (bDue != null) {
      return 1;
    }
    return a.quiz.assignmentId.compareTo(b.quiz.assignmentId);
  });

  return alerts;
}

StudentAssignedQuizAlert? _alertForQuiz(
  StudentAssignedQuizSummary quiz,
  DateTime now,
) {
  final status = quiz.normalizedStatus;
  final completed = status == 'COMPLETED';
  final expired = quiz.isExpiredAt(now) || status == 'EXPIRED';
  final maxAttemptsUsed =
      quiz.maxAttempts != null && quiz.attemptsUsed >= quiz.maxAttempts!;

  if (expired && !completed) {
    return StudentAssignedQuizAlert(
      type: StudentAssignedQuizAlertType.expired,
      quiz: quiz,
      title: 'انتهى وقت اختبار "${_title(quiz)}"',
      description: 'لم يعد متاحًا للبدء',
      priority: 0,
      canAct: false,
    );
  }

  if (maxAttemptsUsed) {
    return StudentAssignedQuizAlert(
      type: StudentAssignedQuizAlertType.maxAttemptsUsed,
      quiz: quiz,
      title: 'استُخدمت جميع المحاولات',
      description: 'لاختبار "${_title(quiz)}"',
      priority: 1,
      canAct: false,
    );
  }

  if (quiz.isClosed) {
    return StudentAssignedQuizAlert(
      type: StudentAssignedQuizAlertType.unavailable,
      quiz: quiz,
      title: 'اختبار "${_title(quiz)}" غير متاح حاليًا',
      description: 'راجعه لاحقًا من صفحة الاختبارات',
      priority: 1,
      canAct: false,
    );
  }

  if (!quiz.canStart) {
    if (completed) return null;
    return StudentAssignedQuizAlert(
      type: StudentAssignedQuizAlertType.unavailable,
      quiz: quiz,
      title: 'اختبار "${_title(quiz)}" غير متاح حاليًا',
      description: 'راجعه لاحقًا من صفحة الاختبارات',
      priority: 1,
      canAct: false,
    );
  }

  final due = quiz.dueAtDate;
  if (due != null && due.isAfter(now)) {
    final remaining = due.difference(now);
    if (remaining <= const Duration(hours: 24)) {
      return StudentAssignedQuizAlert(
        type: StudentAssignedQuizAlertType.endingSoon,
        quiz: quiz,
        title: 'اختبار "${_title(quiz)}" ينتهي قريبًا',
        description: 'ينتهي خلال ${formatAssignedQuizRemainingTime(remaining)}',
        priority: 2,
        canAct: true,
        actionLabel: 'ابدأ الآن',
      );
    }
  }

  return StudentAssignedQuizAlert(
    type: StudentAssignedQuizAlertType.available,
    quiz: quiz,
    title: 'اختبار جديد: ${_title(quiz)}',
    description: 'لديك اختبار جديد من المعلم',
    priority: 3,
    canAct: true,
    actionLabel: 'ابدأ الآن',
  );
}

String formatAssignedQuizRemainingTime(Duration remaining) {
  final hours = remaining.inHours;
  if (hours < 24) {
    if (hours <= 1) return 'ساعة';
    return '$hours ساعة';
  }
  final days = (remaining.inHours / 24).ceil();
  if (days == 1) return 'يوم واحد';
  if (days == 2) return 'يومين';
  return '$days أيام';
}

String _title(StudentAssignedQuizSummary quiz) {
  return quiz.title.trim().isEmpty ? 'اختبار بدون عنوان' : quiz.title.trim();
}
