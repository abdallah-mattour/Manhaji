import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/student_assigned_quiz.dart';
import 'package:manhaji_app/providers/student_assigned_quiz_provider.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/quiz_service.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeQuizService extends QuizApiService {
  FakeQuizService() : super(ApiService(FakeLocalStorage()));

  List<StudentAssignedQuizSummary> quizzes = const [];
  StudentAssignedQuizDetail? detail;
  bool throwOnList = false;
  bool throwOnDetail = false;

  @override
  Future<List<StudentAssignedQuizSummary>> getAssignedQuizzes() async {
    if (throwOnList) throw Exception('list failed');
    return quizzes;
  }

  @override
  Future<StudentAssignedQuizDetail> getAssignedQuizDetail(
    int assignmentId,
  ) async {
    if (throwOnDetail) throw Exception('detail failed');
    return detail!;
  }
}

StudentAssignedQuizSummary _summary() => const StudentAssignedQuizSummary(
  assignmentId: 70,
  quizId: 44,
  title: 'اختبار الحروف',
  subjectName: 'اللغة العربية',
  questionCount: 2,
  status: 'ASSIGNED',
  attemptsUsed: 0,
  maxAttempts: 1,
  canStart: true,
);

void main() {
  test('loads assigned quizzes successfully', () async {
    final service = FakeQuizService()..quizzes = [_summary()];
    final provider = StudentAssignedQuizProvider(service);

    await provider.loadAssignedQuizzes();

    expect(provider.isLoading, isFalse);
    expect(provider.errorMessage, isNull);
    expect(provider.assignedQuizzes.single.title, 'اختبار الحروف');
  });

  test('handles assigned quiz list errors', () async {
    final service = FakeQuizService()..throwOnList = true;
    final provider = StudentAssignedQuizProvider(service);

    await provider.loadAssignedQuizzes();

    expect(provider.isLoading, isFalse);
    expect(provider.assignedQuizzes, isEmpty);
    expect(provider.errorMessage, 'حدث خطأ غير متوقع');
  });
}
