import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/route_args.dart';
import 'package:manhaji_app/app/routes.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/teacher_dashboard.dart';
import 'package:manhaji_app/providers/teacher_provider.dart';
import 'package:manhaji_app/screens/teacher/student_detail_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeTeacherService extends TeacherService {
  FakeTeacherService(this.detail) : super(ApiService(FakeLocalStorage()));

  final StudentDetail detail;
  int? requestedStudentId;

  @override
  Future<StudentDetail> getStudentDetail(int studentId) async {
    requestedStudentId = studentId;
    return detail;
  }
}

Widget _wrap({required FakeTeacherService service, Object? args}) {
  return ChangeNotifierProvider(
    create: (_) => TeacherProvider(service),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.classStudents) {
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Students page')),
          );
        }
        return MaterialPageRoute<void>(
          settings: RouteSettings(arguments: args),
          builder: (_) => const StudentDetailScreen(),
        );
      },
    ),
  );
}

StudentDetail _studentDetail() {
  return StudentDetail(
    studentId: 7,
    fullName: 'سارة أحمد',
    email: 'sara@example.com',
    gradeLevel: 2,
    totalPoints: 340,
    currentStreak: 5,
    lastLoginAt: '2026-07-01T09:30:00',
    lessonsCompleted: 12,
    lessonsInProgress: 3,
    overallMastery: 81.5,
    totalAttempts: 9,
    averageScore: 76.2,
    subjectBreakdown: [
      SubjectMasterySummary(
        subjectId: 1,
        subjectName: 'اللغة العربية',
        totalLessons: 10,
        lessonsCompleted: 7,
        averageMastery: 84,
      ),
    ],
  );
}

void main() {
  testWidgets(
    'StudentDetailScreen renders backend student detail in staff shell',
    (tester) async {
      final service = FakeTeacherService(_studentDetail());

      await tester.pumpWidget(
        _wrap(service: service, args: const StudentDetailArgs(7)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.requestedStudentId, 7);
      expect(find.text('بيانات الطالب'), findsOneWidget);
      expect(find.text('سارة أحمد'), findsOneWidget);
      expect(find.text('sara@example.com'), findsOneWidget);
      expect(find.text('الصف الثاني'), findsOneWidget);
      expect(find.text('340'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('ملخص التعلم'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);
      expect(find.text('محاولات الاختبار'), findsOneWidget);
      expect(find.text('اللغة العربية'), findsOneWidget);
    },
  );

  testWidgets('StudentDetailScreen shows Arabic error for invalid args', (
    tester,
  ) async {
    final service = FakeTeacherService(_studentDetail());

    await tester.pumpWidget(_wrap(service: service));
    await tester.pumpAndSettle();

    expect(service.requestedStudentId, isNull);
    expect(find.text('لم يتم تحديد الطالب بشكل صحيح.'), findsOneWidget);
    expect(find.text('العودة إلى الطلاب'), findsAtLeastNWidgets(1));
  });
}
