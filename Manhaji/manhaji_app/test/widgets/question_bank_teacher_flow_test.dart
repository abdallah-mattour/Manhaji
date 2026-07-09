import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/question_bank.dart';
import 'package:manhaji_app/providers/question_bank_provider.dart';
import 'package:manhaji_app/screens/question_bank/question_bank_subjects_screen.dart';
import 'package:manhaji_app/services/admin_service.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeTeacherService extends TeacherService {
  FakeTeacherService({this.subjects = const [], this.error})
    : super(ApiService(FakeLocalStorage()));

  final List<SubjectSummary> subjects;
  final Exception? error;

  @override
  Future<List<SubjectSummary>> getAssignedSubjects() async {
    if (error != null) throw error!;
    return subjects;
  }
}

class FakeAdminService extends AdminService {
  FakeAdminService() : super(ApiService(FakeLocalStorage()));
}

Widget _wrap(FakeTeacherService teacherService) {
  return ChangeNotifierProvider(
    create: (_) => QuestionBankProvider(teacherService, FakeAdminService()),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const QuestionBankSubjectsScreen(asAdmin: false),
    ),
  );
}

void main() {
  testWidgets('teacher question bank loads assigned subjects only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        FakeTeacherService(
          subjects: [
            SubjectSummary(
              id: 1,
              name: 'اللغة العربية',
              gradeLevel: 1,
              lessonCount: 8,
              questionCount: 40,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('بنك الأسئلة'), findsOneWidget);
    expect(find.text('اللغة العربية'), findsOneWidget);
    expect(find.text('الرياضيات'), findsNothing);
  });

  testWidgets('teacher question bank error state renders retry action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(FakeTeacherService(error: Exception('network'))),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
