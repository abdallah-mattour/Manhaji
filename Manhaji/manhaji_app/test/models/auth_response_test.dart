import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/auth_response.dart';

void main() {
  group('AuthResponse.fromJson', () {
    test('should parse full student response correctly', () {
      final json = {
        'accessToken': 'abc123',
        'refreshToken': 'ref456',
        'userId': 1,
        'fullName': 'طالب جديد',
        'email': 'student@test.com',
        'phone': '0591234567',
        'role': 'STUDENT',
        'gradeLevel': 1,
      };

      final response = AuthResponse.fromJson(json);

      expect(response.accessToken, 'abc123');
      expect(response.refreshToken, 'ref456');
      expect(response.userId, 1);
      expect(response.fullName, 'طالب جديد');
      expect(response.email, 'student@test.com');
      expect(response.phone, '0591234567');
      expect(response.role, 'STUDENT');
      expect(response.gradeLevel, 1);
    });

    test('should parse teacher response without gradeLevel', () {
      final json = {
        'accessToken': 'token',
        'refreshToken': 'refresh',
        'userId': 2,
        'fullName': 'معلم',
        'email': 'teacher@test.com',
        'role': 'TEACHER',
      };

      final response = AuthResponse.fromJson(json);

      expect(response.role, 'TEACHER');
      expect(response.gradeLevel, isNull);
      expect(response.phone, isNull);
    });

    test('should handle missing fields with defaults', () {
      final json = <String, dynamic>{};

      final response = AuthResponse.fromJson(json);

      expect(response.accessToken, '');
      expect(response.refreshToken, '');
      expect(response.userId, 0);
      expect(response.fullName, '');
      expect(response.role, 'STUDENT');
      expect(response.email, isNull);
      expect(response.phone, isNull);
      expect(response.gradeLevel, isNull);
    });
  });
}
