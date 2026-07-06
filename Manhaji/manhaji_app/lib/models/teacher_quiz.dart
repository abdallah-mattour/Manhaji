import 'question_bank.dart';

class TeacherQuizSummary {
  final int id;
  final String title;
  final int? subjectId;
  final String? subjectName;
  final int? lessonId;
  final String? lessonTitle;
  final int questionCount;
  final String? createdAt;
  final String? status;

  const TeacherQuizSummary({
    required this.id,
    required this.title,
    this.subjectId,
    this.subjectName,
    this.lessonId,
    this.lessonTitle,
    required this.questionCount,
    this.createdAt,
    this.status,
  });

  factory TeacherQuizSummary.fromJson(Map<String, dynamic> json) {
    return TeacherQuizSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      subjectId: (json['subjectId'] as num?)?.toInt(),
      subjectName: json['subjectName']?.toString(),
      lessonId: (json['lessonId'] as num?)?.toInt(),
      lessonTitle: json['lessonTitle']?.toString(),
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString(),
      status: json['status']?.toString(),
    );
  }

  bool get hasStatus => status != null && status!.trim().isNotEmpty;

  bool get isDraft => status?.toUpperCase() == 'DRAFT';

  bool get isPublished => status?.toUpperCase() == 'PUBLISHED';

  bool get isArchived => status?.toUpperCase() == 'ARCHIVED';
}

class TeacherQuizDetail extends TeacherQuizSummary {
  final List<QuestionBankItem> questions;

  const TeacherQuizDetail({
    required super.id,
    required super.title,
    super.subjectId,
    super.subjectName,
    super.lessonId,
    super.lessonTitle,
    required super.questionCount,
    super.createdAt,
    super.status,
    required this.questions,
  });

  factory TeacherQuizDetail.fromJson(Map<String, dynamic> json) {
    return TeacherQuizDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      subjectId: (json['subjectId'] as num?)?.toInt(),
      subjectName: json['subjectName']?.toString(),
      lessonId: (json['lessonId'] as num?)?.toInt(),
      lessonTitle: json['lessonTitle']?.toString(),
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt']?.toString(),
      status: json['status']?.toString(),
      questions:
          (json['questions'] as List?)
              ?.map((q) => QuestionBankItem.fromJson(q as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class TeacherQuizAssignment {
  final int assignmentId;
  final int quizId;
  final String quizTitle;
  final int? subjectId;
  final String? subjectName;
  final int? schoolId;
  final String? schoolName;
  final int? gradeLevel;
  final String status;
  final String? publishedAt;
  final String? dueAt;
  final int? maxAttempts;
  final int assignedCount;

  const TeacherQuizAssignment({
    required this.assignmentId,
    required this.quizId,
    required this.quizTitle,
    this.subjectId,
    this.subjectName,
    this.schoolId,
    this.schoolName,
    this.gradeLevel,
    required this.status,
    this.publishedAt,
    this.dueAt,
    this.maxAttempts,
    required this.assignedCount,
  });

  factory TeacherQuizAssignment.fromJson(Map<String, dynamic> json) {
    return TeacherQuizAssignment(
      assignmentId: (json['assignmentId'] as num?)?.toInt() ?? 0,
      quizId: (json['quizId'] as num?)?.toInt() ?? 0,
      quizTitle: json['quizTitle']?.toString() ?? '',
      subjectId: (json['subjectId'] as num?)?.toInt(),
      subjectName: json['subjectName']?.toString(),
      schoolId: (json['schoolId'] as num?)?.toInt(),
      schoolName: json['schoolName']?.toString(),
      gradeLevel: (json['gradeLevel'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'PUBLISHED',
      publishedAt: json['publishedAt']?.toString(),
      dueAt: json['dueAt']?.toString(),
      maxAttempts: (json['maxAttempts'] as num?)?.toInt(),
      assignedCount: (json['assignedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class TeacherAssignmentAttempt {
  final int attemptId;
  final int? studentId;
  final String? studentName;
  final String status;
  final double? score;
  final String? startedAt;
  final String? submittedAt;

  const TeacherAssignmentAttempt({
    required this.attemptId,
    this.studentId,
    this.studentName,
    required this.status,
    this.score,
    this.startedAt,
    this.submittedAt,
  });

  factory TeacherAssignmentAttempt.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentAttempt(
      attemptId: (json['attemptId'] as num?)?.toInt() ?? 0,
      studentId: (json['studentId'] as num?)?.toInt(),
      studentName: json['studentName']?.toString(),
      status: json['status']?.toString() ?? 'IN_PROGRESS',
      score: (json['score'] as num?)?.toDouble(),
      startedAt: json['startedAt']?.toString(),
      submittedAt: json['submittedAt']?.toString(),
    );
  }
}

class TeacherAssignmentResults {
  final int assignmentId;
  final int quizId;
  final String quizTitle;
  final int assignedCount;
  final int completedCount;
  final double? averageScore;
  final List<TeacherAssignmentAttempt> recentAttempts;

  const TeacherAssignmentResults({
    required this.assignmentId,
    required this.quizId,
    required this.quizTitle,
    required this.assignedCount,
    required this.completedCount,
    this.averageScore,
    required this.recentAttempts,
  });

  factory TeacherAssignmentResults.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentResults(
      assignmentId: (json['assignmentId'] as num?)?.toInt() ?? 0,
      quizId: (json['quizId'] as num?)?.toInt() ?? 0,
      quizTitle: json['quizTitle']?.toString() ?? '',
      assignedCount: (json['assignedCount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      recentAttempts:
          (json['recentAttempts'] as List?)
              ?.map(
                (attempt) => TeacherAssignmentAttempt.fromJson(
                  attempt as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }
}
