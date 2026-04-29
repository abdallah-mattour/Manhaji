class ClassStudentSummary {
  final int studentId;
  final String fullName;
  final String? email;
  final int gradeLevel;
  final int totalPoints;
  final int currentStreak;
  final int lessonsCompleted;
  final int lessonsInProgress;
  final double averageMastery;
  final String? lastLoginAt;

  ClassStudentSummary({
    required this.studentId,
    required this.fullName,
    this.email,
    required this.gradeLevel,
    required this.totalPoints,
    required this.currentStreak,
    required this.lessonsCompleted,
    required this.lessonsInProgress,
    required this.averageMastery,
    this.lastLoginAt,
  });

  factory ClassStudentSummary.fromJson(Map<String, dynamic> json) {
    return ClassStudentSummary(
      studentId: json['studentId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'],
      gradeLevel: json['gradeLevel'] ?? 1,
      totalPoints: json['totalPoints'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      lessonsCompleted: json['lessonsCompleted'] ?? 0,
      lessonsInProgress: json['lessonsInProgress'] ?? 0,
      averageMastery: (json['averageMastery'] ?? 0).toDouble(),
      lastLoginAt: json['lastLoginAt'],
    );
  }
}

class TeacherDashboard {
  final int teacherId;
  final String fullName;
  final String? department;
  final int? assignedGrade;
  final int totalStudents;
  final int activeThisWeek;
  final int lessonsCompletedTotal;
  final double averageMasteryAcrossClass;
  final List<ClassStudentSummary> topStudents;

  TeacherDashboard({
    required this.teacherId,
    required this.fullName,
    this.department,
    this.assignedGrade,
    required this.totalStudents,
    required this.activeThisWeek,
    required this.lessonsCompletedTotal,
    required this.averageMasteryAcrossClass,
    required this.topStudents,
  });

  factory TeacherDashboard.fromJson(Map<String, dynamic> json) {
    return TeacherDashboard(
      teacherId: json['teacherId'] ?? 0,
      fullName: json['fullName'] ?? '',
      department: json['department'],
      assignedGrade: json['assignedGrade'],
      totalStudents: json['totalStudents'] ?? 0,
      activeThisWeek: json['activeThisWeek'] ?? 0,
      lessonsCompletedTotal: json['lessonsCompletedTotal'] ?? 0,
      averageMasteryAcrossClass: (json['averageMasteryAcrossClass'] ?? 0).toDouble(),
      topStudents: (json['topStudents'] as List?)
              ?.map((s) => ClassStudentSummary.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class SubjectMasterySummary {
  final int subjectId;
  final String subjectName;
  final int totalLessons;
  final int lessonsCompleted;
  final double averageMastery;

  SubjectMasterySummary({
    required this.subjectId,
    required this.subjectName,
    required this.totalLessons,
    required this.lessonsCompleted,
    required this.averageMastery,
  });

  factory SubjectMasterySummary.fromJson(Map<String, dynamic> json) {
    return SubjectMasterySummary(
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      totalLessons: json['totalLessons'] ?? 0,
      lessonsCompleted: json['lessonsCompleted'] ?? 0,
      averageMastery: (json['averageMastery'] ?? 0).toDouble(),
    );
  }
}

class StudentDetail {
  final int studentId;
  final String fullName;
  final String? email;
  final String? phone;
  final int gradeLevel;
  final int totalPoints;
  final int currentStreak;
  final String? lastLoginAt;
  final String? createdAt;
  final int lessonsCompleted;
  final int lessonsInProgress;
  final double overallMastery;
  final int totalAttempts;
  final double averageScore;
  final List<SubjectMasterySummary> subjectBreakdown;

  StudentDetail({
    required this.studentId,
    required this.fullName,
    this.email,
    this.phone,
    required this.gradeLevel,
    required this.totalPoints,
    required this.currentStreak,
    this.lastLoginAt,
    this.createdAt,
    required this.lessonsCompleted,
    required this.lessonsInProgress,
    required this.overallMastery,
    required this.totalAttempts,
    required this.averageScore,
    required this.subjectBreakdown,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> json) {
    return StudentDetail(
      studentId: json['studentId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      gradeLevel: json['gradeLevel'] ?? 1,
      totalPoints: json['totalPoints'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      lastLoginAt: json['lastLoginAt'],
      createdAt: json['createdAt'],
      lessonsCompleted: json['lessonsCompleted'] ?? 0,
      lessonsInProgress: json['lessonsInProgress'] ?? 0,
      overallMastery: (json['overallMastery'] ?? 0).toDouble(),
      totalAttempts: json['totalAttempts'] ?? 0,
      averageScore: (json['averageScore'] ?? 0).toDouble(),
      subjectBreakdown: (json['subjectBreakdown'] as List?)
              ?.map((s) => SubjectMasterySummary.fromJson(s))
              .toList() ??
          [],
    );
  }
}
