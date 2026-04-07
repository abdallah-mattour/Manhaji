import 'subject.dart';

class Dashboard {
  final int studentId;
  final String fullName;
  final String? avatarId;
  final int gradeLevel;
  final int currentStreak;
  final int totalPoints;
  final List<Subject> subjects;

  Dashboard({
    required this.studentId,
    required this.fullName,
    this.avatarId,
    required this.gradeLevel,
    required this.currentStreak,
    required this.totalPoints,
    required this.subjects,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      studentId: json['studentId'] ?? 0,
      fullName: json['fullName'] ?? '',
      avatarId: json['avatarId'],
      gradeLevel: json['gradeLevel'] ?? 1,
      currentStreak: json['currentStreak'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      subjects: (json['subjects'] as List?)
              ?.map((s) => Subject.fromJson(s))
              .toList() ??
          [],
    );
  }
}
