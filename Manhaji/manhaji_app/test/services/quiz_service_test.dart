import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/config/api_config.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/quiz_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeApiService extends ApiService {
  FakeApiService() : super(FakeLocalStorage());

  final Map<String, Map<String, dynamic>> getResponses = {};
  final Map<String, Map<String, dynamic>> postResponses = {};
  final List<String> getPaths = [];
  final List<String> postPaths = [];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
  }) async {
    getPaths.add(path);
    return getResponses[path] ?? const {'data': null};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    postPaths.add(path);
    return postResponses[path] ?? const {'data': null};
  }
}

void main() {
  late FakeApiService api;
  late QuizApiService service;

  setUp(() {
    api = FakeApiService();
    service = QuizApiService(api);
  });

  test('assigned quizzes use student assignment endpoints', () async {
    api.getResponses[ApiConfig.studentAssignedQuizzes] = {
      'data': [
        {
          'assignmentId': 70,
          'quizId': 44,
          'title': 'اختبار الحروف',
          'subjectName': 'اللغة العربية',
          'questionCount': 2,
          'dueAt': '2026-07-07T10:00:00',
          'status': 'ASSIGNED',
          'attemptsUsed': 0,
          'maxAttempts': 1,
          'canStart': true,
        },
      ],
    };
    api.getResponses[ApiConfig.studentAssignedQuiz(70)] = {
      'data': {
        'assignmentId': 70,
        'quizId': 44,
        'title': 'اختبار الحروف',
        'subjectId': 10,
        'subjectName': 'اللغة العربية',
        'questionCount': 1,
        'status': 'ASSIGNED',
        'attemptsUsed': 0,
        'maxAttempts': 1,
        'canStart': true,
        'questions': [
          {
            'id': 30,
            'type': 'MCQ',
            'questionText': 'اختر الكلمة الصحيحة',
            'options': ['رمان', 'باب'],
            'difficultyLevel': 1,
          },
        ],
      },
    };
    api.postResponses[ApiConfig.startAssignedQuizAttempt(70)] = {
      'data': {
        'attemptId': 900,
        'quizId': 44,
        'status': 'IN_PROGRESS',
        'totalQuestions': 1,
        'correctAnswers': 0,
        'pointsEarned': 0,
        'answers': [],
      },
    };

    final quizzes = await service.getAssignedQuizzes();
    final detail = await service.getAssignedQuizDetail(70);
    final attempt = await service.startAssignedQuizAttempt(70);

    expect(api.getPaths, [
      ApiConfig.studentAssignedQuizzes,
      ApiConfig.studentAssignedQuiz(70),
    ]);
    expect(api.postPaths, [ApiConfig.startAssignedQuizAttempt(70)]);
    expect(api.postPaths, isNot(contains('${ApiConfig.startAttempt}/44')));
    expect(quizzes.single.assignmentId, 70);
    expect(detail.questions.single.id, 30);
    expect(attempt.attemptId, 900);
  });
}
