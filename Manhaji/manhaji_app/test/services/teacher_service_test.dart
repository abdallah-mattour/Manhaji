import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/config/api_config.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeApiService extends ApiService {
  FakeApiService() : super(FakeLocalStorage());

  final Map<String, Map<String, dynamic>> getResponses = {};
  final List<String> getPaths = [];
  final List<Map<String, dynamic>?> getQueryParams = [];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    getPaths.add(path);
    getQueryParams.add(queryParams);
    return getResponses[path] ?? const {'data': null};
  }
}

void main() {
  late FakeApiService api;
  late TeacherService service;

  setUp(() {
    api = FakeApiService();
    service = TeacherService(api);
  });

  group('TeacherService mistake analytics', () {
    test(
      'calls mistake analytics endpoint with filters and parses rows',
      () async {
        api.getResponses[ApiConfig.teacherMistakes] = {
          'data': {
            'summary': {
              'totalMistakes': 3,
              'affectedStudents': 2,
              'mostMistakenLessonTitle': 'حرف الراء',
              'mostMistakenQuestionText': 'اختر الكلمة الصحيحة',
            },
            'mistakes': [
              {
                'studentId': 1,
                'studentName': 'ليان أحمد',
                'subjectId': 10,
                'subjectName': 'اللغة العربية',
                'lessonId': 20,
                'lessonTitle': 'حرف الراء',
                'questionId': 30,
                'questionText': 'اختر الكلمة الصحيحة',
                'studentAnswer': 'باب',
                'correctAnswer': 'رمان',
                'mistakeCount': 2,
                'lastMistakeAt': '2026-07-05T10:15:00',
                'commonMistake': true,
                'affectedStudentsForQuestion': 2,
              },
            ],
          },
        };

        final analytics = await service.getMistakeAnalytics(
          subjectId: 10,
          lessonId: 20,
          studentId: 1,
          limit: 25,
        );

        expect(api.getPaths, [ApiConfig.teacherMistakes]);
        expect(api.getQueryParams.single, {
          'subjectId': 10,
          'lessonId': 20,
          'studentId': 1,
          'limit': 25,
        });
        expect(analytics.summary.totalMistakes, 3);
        expect(analytics.summary.affectedStudents, 2);
        expect(analytics.mistakes, hasLength(1));
        expect(analytics.mistakes.first.studentName, 'ليان أحمد');
        expect(analytics.mistakes.first.commonMistake, isTrue);
      },
    );
  });
}
