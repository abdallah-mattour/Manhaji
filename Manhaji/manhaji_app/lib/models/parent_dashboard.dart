class ChildSummary {
  final int studentId;
  final String fullName;
  final String? avatarId;
  final int gradeLevel;
  final int totalPoints;
  final int currentStreak;
  final int lessonsCompleted;
  final int totalLessons;
  final double overallMastery;
  final String? lastLoginAt;

  ChildSummary({
    required this.studentId,
    required this.fullName,
    this.avatarId,
    required this.gradeLevel,
    required this.totalPoints,
    required this.currentStreak,
    required this.lessonsCompleted,
    required this.totalLessons,
    required this.overallMastery,
    this.lastLoginAt,
  });

  factory ChildSummary.fromJson(Map<String, dynamic> json) {
    return ChildSummary(
      studentId: json['studentId'] ?? 0,
      fullName: json['fullName'] ?? '',
      avatarId: json['avatarId'],
      gradeLevel: json['gradeLevel'] ?? 1,
      totalPoints: json['totalPoints'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      lessonsCompleted: json['lessonsCompleted'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      overallMastery: (json['overallMastery'] ?? 0).toDouble(),
      lastLoginAt: json['lastLoginAt'],
    );
  }
}

class QuizAttemptSummary {
  final int attemptId;
  final String quizTitle;
  final String? lessonTitle;
  final String? subjectName;
  final double? score;
  final String status;
  final String? attemptedAt;

  QuizAttemptSummary({
    required this.attemptId,
    required this.quizTitle,
    this.lessonTitle,
    this.subjectName,
    this.score,
    required this.status,
    this.attemptedAt,
  });

  factory QuizAttemptSummary.fromJson(Map<String, dynamic> json) {
    return QuizAttemptSummary(
      attemptId: json['attemptId'] ?? 0,
      quizTitle: json['quizTitle'] ?? '',
      lessonTitle: json['lessonTitle'],
      subjectName: json['subjectName'],
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      status: json['status'] ?? 'GRADED',
      attemptedAt: json['attemptedAt'],
    );
  }
}

class ParentAlert {
  final int? studentId;
  final String alertType;
  final String message;
  final String severity;
  final String studentName;

  ParentAlert({
    this.studentId,
    required this.alertType,
    required this.message,
    required this.severity,
    required this.studentName,
  });

  factory ParentAlert.fromJson(Map<String, dynamic> json) {
    return ParentAlert(
      studentId: json['studentId'],
      alertType: json['alertType'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'MEDIUM',
      studentName: json['studentName'] ?? '',
    );
  }
}

class ParentRecommendation {
  final String type;
  final String title;
  final String message;
  final String priority;
  final String studentName;
  final String? subjectName;
  final String? actionLabel;

  ParentRecommendation({
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.studentName,
    this.subjectName,
    this.actionLabel,
  });

  factory ParentRecommendation.fromJson(Map<String, dynamic> json) {
    return ParentRecommendation(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      priority: json['priority'] ?? 'MEDIUM',
      studentName: json['studentName'] ?? '',
      subjectName: json['subjectName'],
      actionLabel: json['actionLabel'],
    );
  }
}

class ParentReportSummary {
  final int id;
  final String? periodStart;
  final String? periodEnd;
  final String? summary;
  final String? riskLevel;
  final String? generatedAt;

  ParentReportSummary({
    required this.id,
    this.periodStart,
    this.periodEnd,
    this.summary,
    this.riskLevel,
    this.generatedAt,
  });

  factory ParentReportSummary.fromJson(Map<String, dynamic> json) {
    return ParentReportSummary(
      id: json['id'] ?? 0,
      periodStart: json['periodStart'],
      periodEnd: json['periodEnd'],
      summary: json['summary'],
      riskLevel: json['riskLevel'],
      generatedAt: json['generatedAt'],
    );
  }
}

class ParentDashboard {
  final int parentId;
  final String fullName;
  final List<ChildSummary> children;
  final List<QuizAttemptSummary> recentActivityAcrossChildren;
  final List<ParentAlert> alerts;
  final List<ParentRecommendation> recommendations;

  ParentDashboard({
    required this.parentId,
    required this.fullName,
    required this.children,
    required this.recentActivityAcrossChildren,
    required this.alerts,
    required this.recommendations,
  });

  factory ParentDashboard.fromJson(Map<String, dynamic> json) {
    return ParentDashboard(
      parentId: json['parentId'] ?? 0,
      fullName: json['fullName'] ?? '',
      children: (json['children'] as List?)
              ?.map((c) => ChildSummary.fromJson(c))
              .toList() ??
          [],
      recentActivityAcrossChildren:
          (json['recentActivityAcrossChildren'] as List?)
                  ?.map((a) => QuizAttemptSummary.fromJson(a))
                  .toList() ??
              [],
      alerts: (json['alerts'] as List?)
              ?.map((a) => ParentAlert.fromJson(a))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List?)
              ?.map((r) => ParentRecommendation.fromJson(r))
              .toList() ??
          [],
    );
  }
}
