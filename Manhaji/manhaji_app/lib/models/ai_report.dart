class ProgressReportModel {
  final int id;
  final int studentId;
  final String studentName;
  final String periodStart;
  final String periodEnd;
  final String summary;
  final String riskLevel;
  final String generatedAt;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> recommendations;

  ProgressReportModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.periodStart,
    required this.periodEnd,
    required this.summary,
    required this.riskLevel,
    required this.generatedAt,
    this.strengths = const [],
    this.improvements = const [],
    this.recommendations = const [],
  });

  static List<String> _strList(dynamic v) =>
      (v as List?)?.map((e) => e.toString()).toList() ?? const [];

  factory ProgressReportModel.fromJson(Map<String, dynamic> json) {
    return ProgressReportModel(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      periodStart: json['periodStart'] ?? '',
      periodEnd: json['periodEnd'] ?? '',
      summary: json['summary'] ?? '',
      riskLevel: json['riskLevel'] ?? 'LOW',
      generatedAt: json['generatedAt'] ?? '',
      strengths: _strList(json['strengths']),
      improvements: _strList(json['improvements']),
      recommendations: _strList(json['recommendations']),
    );
  }
}

/// Live performance snapshot shown at the top of the performance tab.
class PerformanceStats {
  final int completedLessons;
  final int totalLessons;
  final int inProgressLessons;
  final double averageMastery;
  final double averageScore;
  final int totalPoints;
  final int currentStreak;
  final int quizzesTaken;
  final bool hasActivity;
  final List<SubjectStat> subjects;

  PerformanceStats({
    required this.completedLessons,
    required this.totalLessons,
    required this.inProgressLessons,
    required this.averageMastery,
    required this.averageScore,
    required this.totalPoints,
    required this.currentStreak,
    required this.quizzesTaken,
    required this.hasActivity,
    required this.subjects,
  });

  factory PerformanceStats.fromJson(Map<String, dynamic> json) {
    return PerformanceStats(
      completedLessons: json['completedLessons'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      inProgressLessons: json['inProgressLessons'] ?? 0,
      averageMastery: (json['averageMastery'] ?? 0).toDouble(),
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      totalPoints: json['totalPoints'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      quizzesTaken: json['quizzesTaken'] ?? 0,
      hasActivity: json['hasActivity'] ?? false,
      subjects: (json['subjects'] as List?)
              ?.map((s) => SubjectStat.fromJson(s))
              .toList() ??
          const [],
    );
  }
}

class SubjectStat {
  final String subjectName;
  final int completedLessons;
  final int totalLessons;
  final double averageMastery;

  SubjectStat({
    required this.subjectName,
    required this.completedLessons,
    required this.totalLessons,
    required this.averageMastery,
  });

  factory SubjectStat.fromJson(Map<String, dynamic> json) {
    return SubjectStat(
      subjectName: json['subjectName'] ?? '',
      completedLessons: json['completedLessons'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      averageMastery: (json['averageMastery'] ?? 0).toDouble(),
    );
  }
}

class LearningPathModel {
  final int id;
  final int studentId;
  final String studentName;
  final String recommendations;
  final String generatedAt;

  LearningPathModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.recommendations,
    required this.generatedAt,
  });

  factory LearningPathModel.fromJson(Map<String, dynamic> json) {
    return LearningPathModel(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      recommendations: json['recommendations'] ?? '{}',
      generatedAt: json['generatedAt'] ?? '',
    );
  }
}
