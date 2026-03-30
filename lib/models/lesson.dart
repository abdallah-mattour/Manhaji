class LessonSummary {
  final int id;
  final String title;
  final int orderIndex;
  final String completionStatus;
  final double masteryLevel;

  LessonSummary({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.completionStatus,
    required this.masteryLevel,
  });

  factory LessonSummary.fromJson(Map<String, dynamic> json) {
    return LessonSummary(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      orderIndex: json['orderIndex'] ?? 0,
      completionStatus: json['completionStatus'] ?? 'NOT_STARTED',
      masteryLevel: (json['masteryLevel'] ?? 0.0).toDouble(),
    );
  }

  bool get isCompleted => completionStatus == 'COMPLETED' || completionStatus == 'MASTERED';
  bool get isInProgress => completionStatus == 'IN_PROGRESS';
}

class Lesson {
  final int id;
  final String title;
  final String content;
  final String? audioUrl;
  final List<String> imageUrls;
  final String? objectives;
  final int orderIndex;
  final int subjectId;
  final String subjectName;
  final int gradeLevel;
  final int totalQuestions;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    this.audioUrl,
    required this.imageUrls,
    this.objectives,
    required this.orderIndex,
    required this.subjectId,
    required this.subjectName,
    required this.gradeLevel,
    required this.totalQuestions,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      audioUrl: json['audioUrl'],
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      objectives: json['objectives'],
      orderIndex: json['orderIndex'] ?? 0,
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      gradeLevel: json['gradeLevel'] ?? 1,
      totalQuestions: json['totalQuestions'] ?? 0,
    );
  }

  bool get hasQuiz => totalQuestions > 0;
}
