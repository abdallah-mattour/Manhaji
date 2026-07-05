import '../models/question_bank.dart';

class StudentDetailArgs {
  final int studentId;
  const StudentDetailArgs(this.studentId);
}

/// Carries the tapped subject into the admin question-bank questions route.
class AdminQuestionBankSubjectArgs {
  final SubjectSummary subject;
  const AdminQuestionBankSubjectArgs(this.subject);
}

class ChildProgressArgs {
  final int studentId;
  const ChildProgressArgs(this.studentId);
}
