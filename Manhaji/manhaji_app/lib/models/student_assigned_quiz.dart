import 'quiz.dart';

class StudentAssignedQuizSummary {
  final int assignmentId;
  final int quizId;
  final String title;
  final String? subjectName;
  final int questionCount;
  final String? dueAt;
  final String status;
  final int attemptsUsed;
  final int? maxAttempts;
  final bool canStart;

  const StudentAssignedQuizSummary({
    required this.assignmentId,
    required this.quizId,
    required this.title,
    this.subjectName,
    required this.questionCount,
    this.dueAt,
    required this.status,
    required this.attemptsUsed,
    this.maxAttempts,
    required this.canStart,
  });

  factory StudentAssignedQuizSummary.fromJson(Map<String, dynamic> json) {
    return StudentAssignedQuizSummary(
      assignmentId: (json['assignmentId'] as num?)?.toInt() ?? 0,
      quizId: (json['quizId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      subjectName: json['subjectName']?.toString(),
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      dueAt: json['dueAt']?.toString(),
      status: json['status']?.toString() ?? 'ASSIGNED',
      attemptsUsed: (json['attemptsUsed'] as num?)?.toInt() ?? 0,
      maxAttempts: (json['maxAttempts'] as num?)?.toInt(),
      canStart: json['canStart'] == true,
    );
  }

  DateTime? get dueAtDate {
    final value = dueAt;
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String get normalizedStatus => status.toUpperCase();

  bool get isClosed => normalizedStatus == 'CLOSED';

  bool get isCompleted =>
      normalizedStatus == 'COMPLETED' ||
      (maxAttempts != null && attemptsUsed >= maxAttempts! && !canStart);

  bool isExpiredAt(DateTime now) {
    final due = dueAtDate;
    return due != null && !due.isAfter(now);
  }
}

class StudentAssignedQuizDetail extends StudentAssignedQuizSummary {
  final int? subjectId;
  final List<Question> questions;

  const StudentAssignedQuizDetail({
    required super.assignmentId,
    required super.quizId,
    required super.title,
    this.subjectId,
    super.subjectName,
    required super.questionCount,
    super.dueAt,
    required super.status,
    required super.attemptsUsed,
    super.maxAttempts,
    required super.canStart,
    required this.questions,
  });

  factory StudentAssignedQuizDetail.fromJson(Map<String, dynamic> json) {
    return StudentAssignedQuizDetail(
      assignmentId: (json['assignmentId'] as num?)?.toInt() ?? 0,
      quizId: (json['quizId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      subjectId: (json['subjectId'] as num?)?.toInt(),
      subjectName: json['subjectName']?.toString(),
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      dueAt: json['dueAt']?.toString(),
      status: json['status']?.toString() ?? 'ASSIGNED',
      attemptsUsed: (json['attemptsUsed'] as num?)?.toInt() ?? 0,
      maxAttempts: (json['maxAttempts'] as num?)?.toInt(),
      canStart: json['canStart'] == true,
      questions:
          (json['questions'] as List?)
              ?.map(
                (q) => Question.fromJson(Map<String, dynamic>.from(q as Map)),
              )
              .toList() ??
          const [],
    );
  }

  Quiz toQuiz() {
    return Quiz(
      id: quizId,
      title: title,
      gamified: false,
      totalQuestions: questionCount,
      questions: questions,
    );
  }
}
