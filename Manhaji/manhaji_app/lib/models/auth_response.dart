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

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

String? _asOptionalString(dynamic value) {
  final text = _asString(value).trim();
  return text.isEmpty ? null : text;
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String role;
  final int? gradeLevel;
  final String? avatarId;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.gradeLevel,
    this.avatarId,
  });

  bool get hasTokens => accessToken.isNotEmpty && refreshToken.isNotEmpty;

  factory AuthResponse.fromJson(Map<dynamic, dynamic> json) {
    final data = _asMap(json);
    return AuthResponse(
      accessToken: _asString(data['accessToken']),
      refreshToken: _asString(data['refreshToken']),
      userId: _asInt(data['userId']),
      fullName: _asString(data['fullName']),
      email: _asOptionalString(data['email']),
      phone: _asOptionalString(data['phone']),
      role: _asString(data['role'], fallback: 'STUDENT').toUpperCase(),
      gradeLevel: data.containsKey('gradeLevel')
          ? _asInt(data['gradeLevel'])
          : null,
      avatarId: _asOptionalString(data['avatarId']),
    );
  }
}
