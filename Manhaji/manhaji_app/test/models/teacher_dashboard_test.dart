import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/teacher_dashboard.dart';

void main() {
  group('TeacherDashboard.fromJson', () {
    test('should parse complete dashboard', () {
      final json = {
        'teacherId': 10,
        'fullName': 'أستاذ أحمد',
        'department': 'اللغة العربية',
        'assignedGrade': 1,
        'totalStudents': 25,
        'activeThisWeek': 18,
        'lessonsCompletedTotal': 120,
        'averageMasteryAcrossClass': 72.5,
        'topStudents': [
          {
            'studentId': 1,
            'fullName': 'طالب متميز',
            'gradeLevel': 1,
            'totalPoints': 500,
            'currentStreak': 7,
            'lessonsCompleted': 10,
            'lessonsInProgress': 2,
            'averageMastery': 92.0,
          },
        ],
      };

      final dashboard = TeacherDashboard.fromJson(json);

      expect(dashboard.teacherId, 10);
      expect(dashboard.fullName, 'أستاذ أحمد');
      expect(dashboard.department, 'اللغة العربية');
      expect(dashboard.assignedGrade, 1);
      expect(dashboard.totalStudents, 25);
      expect(dashboard.activeThisWeek, 18);
      expect(dashboard.lessonsCompletedTotal, 120);
      expect(dashboard.averageMasteryAcrossClass, 72.5);
      expect(dashboard.topStudents, hasLength(1));
      expect(dashboard.topStudents.first.fullName, 'طالب متميز');
      expect(dashboard.topStudents.first.totalPoints, 500);
    });

    test('should handle empty top students list', () {
      final json = {
        'teacherId': 10,
        'fullName': 'معلم',
        'totalStudents': 0,
        'activeThisWeek': 0,
        'lessonsCompletedTotal': 0,
        'averageMasteryAcrossClass': 0,
        'topStudents': [],
      };

      final dashboard = TeacherDashboard.fromJson(json);

      expect(dashboard.topStudents, isEmpty);
    });

    test('should handle null topStudents', () {
      final json = {
        'teacherId': 10,
        'fullName': 'معلم',
        'totalStudents': 0,
        'activeThisWeek': 0,
        'lessonsCompletedTotal': 0,
        'averageMasteryAcrossClass': 0,
      };

      final dashboard = TeacherDashboard.fromJson(json);

      expect(dashboard.topStudents, isEmpty);
    });
  });

  group('ClassStudentSummary.fromJson', () {
    test('should parse student summary', () {
      final json = {
        'studentId': 1,
        'fullName': 'طالب',
        'email': 's@test.com',
        'gradeLevel': 1,
        'totalPoints': 250,
        'currentStreak': 5,
        'lessonsCompleted': 8,
        'lessonsInProgress': 3,
        'averageMastery': 78.5,
        'lastLoginAt': '2026-04-12T10:00:00',
      };

      final summary = ClassStudentSummary.fromJson(json);

      expect(summary.studentId, 1);
      expect(summary.totalPoints, 250);
      expect(summary.averageMastery, 78.5);
      expect(summary.lastLoginAt, '2026-04-12T10:00:00');
    });

    test('should handle missing fields with defaults', () {
      final json = <String, dynamic>{};

      final summary = ClassStudentSummary.fromJson(json);

      expect(summary.studentId, 0);
      expect(summary.fullName, '');
      expect(summary.gradeLevel, 1);
      expect(summary.totalPoints, 0);
      expect(summary.averageMastery, 0.0);
    });
  });

  group('SubjectMasterySummary.fromJson', () {
    test('should parse subject mastery', () {
      final json = {
        'subjectId': 1,
        'subjectName': 'الرياضيات',
        'totalLessons': 10,
        'lessonsCompleted': 7,
        'averageMastery': 85.0,
      };

      final mastery = SubjectMasterySummary.fromJson(json);

      expect(mastery.subjectId, 1);
      expect(mastery.subjectName, 'الرياضيات');
      expect(mastery.totalLessons, 10);
      expect(mastery.lessonsCompleted, 7);
      expect(mastery.averageMastery, 85.0);
    });
  });

  group('StudentDetail.fromJson', () {
    test('should parse full student detail', () {
      final json = {
        'studentId': 1,
        'fullName': 'طالب مفصل',
        'email': 'detail@test.com',
        'gradeLevel': 1,
        'totalPoints': 300,
        'currentStreak': 4,
        'lastLoginAt': '2026-04-12T15:00:00',
        'createdAt': '2026-01-01T00:00:00',
        'lessonsCompleted': 12,
        'lessonsInProgress': 3,
        'overallMastery': 75.5,
        'totalAttempts': 15,
        'averageScore': 82.3,
        'subjectBreakdown': [
          {
            'subjectId': 1,
            'subjectName': 'العربية',
            'totalLessons': 5,
            'lessonsCompleted': 4,
            'averageMastery': 88.0,
          },
        ],
      };

      final detail = StudentDetail.fromJson(json);

      expect(detail.studentId, 1);
      expect(detail.lessonsCompleted, 12);
      expect(detail.overallMastery, 75.5);
      expect(detail.subjectBreakdown, hasLength(1));
      expect(detail.subjectBreakdown.first.subjectName, 'العربية');
    });

    test('should handle empty subject breakdown', () {
      final json = {
        'studentId': 1,
        'fullName': 'Test',
        'gradeLevel': 1,
        'totalPoints': 0,
        'currentStreak': 0,
        'lessonsCompleted': 0,
        'lessonsInProgress': 0,
        'overallMastery': 0,
        'totalAttempts': 0,
        'averageScore': 0,
        'subjectBreakdown': null,
      };

      final detail = StudentDetail.fromJson(json);

      expect(detail.subjectBreakdown, isEmpty);
    });
  });
}
