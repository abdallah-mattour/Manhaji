class ProgressSummary {
  final int totalLessons;
  final int completedLessons;
  final int masteredLessons;
  final int inProgressLessons;
  final double overallMastery;
  final int totalPoints;
  final int currentStreak;
  final int totalQuizzesTaken;
  final double averageQuizScore;
  final List<SubjectProgress> subjectProgress;
  final List<RecentActivity> recentActivity;

  ProgressSummary({
    required this.totalLessons,
    required this.completedLessons,
    required this.masteredLessons,
    required this.inProgressLessons,
    required this.overallMastery,
    required this.totalPoints,
    required this.currentStreak,
    required this.totalQuizzesTaken,
    required this.averageQuizScore,
    required this.subjectProgress,
    required this.recentActivity,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      totalLessons: json['totalLessons'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      masteredLessons: json['masteredLessons'] ?? 0,
      inProgressLessons: json['inProgressLessons'] ?? 0,
      overallMastery: (json['overallMastery'] ?? 0.0).toDouble(),
      totalPoints: json['totalPoints'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      totalQuizzesTaken: json['totalQuizzesTaken'] ?? 0,
      averageQuizScore: (json['averageQuizScore'] ?? 0.0).toDouble(),
      subjectProgress: (json['subjectProgress'] as List?)
              ?.map((s) => SubjectProgress.fromJson(s))
              .toList() ??
          [],
      recentActivity: (json['recentActivity'] as List?)
              ?.map((a) => RecentActivity.fromJson(a))
              .toList() ??
          [],
    );
  }

  double get completionPercent =>
      totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0;
}

class SubjectProgress {
  final int subjectId;
  final String subjectName;
  final int totalLessons;
  final int completedLessons;
  final double masteryPercent;

  SubjectProgress({
    required this.subjectId,
    required this.subjectName,
    required this.totalLessons,
    required this.completedLessons,
    required this.masteryPercent,
  });

  factory SubjectProgress.fromJson(Map<String, dynamic> json) {
    return SubjectProgress(
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      totalLessons: json['totalLessons'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      masteryPercent: (json['masteryPercent'] ?? 0.0).toDouble(),
    );
  }

  double get progressPercent =>
      totalLessons > 0 ? completedLessons / totalLessons : 0.0;
}

class RecentActivity {
  final String type;
  final String title;
  final String subjectName;
  final double? score;
  final int? pointsEarned;
  final String? timestamp;

  RecentActivity({
    required this.type,
    required this.title,
    required this.subjectName,
    this.score,
    this.pointsEarned,
    this.timestamp,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      subjectName: json['subjectName'] ?? '',
      score: json['score']?.toDouble(),
      pointsEarned: json['pointsEarned'],
      timestamp: json['timestamp'],
    );
  }

  bool get isQuiz => type == 'QUIZ_COMPLETED';
  bool get isLesson => type == 'LESSON_VIEWED';
}

class LeaderboardEntry {
  final int rank;
  final int studentId;
  final String studentName;
  final String? avatarId;
  final int totalPoints;
  final int completedLessons;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.studentId,
    required this.studentName,
    this.avatarId,
    required this.totalPoints,
    required this.completedLessons,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      avatarId: json['avatarId'],
      totalPoints: json['totalPoints'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      isCurrentUser: json['currentUser'] ?? false,
    );
  }
}
