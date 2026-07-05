import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/question_bank.dart';
import 'package:manhaji_app/providers/teacher_provider.dart';
import 'package:manhaji_app/screens/teacher/teacher_subjects_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeTeacherService extends TeacherService {
  FakeTeacherService(this.subjects) : super(ApiService(FakeLocalStorage()));

  final List<SubjectSummary> subjects;

  @override
  Future<List<SubjectSummary>> getAssignedSubjects() async => subjects;
}

Widget _wrap(List<SubjectSummary> subjects) {
  return ChangeNotifierProvider(
    create: (_) => TeacherProvider(FakeTeacherService(subjects)),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const TeacherSubjectsScreen(),
    ),
  );
}

void main() {
  testWidgets('TeacherSubjectsScreen groups assigned subjects by grade', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap([
        SubjectSummary(
          id: 1,
          name: 'اللغة العربية',
          gradeLevel: 1,
          lessonCount: 8,
          questionCount: 40,
        ),
        SubjectSummary(
          id: 5,
          name: 'الرياضيات',
          gradeLevel: 2,
          lessonCount: 6,
          questionCount: 32,
        ),
      ]),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('الصف الأول'), findsOneWidget);
    expect(find.text('الصف الثاني'), findsOneWidget);
    expect(find.text('اللغة العربية'), findsOneWidget);
    expect(find.text('الرياضيات'), findsOneWidget);
    expect(find.text('لا توجد مواد مخصصة لهذا الحساب حالياً.'), findsNothing);
  });

  testWidgets('TeacherSubjectsScreen shows Arabic empty state', (tester) async {
    await tester.pumpWidget(_wrap(const []));

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('لا توجد مواد مخصصة لهذا الحساب حالياً.'), findsOneWidget);
  });
}
