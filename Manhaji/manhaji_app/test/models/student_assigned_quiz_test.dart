import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/student_assigned_quiz.dart';

void main() {
  test('StudentAssignedQuizSummary parses summary JSON safely', () {
    final quiz = StudentAssignedQuizSummary.fromJson({
      'assignmentId': 70,
      'quizId': 44,
      'title': 'اختبار الحروف',
      'subjectName': 'اللغة العربية',
      'questionCount': 3,
      'dueAt': '2026-07-07T10:00:00',
      'status': 'ASSIGNED',
      'attemptsUsed': 1,
      'maxAttempts': 2,
      'canStart': true,
    });

    expect(quiz.assignmentId, 70);
    expect(quiz.quizId, 44);
    expect(quiz.title, 'اختبار الحروف');
    expect(quiz.subjectName, 'اللغة العربية');
    expect(quiz.questionCount, 3);
    expect(quiz.dueAtDate, DateTime(2026, 7, 7, 10));
    expect(quiz.status, 'ASSIGNED');
    expect(quiz.attemptsUsed, 1);
    expect(quiz.maxAttempts, 2);
    expect(quiz.canStart, isTrue);
  });

  test('StudentAssignedQuizDetail converts to quiz for learning flow', () {
    final detail = StudentAssignedQuizDetail.fromJson({
      'assignmentId': 70,
      'quizId': 44,
      'title': 'اختبار الحروف',
      'subjectId': 10,
      'subjectName': 'اللغة العربية',
      'questionCount': 1,
      'status': 'ASSIGNED',
      'attemptsUsed': 0,
      'maxAttempts': 1,
      'canStart': true,
      'questions': [
        {
          'id': 30,
          'type': 'MCQ',
          'questionText': 'اختر الكلمة الصحيحة',
          'options': ['رمان', 'باب'],
          'difficultyLevel': 1,
        },
      ],
    });

    final quiz = detail.toQuiz();

    expect(detail.subjectId, 10);
    expect(detail.questions.single.id, 30);
    expect(quiz.id, 44);
    expect(quiz.title, 'اختبار الحروف');
    expect(quiz.questions.single.questionText, 'اختر الكلمة الصحيحة');
  });
}
