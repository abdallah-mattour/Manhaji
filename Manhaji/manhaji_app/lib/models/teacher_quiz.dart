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

  const TeacherQuizSummary({
    required this.id,
    required this.title,
    this.subjectId,
    this.subjectName,
    this.lessonId,
    this.lessonTitle,
    required this.questionCount,
    this.createdAt,
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
    );
  }
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
      questions:
          (json['questions'] as List?)
              ?.map((q) => QuestionBankItem.fromJson(q as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
