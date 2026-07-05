import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/teacher_mistake_analytics.dart';
import 'package:manhaji_app/providers/teacher_provider.dart';
import 'package:manhaji_app/screens/teacher/teacher_mistake_analytics_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeTeacherService extends TeacherService {
  FakeTeacherService(this.analytics) : super(ApiService(FakeLocalStorage()));

  final TeacherMistakeAnalytics analytics;

  @override
  Future<TeacherMistakeAnalytics> getMistakeAnalytics({
    int? subjectId,
    int? lessonId,
    int? studentId,
    int? limit,
  }) async {
    return analytics;
  }
}

TeacherMistakeAnalytics _analytics({bool empty = false}) {
  if (empty) {
    return const TeacherMistakeAnalytics(
      summary: TeacherMistakeSummary(totalMistakes: 0, affectedStudents: 0),
      mistakes: [],
    );
  }

  return const TeacherMistakeAnalytics(
    summary: TeacherMistakeSummary(
      totalMistakes: 3,
      affectedStudents: 2,
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
        lastMistakeAt: '2026-07-05T10:15:00',
        commonMistake: true,
        affectedStudentsForQuestion: 2,
      ),
      TeacherMistakeRow(
        studentId: 2,
        studentName: 'كريم حسن',
        subjectId: 11,
        subjectName: 'الرياضيات',
        lessonId: 21,
        lessonTitle: 'الجمع',
        questionId: 31,
        questionText: '٢ + ٢ = ؟',
        studentAnswer: '5',
        correctAnswer: '4',
        mistakeCount: 1,
        lastMistakeAt: '2026-07-04T09:00:00',
        commonMistake: false,
        affectedStudentsForQuestion: 1,
      ),
    ],
  );
}

Widget _wrap(TeacherMistakeAnalytics analytics) {
  return ChangeNotifierProvider(
    create: (_) => TeacherProvider(FakeTeacherService(analytics)),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const TeacherMistakeAnalyticsScreen(),
    ),
  );
}

void _useDesktop(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('teacher mistake analytics renders summary, rows, and sidebar', (
    tester,
  ) async {
    _useDesktop(tester);

    await tester.pumpWidget(_wrap(_analytics()));
    await tester.pumpAndSettle();

    expect(find.text('تحليل أخطاء الطلاب'), findsOneWidget);
    expect(find.text('تحليل الأخطاء'), findsOneWidget);
    expect(find.text('إجمالي الأخطاء'), findsOneWidget);
    expect(find.text('الطلاب المتأثرون'), findsOneWidget);
    expect(find.text('أكثر درس يحتاج متابعة'), findsOneWidget);
    expect(find.text('أكثر سؤال تكررت فيه الأخطاء'), findsOneWidget);
    expect(find.text('ليان أحمد'), findsOneWidget);
    expect(find.text('اللغة العربية'), findsAtLeastNWidgets(1));
    expect(find.text('حرف الراء'), findsAtLeastNWidgets(1));
    expect(find.text('اختر الكلمة الصحيحة'), findsAtLeastNWidgets(1));
    expect(find.text('باب'), findsOneWidget);
    expect(find.text('رمان'), findsOneWidget);
    expect(find.text('خطأ شائع'), findsOneWidget);
    expect(find.text('خطأ فردي'), findsOneWidget);
  });

  testWidgets('teacher mistake analytics renders empty state', (tester) async {
    _useDesktop(tester);

    await tester.pumpWidget(_wrap(_analytics(empty: true)));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد أخطاء مسجلة حاليًا'), findsOneWidget);
  });
}
