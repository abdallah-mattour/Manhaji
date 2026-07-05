import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/parent_dashboard.dart';

void main() {
  group('ParentDashboard.fromJson', () {
    test('parses full JSON', () {
      final json = {
        'parentId': 121,
        'fullName': 'أم ليان',
        'children': [
          {
            'studentId': 131,
            'fullName': 'ليان أحمد',
            'avatarId': 'avatar-1',
            'gradeLevel': 1,
            'totalPoints': 460,
            'currentStreak': 3,
            'lessonsCompleted': 12,
            'totalLessons': 24,
            'overallMastery': 88.0,
            'lastLoginAt': '2026-07-04T10:00:00',
          },
        ],
        'recentActivityAcrossChildren': [
          {
            'attemptId': 900,
            'quizTitle': 'اختبار حرف الراء',
            'lessonTitle': 'حرف الراء',
            'subjectName': 'اللغة العربية',
            'score': 85,
            'status': 'GRADED',
            'attemptedAt': '2026-07-04T11:00:00',
          },
        ],
        'alerts': [
          {
            'studentId': 131,
            'alertType': 'LOW_MASTERY',
            'message': 'يحتاج بعض المتابعة',
            'severity': 'HIGH',
            'studentName': 'ليان أحمد',
          },
        ],
        'recommendations': [
          {
            'type': 'PRACTICE',
            'title': 'تدريب يومي قصير',
            'message': 'خصص 10 دقائق يومياً للمراجعة.',
            'priority': 'HIGH',
            'studentName': 'ليان أحمد',
            'subjectName': 'اللغة العربية',
            'actionLabel': 'ابدأ الآن',
          },
        ],
      };

      final dashboard = ParentDashboard.fromJson(json);

      expect(dashboard.parentId, 121);
      expect(dashboard.fullName, 'أم ليان');
      expect(dashboard.children, hasLength(1));
      expect(dashboard.children.first.studentId, 131);
      expect(dashboard.children.first.fullName, 'ليان أحمد');
      expect(dashboard.children.first.overallMastery, 88.0);
      expect(dashboard.recentActivityAcrossChildren, hasLength(1));
      expect(
        dashboard.recentActivityAcrossChildren.first.quizTitle,
        'اختبار حرف الراء',
      );
      expect(dashboard.alerts, hasLength(1));
      expect(dashboard.alerts.first.severity, 'HIGH');
      expect(dashboard.recommendations, hasLength(1));
      expect(dashboard.recommendations.first.actionLabel, 'ابدأ الآن');
    });

    test('missing, empty, and null lists fallback safely', () {
      final cases = <String, Map<String, dynamic>>{
        'missing': {'parentId': 1, 'fullName': 'ولي أمر'},
        'empty': {
          'parentId': 1,
          'fullName': 'ولي أمر',
          'children': [],
          'recentActivityAcrossChildren': [],
          'alerts': [],
          'recommendations': [],
        },
        'null': {
          'parentId': 1,
          'fullName': 'ولي أمر',
          'children': null,
          'recentActivityAcrossChildren': null,
          'alerts': null,
          'recommendations': null,
        },
      };

      for (final entry in cases.entries) {
        final dashboard = ParentDashboard.fromJson(entry.value);

        expect(dashboard.children, isEmpty, reason: entry.key);
        expect(
          dashboard.recentActivityAcrossChildren,
          isEmpty,
          reason: entry.key,
        );
        expect(dashboard.alerts, isEmpty, reason: entry.key);
        expect(dashboard.recommendations, isEmpty, reason: entry.key);
      }
    });
  });
}
