import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/routes.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/dashboard.dart';
import 'package:manhaji_app/models/lesson.dart';
import 'package:manhaji_app/models/quiz.dart';
import 'package:manhaji_app/models/skill_mastery.dart';
import 'package:manhaji_app/models/student_assigned_quiz.dart';
import 'package:manhaji_app/models/subject.dart';
import 'package:manhaji_app/providers/lesson_provider.dart';
import 'package:manhaji_app/providers/student_assigned_quiz_provider.dart';
import 'package:manhaji_app/screens/home/home_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/lesson_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/quiz_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {
  @override
  bool get isLoggedIn => true;
}

class FakeLessonService extends LessonApiService {
  FakeLessonService(LocalStorageService storage, {this.subjects = const []})
    : super(ApiService(storage));

  final List<Subject> subjects;

  @override
  Future<Dashboard> getDashboard() async {
    return Dashboard(
      studentId: 1,
      fullName: 'ليان',
      gradeLevel: 1,
      currentStreak: 6,
      totalPoints: 140,
      subjects: subjects,
    );
  }

  @override
  Future<List<Subject>> getSubjectsByGrade(int gradeLevel) async => subjects;

  @override
  Future<List<LessonSummary>> getLessonsBySubject(int subjectId) async =>
      const [];
}

class FakeQuizService extends QuizApiService {
  FakeQuizService(
    LocalStorageService storage, {
    this.assignedQuizzes = const [],
    this.assignedDetail,
    this.throwOnDetail = false,
  }) : super(ApiService(storage));

  final List<StudentAssignedQuizSummary> assignedQuizzes;
  final StudentAssignedQuizDetail? assignedDetail;
  final bool throwOnDetail;
  int detailRequests = 0;

  @override
  Future<List<StudentAssignedQuizSummary>> getAssignedQuizzes() async =>
      assignedQuizzes;

  @override
  Future<StudentAssignedQuizDetail> getAssignedQuizDetail(
    int assignmentId,
  ) async {
    detailRequests++;
    if (throwOnDetail) throw Exception('detail failed');
    return assignedDetail!;
  }

  @override
  Future<Quiz> generatePersonalizedQuiz(int subjectId) async {
    throw UnimplementedError();
  }

  @override
  Future<SkillMastery> getSkillMastery(int subjectId) async {
    throw UnimplementedError();
  }
}

Question _question(int id) => Question(
  id: id,
  type: 'MCQ',
  questionText: 'اختر الإجابة الصحيحة',
  options: const ['أ', 'ب'],
  difficultyLevel: 1,
);

StudentAssignedQuizSummary _assignedQuizSummary({
  int assignmentId = 70,
  String? dueAt,
}) {
  // Time-relative default: due in 8 hours, so the quiz is always in the
  // "ending soon" window (<24h) and startable. A hardcoded date here
  // expired once the calendar caught up and silently flipped the fixture
  // into the expired state.
  return StudentAssignedQuizSummary(
    assignmentId: assignmentId,
    quizId: 44,
    title: 'اختبار الحروف',
    subjectName: 'اللغة العربية',
    questionCount: 2,
    dueAt:
        dueAt ??
        DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
    status: 'ASSIGNED',
    attemptsUsed: 0,
    maxAttempts: 1,
    canStart: true,
  );
}

StudentAssignedQuizDetail _assignedQuizDetail() {
  return StudentAssignedQuizDetail(
    assignmentId: 70,
    quizId: 44,
    title: 'اختبار الحروف',
    subjectName: 'اللغة العربية',
    questionCount: 1,
    status: 'ASSIGNED',
    attemptsUsed: 0,
    maxAttempts: 1,
    canStart: true,
    questions: [_question(1)],
  );
}

List<Subject> _subjects() => [
  Subject(
    id: 1,
    name: 'اللغة العربية',
    gradeLevel: 1,
    totalLessons: 12,
    completedLessons: 5,
  ),
  Subject(
    id: 2,
    name: 'الرياضيات',
    gradeLevel: 1,
    totalLessons: 10,
    completedLessons: 2,
  ),
];

Widget _wrap({
  FakeQuizService? quizService,
  List<Subject> subjects = const [],
}) {
  final storage = FakeLocalStorage();
  final effectiveQuizService = quizService ?? FakeQuizService(storage);
  return MultiProvider(
    providers: [
      Provider<LocalStorageService>.value(value: storage),
      Provider<QuizApiService>.value(value: effectiveQuizService),
      ChangeNotifierProvider(
        create: (_) =>
            LessonProvider(FakeLessonService(storage, subjects: subjects)),
      ),
      ChangeNotifierProvider(
        create: (_) => StudentAssignedQuizProvider(effectiveQuizService),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        AppRoutes.rewards: (_) => const Scaffold(body: Text('Rewards route')),
      },
      home: const HomeScreen(),
    ),
  );
}

void _useMobile(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('student home shows rewards entry card', (tester) async {
    _useMobile(tester);

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('student-rewards-entry-card')),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('student-rewards-entry-card')),
      findsOneWidget,
    );
    expect(find.text('متجر المكافآت'), findsOneWidget);
    expect(find.text('استخدم نجومك لفتح مكافآت شكلية'), findsOneWidget);
  });

  testWidgets(
    'student home prioritizes assigned quiz alerts before compact quiz list',
    (tester) async {
      _useMobile(tester);
      final storage = FakeLocalStorage();
      final quizService = FakeQuizService(
        storage,
        assignedQuizzes: [_assignedQuizSummary()],
        assignedDetail: _assignedQuizDetail(),
      );

      await tester.pumpWidget(_wrap(quizService: quizService));
      await tester.pumpAndSettle();

      expect(find.text('تنبيهات الاختبارات'), findsOneWidget);
      expect(find.text('اختبارات المعلم'), findsOneWidget);
      expect(find.text('اختبار "اختبار الحروف" ينتهي قريبًا'), findsOneWidget);
      expect(find.text('لا توجد اختبارات مخصصة حاليًا'), findsNothing);

      final alertTop = tester.getTopLeft(find.text('تنبيهات الاختبارات')).dy;
      final listTop = tester.getTopLeft(find.text('اختبارات المعلم')).dy;
      expect(alertTop, lessThan(listTop));

      // Deadline copy appears in the alert only; compact card keeps action
      // details without repeating the exact same deadline line.
      expect(find.textContaining('ينتهي خلال'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('student-rewards-entry-card')),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('student-rewards-entry-card')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'student home composes assigned quizzes, rewards, and learning subjects',
    (tester) async {
      _useMobile(tester);
      final storage = FakeLocalStorage();
      final quizService = FakeQuizService(
        storage,
        assignedQuizzes: [
          _assignedQuizSummary(
            dueAt: DateTime.now()
                .add(const Duration(hours: 8))
                .toIso8601String(),
          ),
        ],
        assignedDetail: _assignedQuizDetail(),
      );

      await tester.pumpWidget(
        _wrap(quizService: quizService, subjects: _subjects()),
      );
      await tester.pumpAndSettle();

      expect(find.text('تنبيهات الاختبارات'), findsOneWidget);
      expect(find.text('اختبارات المعلم'), findsOneWidget);
      expect(find.text('لا توجد اختبارات مخصصة حاليًا'), findsNothing);
      expect(find.text('لا توجد مواد للصف 1 بعد'), findsNothing);

      final alertTop = tester.getTopLeft(find.text('تنبيهات الاختبارات')).dy;
      final quizListTop = tester.getTopLeft(find.text('اختبارات المعلم')).dy;
      expect(alertTop, lessThan(quizListTop));

      await tester.scrollUntilVisible(
        find.text('الرياضيات'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('الرياضيات'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('student-rewards-entry-card')),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('متجر المكافآت'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('هدف اليوم'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('هدف اليوم'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('تحدَّ نفسك!'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('تحدَّ نفسك!'), findsOneWidget);
    },
  );

  testWidgets('assigned quiz detail failure shows safe Arabic feedback', (
    tester,
  ) async {
    _useMobile(tester);
    final storage = FakeLocalStorage();
    final quizService = FakeQuizService(
      storage,
      assignedQuizzes: [_assignedQuizSummary()],
      throwOnDetail: true,
    );

    await tester.pumpWidget(_wrap(quizService: quizService));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('assigned_quiz_start_70')));
    await tester.pumpAndSettle();

    expect(quizService.detailRequests, 1);
    expect(find.text('حدث خطأ غير متوقع'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('assigned_quiz_start_70')));
    await tester.pumpAndSettle();

    expect(quizService.detailRequests, 2);
  });
}
