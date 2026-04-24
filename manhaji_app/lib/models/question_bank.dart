// Models for the teacher/admin question-bank viewer (FR-9).
// Mirrors the Spring DTOs in `dto/response/`:
//   SubjectSummary / LessonSummary / QuestionBankItem / QuestionBankResponse

class SubjectSummary {
  final int id;
  final String name;
  final int gradeLevel;
  final int lessonCount;
  final int questionCount;

  SubjectSummary({
    required this.id,
    required this.name,
    required this.gradeLevel,
    required this.lessonCount,
    required this.questionCount,
  });

  factory SubjectSummary.fromJson(Map<String, dynamic> json) {
    return SubjectSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      gradeLevel: (json['gradeLevel'] as num?)?.toInt() ?? 0,
      lessonCount: (json['lessonCount'] as num?)?.toInt() ?? 0,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class LessonSummary {
  final int id;
  final String title;
  final int orderIndex;
  final int questionCount;

  LessonSummary({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.questionCount,
  });

  factory LessonSummary.fromJson(Map<String, dynamic> json) {
    return LessonSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuestionBankItem {
  final int id;
  final String type; // MCQ / TRUE_FALSE / SHORT_ANSWER / FILL_BLANK / ORDERING / PRONUNCIATION / TRACING
  final String questionText;
  final String correctAnswer;
  final List<String> options;
  final int difficultyLevel;
  final int? lessonId;
  final String? lessonTitle;

  QuestionBankItem({
    required this.id,
    required this.type,
    required this.questionText,
    required this.correctAnswer,
    required this.options,
    required this.difficultyLevel,
    this.lessonId,
    this.lessonTitle,
  });

  factory QuestionBankItem.fromJson(Map<String, dynamic> json) {
    return QuestionBankItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'MCQ',
      questionText: json['questionText']?.toString() ?? '',
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      options: json['options'] is List
          ? (json['options'] as List).map((e) => e.toString()).toList()
          : const [],
      difficultyLevel: (json['difficultyLevel'] as num?)?.toInt() ?? 1,
      lessonId: (json['lessonId'] as num?)?.toInt(),
      lessonTitle: json['lessonTitle']?.toString(),
    );
  }

  bool get isMcq => type == 'MCQ';
  bool get isTrueFalse => type == 'TRUE_FALSE';
  bool get isShortAnswer => type == 'SHORT_ANSWER';
  bool get isFillBlank => type == 'FILL_BLANK';
  bool get isOrdering => type == 'ORDERING';
  bool get isPronunciation => type == 'PRONUNCIATION';
  bool get isTracing => type == 'TRACING';
}

class QuestionBankResponse {
  final int subjectId;
  final String subjectName;
  final int gradeLevel;
  final List<LessonSummary> lessons;
  final List<QuestionBankItem> questions;
  final int totalQuestionsInSubject;

  QuestionBankResponse({
    required this.subjectId,
    required this.subjectName,
    required this.gradeLevel,
    required this.lessons,
    required this.questions,
    required this.totalQuestionsInSubject,
  });

  factory QuestionBankResponse.fromJson(Map<String, dynamic> json) {
    return QuestionBankResponse(
      subjectId: (json['subjectId'] as num?)?.toInt() ?? 0,
      subjectName: json['subjectName']?.toString() ?? '',
      gradeLevel: (json['gradeLevel'] as num?)?.toInt() ?? 0,
      lessons: (json['lessons'] as List?)
              ?.map((l) => LessonSummary.fromJson(l as Map<String, dynamic>))
              .toList() ??
          const [],
      questions: (json['questions'] as List?)
              ?.map((q) => QuestionBankItem.fromJson(q as Map<String, dynamic>))
              .toList() ??
          const [],
      totalQuestionsInSubject:
          (json['totalQuestionsInSubject'] as num?)?.toInt() ?? 0,
    );
  }
}
