import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/routes.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/question_bank.dart';
import 'package:manhaji_app/providers/question_bank_provider.dart';
import 'package:manhaji_app/screens/admin/admin_question_bank_questions_screen.dart';
import 'package:manhaji_app/screens/admin/admin_question_bank_screen.dart';
import 'package:manhaji_app/services/admin_service.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeTeacherService extends TeacherService {
  FakeTeacherService() : super(ApiService(FakeLocalStorage()));
}

class FakeAdminService extends AdminService {
  FakeAdminService({
    this.subjects = const [],
    this.response,
    this.throwOnSubjects = false,
  }) : super(ApiService(FakeLocalStorage()));

  final List<SubjectSummary> subjects;
  final QuestionBankResponse? response;
  final bool throwOnSubjects;

  @override
  Future<List<SubjectSummary>> getAllSubjects({int? grade}) async {
    if (throwOnSubjects) throw Exception('boom');
    if (grade == null) return subjects;
    return subjects.where((s) => s.gradeLevel == grade).toList();
  }

  @override
  Future<QuestionBankResponse> getQuestionsForSubject(
    int subjectId, {
    int? difficulty,
    int? lessonId,
  }) async {
    return response!;
  }
}

List<SubjectSummary> _multiGradeSubjects() {
  return [
    SubjectSummary(
      id: 1,
      name: 'اللغة العربية',
      gradeLevel: 1,
      lessonCount: 5,
      questionCount: 40,
    ),
    SubjectSummary(
      id: 5,
      name: 'الرياضيات',
      gradeLevel: 1,
      lessonCount: 4,
      questionCount: 30,
    ),
    SubjectSummary(
      id: 4,
      name: 'English',
      gradeLevel: 2,
      lessonCount: 3,
      questionCount: 20,
    ),
  ];
}

QuestionBankResponse _arabicResponse() {
  return QuestionBankResponse(
    subjectId: 1,
    subjectName: 'اللغة العربية',
    gradeLevel: 1,
    lessons: [
      LessonSummary(id: 11, title: 'حرف الراء', orderIndex: 1, questionCount: 1),
    ],
    questions: [
      QuestionBankItem(
        id: 100,
        type: 'MCQ',
        questionText: 'ما هي الكلمة التي تبدأ بحرف الراء؟',
        correctAnswer: 'رمان',
        options: const ['رمان', 'موز', 'تفاح'],
        difficultyLevel: 1,
        lessonId: 11,
        lessonTitle: 'حرف الراء',
      ),
    ],
    totalQuestionsInSubject: 1,
  );
}

Widget _wrap(FakeAdminService service) {
  return ChangeNotifierProvider(
    create: (_) => QuestionBankProvider(FakeTeacherService(), service),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      routes: {
        AppRoutes.adminQuestionBankQuestions: (_) =>
            const AdminQuestionBankQuestionsScreen(),
      },
      home: const AdminQuestionBankScreen(),
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
  testWidgets('admin question bank shows all subjects with derived grades', (
    tester,
  ) async {
    _useDesktop(tester);

    await tester.pumpWidget(
      _wrap(FakeAdminService(subjects: _multiGradeSubjects())),
    );
    await tester.pumpAndSettle();

    // Shell + all subjects from every grade.
    expect(find.text('مساحة المشرف'), findsOneWidget);
    expect(find.text('اللغة العربية'), findsOneWidget);
    expect(find.text('الرياضيات'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('3 مادة'), findsOneWidget);

    // Grade chips derived from the loaded data only — no hardcoded grades.
    expect(find.widgetWithText(ChoiceChip, 'الصف 1'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'الصف 2'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'الصف 3'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'الصف 6'), findsNothing);
  });

  testWidgets('grade chip filters subjects client-side', (tester) async {
    _useDesktop(tester);

    await tester.pumpWidget(
      _wrap(FakeAdminService(subjects: _multiGradeSubjects())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'الصف 2'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('اللغة العربية'), findsNothing);
    expect(find.text('الرياضيات'), findsNothing);
    expect(find.text('1 مادة'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'الكل'));
    await tester.pumpAndSettle();
    expect(find.text('اللغة العربية'), findsOneWidget);
  });

  testWidgets('admin question bank renders error state with retry', (
    tester,
  ) async {
    _useDesktop(tester);

    await tester.pumpWidget(_wrap(FakeAdminService(throwOnSubjects: true)));
    await tester.pumpAndSettle();

    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('admin question bank renders empty state', (tester) async {
    _useDesktop(tester);

    await tester.pumpWidget(_wrap(FakeAdminService(subjects: const [])));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد مواد حاليًا'), findsOneWidget);
  });

  testWidgets('tapping a subject opens its questions inside the shell', (
    tester,
  ) async {
    _useDesktop(tester);

    await tester.pumpWidget(
      _wrap(
        FakeAdminService(
          subjects: _multiGradeSubjects(),
          response: _arabicResponse(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('اللغة العربية'));
    await tester.pumpAndSettle();

    // Questions screen inside the staff shell with back action.
    expect(find.text('ما هي الكلمة التي تبدأ بحرف الراء؟'), findsOneWidget);
    expect(find.text('حرف الراء'), findsAtLeastNWidgets(1));
    expect(
      find.byKey(const ValueKey('admin-question-bank-back')),
      findsOneWidget,
    );
    expect(find.text('مساحة المشرف'), findsOneWidget);

    // Back returns to the subjects grid.
    await tester.tap(find.byKey(const ValueKey('admin-question-bank-back')));
    await tester.pumpAndSettle();
    expect(find.text('الرياضيات'), findsOneWidget);
  });
}
