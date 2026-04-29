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
  });
}
