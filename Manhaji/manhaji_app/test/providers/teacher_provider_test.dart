import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/models/question_bank.dart';
import 'package:manhaji_app/models/teacher_dashboard.dart';
import 'package:manhaji_app/models/teacher_mistake_analytics.dart';
import 'package:manhaji_app/models/teacher_quiz.dart';
import 'package:manhaji_app/providers/teacher_provider.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';

/// Minimal LocalStorageService fake
class FakeLocalStorage extends Fake implements LocalStorageService {}

/// Manual mock for TeacherService
class MockTeacherService extends TeacherService {
  TeacherDashboard? dashboardResult;
  List<ClassStudentSummary>? studentsResult;
  List<SubjectSummary>? assignedSubjectsResult;
  StudentDetail? studentDetailResult;
  TeacherMistakeAnalytics? mistakeAnalyticsResult;
  List<TeacherQuizSummary>? teacherQuizzesResult;
  QuestionBankResponse? quizQuestionBankResult;
  TeacherQuizDetail? createdQuizResult;
  String? lastCreatedTitle;
  int? lastCreatedSubjectId;
  int? lastCreatedLessonId;
  List<int>? lastCreatedQuestionIds;
  Exception? errorToThrow;

  MockTeacherService() : super(ApiService(FakeLocalStorage()));

  @override
  Future<TeacherDashboard> getDashboard() async {
    if (errorToThrow != null) throw errorToThrow!;
    return dashboardResult!;
  }

  @override
  Future<List<ClassStudentSummary>> getStudents() async {
    if (errorToThrow != null) throw errorToThrow!;
    return studentsResult!;
  }

  @override
  Future<List<SubjectSummary>> getAssignedSubjects() async {
    if (errorToThrow != null) throw errorToThrow!;
    return assignedSubjectsResult!;
  }

  @override
  Future<StudentDetail> getStudentDetail(int studentId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return studentDetailResult!;
  }

  @override
  Future<TeacherMistakeAnalytics> getMistakeAnalytics({
    int? subjectId,
    int? lessonId,
    int? studentId,
    int? limit,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return mistakeAnalyticsResult!;
  }

  @override
  Future<List<TeacherQuizSummary>> getTeacherQuizzes() async {
    if (errorToThrow != null) throw errorToThrow!;
    return teacherQuizzesResult!;
  }

  @override
  Future<QuestionBankResponse> getQuestionsForSubject(
    int subjectId, {
    int? difficulty,
    int? lessonId,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return quizQuestionBankResult!;
  }

  @override
  Future<TeacherQuizDetail> createTeacherQuiz({
    required String title,
    required int subjectId,
    int? lessonId,
    required List<int> questionIds,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    lastCreatedTitle = title;
    lastCreatedSubjectId = subjectId;
    lastCreatedLessonId = lessonId;
    lastCreatedQuestionIds = questionIds;
    return createdQuizResult!;
  }
}

void main() {
  late MockTeacherService mockService;
  late TeacherProvider provider;

  setUp(() {
    mockService = MockTeacherService();
    provider = TeacherProvider(mockService);
  });

  group('TeacherProvider', () {
    group('loadDashboard()', () {
      test('should load dashboard successfully', () async {
        mockService.dashboardResult = TeacherDashboard(
          teacherId: 10,
          fullName: 'أستاذ أحمد',
          department: 'اللغة العربية',
          assignedGrade: 1,
          totalStudents: 25,
          activeThisWeek: 18,
          lessonsCompletedTotal: 120,
          averageMasteryAcrossClass: 72.5,
          topStudents: [],
        );

        await provider.loadDashboard();

        expect(provider.dashboard, isNotNull);
        expect(provider.dashboard!.teacherId, 10);
        expect(provider.dashboard!.fullName, 'أستاذ أحمد');
        expect(provider.dashboard!.totalStudents, 25);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('should set error on failure', () async {
        mockService.errorToThrow = Exception('Network error');

        await provider.loadDashboard();

        expect(provider.dashboard, isNull);
        expect(provider.error, 'حدث خطأ غير متوقع');
        expect(provider.isLoading, false);
      });
    });

    group('loadStudents()', () {
      test('should load students list', () async {
        mockService.studentsResult = [
          ClassStudentSummary(
            studentId: 1,
            fullName: 'طالب واحد',
            gradeLevel: 1,
            totalPoints: 100,
            currentStreak: 3,
            lessonsCompleted: 5,
            lessonsInProgress: 2,
            averageMastery: 78.0,
          ),
          ClassStudentSummary(
            studentId: 2,
            fullName: 'طالب اثنان',
            gradeLevel: 1,
            totalPoints: 50,
            currentStreak: 1,
            lessonsCompleted: 3,
            lessonsInProgress: 1,
            averageMastery: 60.0,
          ),
        ];

        await provider.loadStudents();

        expect(provider.students, hasLength(2));
        expect(provider.students!.first.fullName, 'طالب واحد');
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('should set error when loading students fails', () async {
        mockService.errorToThrow = Exception('Server error');

        await provider.loadStudents();

        expect(provider.students, isNull);
        expect(provider.error, 'حدث خطأ غير متوقع');
      });
    });

    group('loadStudentDetail()', () {
      test('should load student detail', () async {
        mockService.studentDetailResult = StudentDetail(
          studentId: 1,
          fullName: 'طالب مفصل',
          gradeLevel: 1,
          totalPoints: 300,
          currentStreak: 4,
          lessonsCompleted: 12,
          lessonsInProgress: 3,
          overallMastery: 75.5,
          totalAttempts: 15,
          averageScore: 82.3,
          subjectBreakdown: [],
        );

        await provider.loadStudentDetail(1);

        expect(provider.studentDetail, isNotNull);
        expect(provider.studentDetail!.studentId, 1);
        expect(provider.studentDetail!.overallMastery, 75.5);
        expect(provider.isLoading, false);
      });

      test('should clear previous detail before loading', () async {
        // First load
        mockService.studentDetailResult = StudentDetail(
          studentId: 1,
          fullName: 'First',
          gradeLevel: 1,
          totalPoints: 0,
          currentStreak: 0,
          lessonsCompleted: 0,
          lessonsInProgress: 0,
          overallMastery: 0,
          totalAttempts: 0,
          averageScore: 0,
          subjectBreakdown: [],
        );
        await provider.loadStudentDetail(1);

        // Second load should clear first
        mockService.studentDetailResult = StudentDetail(
          studentId: 2,
          fullName: 'Second',
          gradeLevel: 1,
          totalPoints: 100,
          currentStreak: 0,
          lessonsCompleted: 0,
          lessonsInProgress: 0,
          overallMastery: 0,
          totalAttempts: 0,
          averageScore: 0,
          subjectBreakdown: [],
        );
        await provider.loadStudentDetail(2);

        expect(provider.studentDetail!.studentId, 2);
        expect(provider.studentDetail!.fullName, 'Second');
      });
    });

    group('loadAssignedSubjects()', () {
      test('should load assigned subjects list', () async {
        mockService.assignedSubjectsResult = [
          SubjectSummary(
            id: 1,
            name: 'اللغة العربية',
            gradeLevel: 1,
            lessonCount: 8,
            questionCount: 40,
          ),
          SubjectSummary(
            id: 2,
            name: 'اللغة العربية',
            gradeLevel: 2,
            lessonCount: 7,
            questionCount: 36,
          ),
        ];

        await provider.loadAssignedSubjects();

        expect(provider.assignedSubjects, hasLength(2));
        expect(provider.assignedSubjects!.first.gradeLevel, 1);
        expect(provider.assignedSubjects!.last.gradeLevel, 2);
        expect(provider.isLoading, false);
        expect(provider.error, isNull);
      });

      test('should set error when loading assigned subjects fails', () async {
        mockService.errorToThrow = Exception('Server error');

        await provider.loadAssignedSubjects();

        expect(provider.assignedSubjects, isNull);
        expect(provider.error, 'حدث خطأ غير متوقع');
        expect(provider.isLoading, false);
      });
    });

    group('loadMistakeAnalytics()', () {
      test('should load mistake analytics successfully', () async {
        mockService.mistakeAnalyticsResult = const TeacherMistakeAnalytics(
          summary: TeacherMistakeSummary(
            totalMistakes: 2,
            affectedStudents: 1,
            mostMistakenLessonTitle: 'حرف الراء',
            mostMistakenQuestionText: 'اختر الكلمة الصحيحة',
          ),
          mistakes: [
            TeacherMistakeRow(
              studentId: 1,
              studentName: 'ليان أحمد',
              subjectId: 10,
              subjectName: 'اللغة العربية',
              lessonId: 20,
              lessonTitle: 'حرف الراء',
              questionId: 30,
              questionText: 'اختر الكلمة الصحيحة',
              studentAnswer: 'باب',
              correctAnswer: 'رمان',
              mistakeCount: 2,
              commonMistake: false,
              affectedStudentsForQuestion: 1,
            ),
          ],
        );

        await provider.loadMistakeAnalytics();

        expect(provider.mistakeAnalytics, isNotNull);
        expect(provider.mistakeAnalytics!.summary.totalMistakes, 2);
        expect(
          provider.mistakeAnalytics!.mistakes.first.studentName,
          'ليان أحمد',
        );
        expect(provider.isMistakeAnalyticsLoading, false);
        expect(provider.mistakeAnalyticsError, isNull);
      });

      test('should set mistake analytics error on failure', () async {
        mockService.errorToThrow = Exception('Server error');

        await provider.loadMistakeAnalytics();

        expect(provider.mistakeAnalytics, isNull);
        expect(provider.isMistakeAnalyticsLoading, false);
        expect(provider.mistakeAnalyticsError, 'حدث خطأ غير متوقع');
      });
    });

    group('teacher quizzes', () {
      test('should load teacher quizzes successfully', () async {
        mockService.teacherQuizzesResult = const [
          TeacherQuizSummary(
            id: 44,
            title: 'اختبار الحروف',
            subjectId: 10,
            subjectName: 'اللغة العربية',
            lessonId: 20,
            lessonTitle: 'حرف الراء',
            questionCount: 2,
            createdAt: '2026-07-05T10:00:00',
          ),
        ];

        await provider.loadTeacherQuizzes();

        expect(provider.teacherQuizzes, hasLength(1));
        expect(provider.teacherQuizzes!.single.title, 'اختبار الحروف');
        expect(provider.isTeacherQuizzesLoading, false);
        expect(provider.teacherQuizzesError, isNull);
      });

      test('should load quiz question bank for selected subject', () async {
        mockService.quizQuestionBankResult = QuestionBankResponse(
          subjectId: 10,
          subjectName: 'اللغة العربية',
          gradeLevel: 1,
          lessons: [
            LessonSummary(
              id: 20,
              title: 'حرف الراء',
              orderIndex: 1,
              questionCount: 1,
            ),
          ],
          questions: [
            QuestionBankItem(
              id: 30,
              type: 'MCQ',
              questionText: 'اختر الكلمة الصحيحة',
              correctAnswer: 'رمان',
              options: const ['رمان', 'باب'],
              difficultyLevel: 1,
              lessonId: 20,
              lessonTitle: 'حرف الراء',
            ),
          ],
          totalQuestionsInSubject: 1,
        );

        await provider.loadQuizQuestionBank(10);

        expect(provider.quizQuestionBank, isNotNull);
        expect(provider.quizQuestionBank!.questions.single.id, 30);
        expect(provider.isQuizQuestionBankLoading, false);
        expect(provider.quizQuestionBankError, isNull);
      });

      test('should create quiz and send expected payload', () async {
        mockService.createdQuizResult = const TeacherQuizDetail(
          id: 45,
          title: 'اختبار جديد',
          subjectId: 10,
          subjectName: 'اللغة العربية',
          lessonId: 20,
          lessonTitle: 'حرف الراء',
          questionCount: 2,
          questions: [],
        );

        final ok = await provider.createTeacherQuiz(
          title: 'اختبار جديد',
          subjectId: 10,
          lessonId: 20,
          questionIds: [30, 31],
        );

        expect(ok, isTrue);
        expect(mockService.lastCreatedTitle, 'اختبار جديد');
        expect(mockService.lastCreatedSubjectId, 10);
        expect(mockService.lastCreatedLessonId, 20);
        expect(mockService.lastCreatedQuestionIds, [30, 31]);
        expect(provider.teacherQuizzes!.single.id, 45);
        expect(provider.isCreatingTeacherQuiz, false);
        expect(provider.createTeacherQuizError, isNull);
      });

      test('should set quiz creation error on failure', () async {
        mockService.errorToThrow = Exception('Server error');

        final ok = await provider.createTeacherQuiz(
          title: 'اختبار جديد',
          subjectId: 10,
          questionIds: [30],
        );

        expect(ok, isFalse);
        expect(provider.createTeacherQuizError, 'حدث خطأ غير متوقع');
        expect(provider.isCreatingTeacherQuiz, false);
      });
    });
  });
}
