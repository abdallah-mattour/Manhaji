import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/admin_stats.dart';

void main() {
  group('AdminStats.fromJson', () {
    test('should parse complete stats', () {
      final json = {
        'totalStudents': 150,
        'totalTeachers': 12,
        'totalParents': 80,
        'totalAdmins': 2,
        'totalSubjects': 6,
        'totalLessons': 48,
        'totalAttempts': 320,
        'totalCompletedLessons': 210,
        'activeStudentsThisWeek': 95,
      };

      final stats = AdminStats.fromJson(json);

      expect(stats.totalStudents, 150);
      expect(stats.totalTeachers, 12);
      expect(stats.totalParents, 80);
      expect(stats.totalAdmins, 2);
      expect(stats.totalSubjects, 6);
      expect(stats.totalLessons, 48);
      expect(stats.totalAttempts, 320);
      expect(stats.totalCompletedLessons, 210);
      expect(stats.activeStudentsThisWeek, 95);
    });

    test('should default to zero for missing fields', () {
      final json = <String, dynamic>{};

      final stats = AdminStats.fromJson(json);

      expect(stats.totalStudents, 0);
      expect(stats.totalTeachers, 0);
      expect(stats.totalParents, 0);
      expect(stats.totalAdmins, 0);
      expect(stats.totalSubjects, 0);
      expect(stats.totalLessons, 0);
      expect(stats.totalAttempts, 0);
      expect(stats.totalCompletedLessons, 0);
      expect(stats.activeStudentsThisWeek, 0);
    });
  });

  group('UserSummary.fromJson', () {
    test('should parse student user summary with grade level', () {
      final json = {
        'userId': 1,
        'fullName': 'طالب جديد',
        'email': 'student@test.com',
        'phone': '0591234567',
        'role': 'STUDENT',
        'isActive': true,
        'lastLoginAt': '2026-04-12T10:00:00',
        'createdAt': '2026-01-01T00:00:00',
        'gradeLevel': 1,
      };

      final summary = UserSummary.fromJson(json);

      expect(summary.userId, 1);
      expect(summary.fullName, 'طالب جديد');
      expect(summary.email, 'student@test.com');
      expect(summary.role, 'STUDENT');
      expect(summary.isActive, true);
      expect(summary.gradeLevel, 1);
    });

    test('should parse teacher without grade level', () {
      final json = {
        'userId': 2,
        'fullName': 'معلم',
        'role': 'TEACHER',
        'isActive': true,
      };

      final summary = UserSummary.fromJson(json);

      expect(summary.role, 'TEACHER');
      expect(summary.gradeLevel, isNull);
      expect(summary.email, isNull);
      expect(summary.phone, isNull);
    });

    test('should handle missing isActive with default true', () {
      final json = {
        'userId': 3,
        'fullName': 'مسؤول',
        'role': 'ADMIN',
      };

      final summary = UserSummary.fromJson(json);

      expect(summary.isActive, true);
    });
  });
}
