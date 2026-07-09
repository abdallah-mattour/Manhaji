import 'dart:convert';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value.trim()) ??
        double.tryParse(value.trim())?.toInt() ??
        0;
  }
  return 0;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleaned = value.trim().replaceAll('%', '');
    return double.tryParse(cleaned) ?? 0;
  }
  return 0;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is DateTime) return value.toIso8601String();
  return value.toString();
}

String _asJsonString(dynamic value, {String fallback = '{}'}) {
  if (value == null) return fallback;
  if (value is String) return value;
  if (value is Map || value is List) return jsonEncode(value);
  return value.toString();
}

List<String> _stringList(dynamic value) {
  dynamic listValue = value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const [];
    try {
      listValue = jsonDecode(trimmed);
    } catch (_) {
      return [trimmed];
    }
  }

  if (listValue is! List) return const [];
  return listValue
      .map((item) => _asString(item).trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _riskLevel(dynamic value) {
  final level = _asString(value, fallback: 'LOW').trim().toUpperCase();
  return switch (level) {
    'LOW' || 'MEDIUM' || 'HIGH' => level,
    _ => 'LOW',
  };
}

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

  factory ProgressReportModel.fromJson(Map<dynamic, dynamic> json) {
    final data = _asMap(json);
    return ProgressReportModel(
      id: _asInt(data['id']),
      studentId: _asInt(data['studentId']),
      studentName: _asString(data['studentName']),
      periodStart: _asString(data['periodStart']),
      periodEnd: _asString(data['periodEnd']),
      summary: _asString(data['summary']),
      riskLevel: _riskLevel(data['riskLevel']),
      generatedAt: _asString(data['generatedAt']),
      strengths: _stringList(data['strengths']),
      improvements: _stringList(data['improvements']),
      recommendations: _stringList(data['recommendations']),
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

  factory PerformanceStats.fromJson(Map<dynamic, dynamic> json) {
    final data = _asMap(json);
    return PerformanceStats(
      completedLessons: _asInt(data['completedLessons']),
      totalLessons: _asInt(data['totalLessons']),
      inProgressLessons: _asInt(data['inProgressLessons']),
      averageMastery: _asDouble(data['averageMastery']),
      averageScore: _asDouble(data['averageScore']),
      totalPoints: _asInt(data['totalPoints']),
      currentStreak: _asInt(data['currentStreak']),
      quizzesTaken: _asInt(data['quizzesTaken']),
      hasActivity: _asBool(data['hasActivity']),
      subjects: (data['subjects'] is List ? data['subjects'] as List : const [])
          .whereType<Map>()
          .map((subject) => SubjectStat.fromJson(subject))
          .toList(growable: false),
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

  factory SubjectStat.fromJson(Map<dynamic, dynamic> json) {
    final data = _asMap(json);
    return SubjectStat(
      subjectName: _asString(data['subjectName']),
      completedLessons: _asInt(data['completedLessons']),
      totalLessons: _asInt(data['totalLessons']),
      averageMastery: _asDouble(data['averageMastery']),
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

  factory LearningPathModel.fromJson(Map<dynamic, dynamic> json) {
    final data = _asMap(json);
    return LearningPathModel(
      id: _asInt(data['id']),
      studentId: _asInt(data['studentId']),
      studentName: _asString(data['studentName']),
      recommendations: _asJsonString(data['recommendations']),
      generatedAt: _asString(data['generatedAt']),
    );
  }
}
