import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/ai_report.dart';

void main() {
  group('ProgressReportModel.fromJson', () {
    test('should parse complete report', () {
      final json = {
        'id': 1,
        'studentId': 10,
        'studentName': 'طالب أحمد',
        'periodStart': '2026-03-01',
        'periodEnd': '2026-04-01',
        'summary': 'أداء الطالب جيد مع تقدم ملحوظ في الرياضيات',
        'riskLevel': 'LOW',
        'generatedAt': '2026-04-13T10:00:00',
      };

      final report = ProgressReportModel.fromJson(json);

      expect(report.id, 1);
      expect(report.studentId, 10);
      expect(report.studentName, 'طالب أحمد');
      expect(report.periodStart, '2026-03-01');
      expect(report.periodEnd, '2026-04-01');
      expect(report.summary, contains('أداء الطالب جيد'));
      expect(report.riskLevel, 'LOW');
    });

    test('should default riskLevel to LOW when missing', () {
      final json = {
        'id': 2,
        'studentId': 10,
        'studentName': 'Test',
        'periodStart': '',
        'periodEnd': '',
        'summary': '',
        'generatedAt': '',
      };

      final report = ProgressReportModel.fromJson(json);

      expect(report.riskLevel, 'LOW');
    });

    test('should handle empty JSON with safe defaults', () {
      final json = <String, dynamic>{};

      final report = ProgressReportModel.fromJson(json);

      expect(report.id, 0);
      expect(report.studentId, 0);
      expect(report.studentName, '');
      expect(report.summary, '');
      expect(report.riskLevel, 'LOW');
    });

    test('should coerce mixed backend values without throwing', () {
      final report = ProgressReportModel.fromJson({
        'id': '7',
        'studentId': 12.0,
        'studentName': 123,
        'periodStart': DateTime(2026, 4, 1),
        'summary': null,
        'riskLevel': 'medium',
        'strengths': '["قراءة جيدة", 45]',
        'improvements': ['المراجعة', null, ''],
        'recommendations': 'تمرّن يومياً',
      });

      expect(report.id, 7);
      expect(report.studentId, 12);
      expect(report.studentName, '123');
      expect(report.periodStart, startsWith('2026-04-01'));
      expect(report.summary, '');
      expect(report.riskLevel, 'MEDIUM');
      expect(report.strengths, ['قراءة جيدة', '45']);
      expect(report.improvements, ['المراجعة']);
      expect(report.recommendations, ['تمرّن يومياً']);
    });
  });

  group('PerformanceStats.fromJson', () {
    test(
      'should parse stats with string numbers and ignore invalid subjects',
      () {
        final stats = PerformanceStats.fromJson({
          'completedLessons': '3',
          'totalLessons': 10.0,
          'inProgressLessons': '2.0',
          'averageMastery': '81.5%',
          'averageScore': 72,
          'totalPoints': '140',
          'currentStreak': '4',
          'quizzesTaken': 5.0,
          'hasActivity': 'true',
          'subjects': [
            {
              'subjectName': 'رياضيات',
              'completedLessons': '2',
              'totalLessons': '6',
              'averageMastery': '75.5',
            },
            'bad subject row',
          ],
        });

        expect(stats.completedLessons, 3);
        expect(stats.totalLessons, 10);
        expect(stats.inProgressLessons, 2);
        expect(stats.averageMastery, 81.5);
        expect(stats.averageScore, 72);
        expect(stats.totalPoints, 140);
        expect(stats.currentStreak, 4);
        expect(stats.quizzesTaken, 5);
        expect(stats.hasActivity, true);
        expect(stats.subjects, hasLength(1));
        expect(stats.subjects.first.subjectName, 'رياضيات');
        expect(stats.subjects.first.averageMastery, 75.5);
      },
    );
  });

  group('LearningPathModel.fromJson', () {
    test('should parse complete learning path', () {
      final json = {
        'id': 1,
        'studentId': 10,
        'studentName': 'طالب أحمد',
        'recommendations':
            '{"reviewLessons":["الدرس 1"],"activities":["تمرين القراءة"],"tips":["القراءة يومياً"]}',
        'generatedAt': '2026-04-13T10:00:00',
      };

      final path = LearningPathModel.fromJson(json);

      expect(path.id, 1);
      expect(path.studentId, 10);
      expect(path.studentName, 'طالب أحمد');
      expect(path.recommendations, contains('reviewLessons'));
    });

    test('should default recommendations to empty JSON object', () {
      final json = {
        'id': 2,
        'studentId': 10,
        'studentName': 'Test',
        'generatedAt': '',
      };

      final path = LearningPathModel.fromJson(json);

      expect(path.recommendations, '{}');
    });

    test('should handle empty JSON with safe defaults', () {
      final json = <String, dynamic>{};

      final path = LearningPathModel.fromJson(json);

      expect(path.id, 0);
      expect(path.studentId, 0);
      expect(path.studentName, '');
      expect(path.recommendations, '{}');
    });

    test('should encode structured recommendations as JSON', () {
      final path = LearningPathModel.fromJson({
        'recommendations': {
          'reviewLessons': ['الدرس 1'],
          'activities': ['تدريب'],
        },
      });

      expect(path.recommendations, contains('reviewLessons'));
      expect(path.recommendations, contains('الدرس 1'));
    });
  });
}
