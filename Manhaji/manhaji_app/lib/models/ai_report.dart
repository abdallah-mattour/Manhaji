class ProgressReportModel {
  final int id;
  final int studentId;
  final String studentName;
  final String periodStart;
  final String periodEnd;
  final String summary;
  final String riskLevel;
  final String generatedAt;

  ProgressReportModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.periodStart,
    required this.periodEnd,
    required this.summary,
    required this.riskLevel,
    required this.generatedAt,
  });

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
