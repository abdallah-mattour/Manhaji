class AdminStats {
  final int totalStudents;
  final int totalTeachers;
  final int totalParents;
  final int totalAdmins;
  final int totalSubjects;
  final int totalLessons;
  final int totalAttempts;
  final int totalCompletedLessons;
  final int activeStudentsThisWeek;

  AdminStats({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalParents,
    required this.totalAdmins,
    required this.totalSubjects,
    required this.totalLessons,
    required this.totalAttempts,
    required this.totalCompletedLessons,
    required this.activeStudentsThisWeek,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalStudents: json['totalStudents'] ?? 0,
      totalTeachers: json['totalTeachers'] ?? 0,
      totalParents: json['totalParents'] ?? 0,
      totalAdmins: json['totalAdmins'] ?? 0,
      totalSubjects: json['totalSubjects'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      totalAttempts: json['totalAttempts'] ?? 0,
      totalCompletedLessons: json['totalCompletedLessons'] ?? 0,
      activeStudentsThisWeek: json['activeStudentsThisWeek'] ?? 0,
    );
  }
}

class UserSummary {
  final int userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final bool isActive;
  final String? lastLoginAt;
  final String? createdAt;
  final int? gradeLevel;

  UserSummary({
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
    this.createdAt,
    this.gradeLevel,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? '',
      isActive: json['isActive'] ?? true,
      lastLoginAt: json['lastLoginAt'],
      createdAt: json['createdAt'],
      gradeLevel: json['gradeLevel'],
    );
  }
}
