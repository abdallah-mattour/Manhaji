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

class ParentDashboard {
  final int parentId;
  final String fullName;
  final List<ChildSummary> children;

  ParentDashboard({
    required this.parentId,
    required this.fullName,
    required this.children,
  });

  factory ParentDashboard.fromJson(Map<String, dynamic> json) {
    return ParentDashboard(
      parentId: json['parentId'] ?? 0,
      fullName: json['fullName'] ?? '',
      children: (json['children'] as List?)
              ?.map((c) => ChildSummary.fromJson(c))
              .toList() ??
          [],
    );
  }
}
