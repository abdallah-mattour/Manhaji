import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/routes.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/teacher_dashboard.dart';
import 'package:manhaji_app/models/teacher_mistake_analytics.dart';
import 'package:manhaji_app/models/teacher_quiz.dart';
import 'package:manhaji_app/providers/teacher_provider.dart';
import 'package:manhaji_app/screens/teacher/teacher_dashboard_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeTeacherService extends TeacherService {
  FakeTeacherService(
    this.dashboard, {
    this.students = const [],
    this.mistakes = const [],
    this.quizzes = const [],
  }) : super(ApiService(FakeLocalStorage()));

  final TeacherDashboard dashboard;
  final List<ClassStudentSummary> students;
  final List<TeacherMistakeRow> mistakes;
  final List<TeacherQuizSummary> quizzes;

  @override
  Future<TeacherDashboard> getDashboard() async => dashboard;

  @override
  Future<List<ClassStudentSummary>> getStudents() async => students;

  @override
  Future<TeacherMistakeAnalytics> getMistakeAnalytics({
    int? subjectId,
    int? lessonId,
    int? studentId,
    int? limit,
  }) async {
    return TeacherMistakeAnalytics(
      summary: TeacherMistakeSummary(
        totalMistakes: mistakes.length,
        affectedStudents: mistakes.map((row) => row.studentId).toSet().length,
      ),
      mistakes: mistakes,
    );
  }

  @override
  Future<List<TeacherQuizSummary>> getTeacherQuizzes() async => quizzes;
}

TeacherDashboard _dashboard() {
  return TeacherDashboard(
    teacherId: 111,
    fullName: 'أ. سلمى',
    department: 'اللغة العربية',
    assignedGrade: 1,
    totalStudents: 10,
    activeThisWeek: 8,
    lessonsCompletedTotal: 24,
    averageMasteryAcrossClass: 67.4,
    topStudents: [
      ClassStudentSummary(
        studentId: 133,
        fullName: 'جنى خالد',
        gradeLevel: 1,
        totalPoints: 610,
        currentStreak: 5,
        lessonsCompleted: 3,
        lessonsInProgress: 2,
        averageMastery: 90.5,
      ),
    ],
  );
}

List<ClassStudentSummary> _students() {
  return [
    ClassStudentSummary(
      studentId: 144,
      fullName: 'رامي سعيد',
      gradeLevel: 1,
      totalPoints: 80,
      currentStreak: 0,
      lessonsCompleted: 1,
      lessonsInProgress: 3,
      averageMastery: 48,
    ),
    ClassStudentSummary(
      studentId: 145,
      fullName: 'نور علي',
      gradeLevel: 1,
      totalPoints: 340,
      currentStreak: 4,
      lessonsCompleted: 5,
      lessonsInProgress: 1,
      averageMastery: 74,
    ),
  ];
}

List<TeacherMistakeRow> _mistakes() {
  return const [
    TeacherMistakeRow(
      studentId: 144,
      studentName: 'رامي سعيد',
      subjectId: 1,
      subjectName: 'اللغة العربية',
      lessonId: 11,
      lessonTitle: 'حرف السين',
      questionId: 91,
      questionText: 'اختر الكلمة التي تبدأ بحرف السين',
      mistakeCount: 2,
      commonMistake: true,
      affectedStudentsForQuestion: 3,
    ),
  ];
}

List<TeacherQuizSummary> _quizzes() {
  return const [
    TeacherQuizSummary(
      id: 5,
      title: 'اختبار القراءة القصير',
      subjectName: 'اللغة العربية',
      questionCount: 6,
      status: 'PUBLISHED',
    ),
    TeacherQuizSummary(
      id: 6,
      title: 'مسودة الحروف',
      subjectName: 'اللغة العربية',
      questionCount: 4,
      status: 'DRAFT',
    ),
  ];
}

Widget _wrap(FakeTeacherService service) {
  return ChangeNotifierProvider(
    create: (_) => TeacherProvider(service),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        AppRoutes.classStudents: (_) =>
            const Scaffold(body: Text('كل الطلاب — صفحة')),
        AppRoutes.teacherMistakes: (_) =>
            const Scaffold(body: Text('تحليل الأخطاء — صفحة')),
        AppRoutes.teacherQuizzes: (_) =>
            const Scaffold(body: Text('اختبارات المعلم — صفحة')),
      },
      home: const TeacherDashboardScreen(),
    ),
  );
}

void main() {
  testWidgets(
    'teacher dashboard renders real data panels without quick actions '
    'or unavailable placeholders',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          FakeTeacherService(
            _dashboard(),
            students: _students(),
            mistakes: _mistakes(),
            quizzes: _quizzes(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Real sections still render from provider data.
      expect(find.text('مساحة المعلم'), findsOneWidget);
      expect(find.textContaining('أ. سلمى'), findsOneWidget);
      expect(find.text('إجمالي الطلاب'), findsOneWidget);
      expect(find.text('نبض الصف'), findsOneWidget);
      expect(find.text('أفضل الطلاب'), findsOneWidget);
      expect(find.text('جنى خالد'), findsOneWidget);
      expect(find.text('الطلاب الذين يحتاجون متابعة'), findsAtLeastNWidgets(1));
      expect(find.text('رامي سعيد'), findsAtLeastNWidgets(1));
      expect(find.text('آخر أخطاء الطلاب'), findsAtLeastNWidgets(1));
      expect(find.text('اختر الكلمة التي تبدأ بحرف السين'), findsOneWidget);
      expect(find.text('الاختبارات المنشورة'), findsAtLeastNWidgets(1));
      expect(find.text('اختبار القراءة القصير'), findsOneWidget);
      expect(find.text('تحليل الأخطاء'), findsAtLeastNWidgets(1));
      expect(find.text('إنشاء اختبار'), findsOneWidget);

      expect(find.text('تحليلات تحتاج بيانات إضافية'), findsNothing);
      expect(find.textContaining('غير متاحة'), findsNothing);
    },
  );

  testWidgets('teacher dashboard empty states render safely', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(FakeTeacherService(_dashboard())));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد بيانات كافية حاليًا'), findsAtLeastNWidgets(1));
    expect(find.text('لا توجد أخطاء مسجلة'), findsAtLeastNWidgets(1));
    expect(find.text('لا توجد اختبارات منشورة'), findsAtLeastNWidgets(1));
  });

  testWidgets('teacher quick action opens quizzes route', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        FakeTeacherService(
          _dashboard(),
          students: _students(),
          mistakes: _mistakes(),
          quizzes: _quizzes(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('teacher-dashboard-open-quizzes')),
    );
    await tester.pumpAndSettle();

    expect(find.text('اختبارات المعلم — صفحة'), findsOneWidget);
  });
}
