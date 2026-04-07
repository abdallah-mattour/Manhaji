class User {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final int? gradeLevel;
  final String? avatarId;
  final int currentStreak;
  final int totalPoints;

  User({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.gradeLevel,
    this.avatarId,
    this.currentStreak = 0,
    this.totalPoints = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] ?? json['studentId'] ?? json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'STUDENT',
      gradeLevel: json['gradeLevel'],
      avatarId: json['avatarId'],
      currentStreak: json['currentStreak'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
    );
  }
}
