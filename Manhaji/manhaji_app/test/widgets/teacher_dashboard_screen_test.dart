import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/teacher_dashboard.dart';
import 'package:manhaji_app/providers/teacher_provider.dart';
import 'package:manhaji_app/screens/teacher/teacher_dashboard_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeTeacherService extends TeacherService {
  FakeTeacherService(this.dashboard) : super(ApiService(FakeLocalStorage()));

  final TeacherDashboard dashboard;

  @override
  Future<TeacherDashboard> getDashboard() async => dashboard;
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
        ChangeNotifierProvider(
          create: (_) => TeacherProvider(FakeTeacherService(_dashboard())),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TeacherDashboardScreen(),
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

      // Phase 5H.1: no duplicated quick actions, no permanent
      // "unavailable" placeholder analytics cards.
      expect(find.text('إجراءات سريعة'), findsNothing);
      expect(find.text('تحليلات تحتاج بيانات إضافية'), findsNothing);
      expect(find.textContaining('غير متاحة'), findsNothing);
    },
  );
}
