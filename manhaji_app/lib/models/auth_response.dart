class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final int? gradeLevel;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.gradeLevel,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'STUDENT',
      gradeLevel: json['gradeLevel'],
    );
  }
}
