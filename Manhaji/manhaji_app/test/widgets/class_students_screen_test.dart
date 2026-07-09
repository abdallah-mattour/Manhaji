import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/teacher_dashboard.dart';
import 'package:manhaji_app/providers/teacher_provider.dart';
import 'package:manhaji_app/screens/teacher/class_students_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeTeacherService extends TeacherService {
  FakeTeacherService(this.students) : super(ApiService(FakeLocalStorage()));

  final List<ClassStudentSummary> students;

  @override
  Future<List<ClassStudentSummary>> getStudents() async => students;
}

void main() {
  testWidgets('ClassStudentsScreen groups returned students by grade', (
    tester,
  ) async {
    final students = [
      ClassStudentSummary(
        studentId: 1,
        fullName: 'سارة أحمد',
        email: 'sara@example.com',
        gradeLevel: 1,
        totalPoints: 120,
        currentStreak: 4,
        lessonsCompleted: 6,
        lessonsInProgress: 1,
        averageMastery: 82,
      ),
      ClassStudentSummary(
        studentId: 2,
        fullName: 'ليان خالد',
        email: 'layan@example.com',
        gradeLevel: 2,
        totalPoints: 90,
        currentStreak: 2,
        lessonsCompleted: 4,
        lessonsInProgress: 3,
        averageMastery: 70,
      ),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TeacherProvider(FakeTeacherService(students)),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ClassStudentsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('الصف الأول'), findsOneWidget);
    expect(find.text('الصف الثاني'), findsOneWidget);
    expect(find.text('سارة أحمد'), findsOneWidget);
    expect(find.text('ليان خالد'), findsOneWidget);
  });
}
