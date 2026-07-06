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
  FakeLessonService(LocalStorageService storage) : super(ApiService(storage));

  @override
  Future<Dashboard> getDashboard() async {
    return Dashboard(
      studentId: 1,
      fullName: 'ليان',
      gradeLevel: 1,
      currentStreak: 6,
      totalPoints: 140,
      subjects: const [],
    );
  }

  @override
  Future<List<Subject>> getSubjectsByGrade(int gradeLevel) async => const [];

  @override
  Future<List<LessonSummary>> getLessonsBySubject(int subjectId) async =>
      const [];
}

class FakeQuizService extends QuizApiService {
  FakeQuizService(LocalStorageService storage) : super(ApiService(storage));

  @override
  Future<List<StudentAssignedQuizSummary>> getAssignedQuizzes() async =>
      const [];

  @override
  Future<Quiz> generatePersonalizedQuiz(int subjectId) async {
    throw UnimplementedError();
  }

  @override
  Future<SkillMastery> getSkillMastery(int subjectId) async {
    throw UnimplementedError();
  }
}

Widget _wrap() {
  final storage = FakeLocalStorage();
  final quizService = FakeQuizService(storage);
  return MultiProvider(
    providers: [
      Provider<LocalStorageService>.value(value: storage),
      Provider<QuizApiService>.value(value: quizService),
      ChangeNotifierProvider(
        create: (_) => LessonProvider(FakeLessonService(storage)),
      ),
      ChangeNotifierProvider(
        create: (_) => StudentAssignedQuizProvider(quizService),
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

    expect(
      find.byKey(const ValueKey('student-rewards-entry-card')),
      findsOneWidget,
    );
    expect(find.text('متجر المكافآت'), findsOneWidget);
    expect(find.text('استخدم نجومك لفتح مكافآت شكلية'), findsOneWidget);
  });
}
