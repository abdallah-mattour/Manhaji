import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/question_bank.dart';
import 'package:manhaji_app/models/teacher_quiz.dart';
import 'package:manhaji_app/providers/teacher_provider.dart';
import 'package:manhaji_app/screens/teacher/teacher_quizzes_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/teacher_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeTeacherService extends TeacherService {
  FakeTeacherService({
    required this.quizzes,
    required this.subjects,
    required this.questionBank,
  }) : super(ApiService(FakeLocalStorage()));

  final List<TeacherQuizSummary> quizzes;
  final List<SubjectSummary> subjects;
  final QuestionBankResponse questionBank;

  int? requestedSubjectId;
  String? createdTitle;
  int? createdSubjectId;
  int? createdLessonId;
  List<int>? createdQuestionIds;

  @override
  Future<List<TeacherQuizSummary>> getTeacherQuizzes() async {
    return quizzes;
  }

  @override
  Future<List<SubjectSummary>> getAssignedSubjects() async {
    return subjects;
  }

  @override
  Future<QuestionBankResponse> getQuestionsForSubject(
    int subjectId, {
    int? difficulty,
    int? lessonId,
  }) async {
    requestedSubjectId = subjectId;
    return questionBank;
  }

  @override
  Future<TeacherQuizDetail> createTeacherQuiz({
    required String title,
    required int subjectId,
    int? lessonId,
    required List<int> questionIds,
  }) async {
    createdTitle = title;
    createdSubjectId = subjectId;
    createdLessonId = lessonId;
    createdQuestionIds = questionIds;
    return TeacherQuizDetail(
      id: 99,
      title: title,
      subjectId: subjectId,
      subjectName: 'اللغة العربية',
      lessonId: lessonId,
      lessonTitle: 'حرف الراء',
      questionCount: questionIds.length,
      questions: const [],
    );
  }
}

Widget _wrap(FakeTeacherService service) {
  return ChangeNotifierProvider(
    create: (_) => TeacherProvider(service),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const TeacherQuizzesScreen(),
    ),
  );
}

void _useDesktop(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

SubjectSummary _subject() {
  return SubjectSummary(
    id: 10,
    name: 'اللغة العربية',
    gradeLevel: 1,
    lessonCount: 1,
    questionCount: 1,
  );
}

QuestionBankResponse _questionBank({bool empty = false}) {
  return QuestionBankResponse(
    subjectId: 10,
    subjectName: 'اللغة العربية',
    gradeLevel: 1,
    lessons: [
      LessonSummary(
        id: 20,
        title: 'حرف الراء',
        orderIndex: 1,
        questionCount: empty ? 0 : 1,
      ),
    ],
    questions: empty
        ? const []
        : [
            QuestionBankItem(
              id: 30,
              type: 'MCQ',
              questionText: 'اختر الكلمة الصحيحة',
              correctAnswer: 'رمان',
              options: const ['رمان', 'باب'],
              difficultyLevel: 1,
              lessonId: 20,
              lessonTitle: 'حرف الراء',
            ),
          ],
    totalQuestionsInSubject: empty ? 0 : 1,
  );
}

void main() {
  testWidgets('teacher quizzes page renders action and empty state', (
    tester,
  ) async {
    _useDesktop(tester);
    final service = FakeTeacherService(
      quizzes: const [],
      subjects: [_subject()],
      questionBank: _questionBank(),
    );

    await tester.pumpWidget(_wrap(service));
    await tester.pumpAndSettle();

    expect(find.text('إدارة الاختبارات'), findsOneWidget);
    expect(find.text('الاختبارات'), findsOneWidget);
    expect(find.text('إنشاء اختبار جديد'), findsAtLeastNWidgets(1));
    expect(find.text('لا توجد اختبارات بعد'), findsOneWidget);
  });

  testWidgets('teacher can select subject and question with fake data', (
    tester,
  ) async {
    _useDesktop(tester);
    final service = FakeTeacherService(
      quizzes: const [],
      subjects: [_subject()],
      questionBank: _questionBank(),
    );

    await tester.pumpWidget(_wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إنشاء اختبار جديد').first);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('teacher_quiz_title_field')),
      'اختبار جديد',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('teacher_quiz_subject_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اللغة العربية - الصف الأول').last);
    await tester.pumpAndSettle();

    expect(service.requestedSubjectId, 10);
    expect(find.text('اختر الكلمة الصحيحة'), findsOneWidget);
    expect(find.text('سؤال خارج النطاق'), findsNothing);

    await tester.tap(find.byTooltip('إضافة السؤال').first);
    await tester.pump();
    await tester.tap(find.text('حفظ الاختبار'));
    await tester.pumpAndSettle();

    expect(service.createdTitle, 'اختبار جديد');
    expect(service.createdSubjectId, 10);
    expect(service.createdQuestionIds, [30]);
    expect(find.text('اختبار جديد'), findsOneWidget);
  });

  testWidgets('teacher quizzes dialog shows empty question state', (
    tester,
  ) async {
    _useDesktop(tester);
    final service = FakeTeacherService(
      quizzes: const [],
      subjects: [_subject()],
      questionBank: _questionBank(empty: true),
    );

    await tester.pumpWidget(_wrap(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إنشاء اختبار جديد').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('teacher_quiz_subject_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اللغة العربية - الصف الأول').last);
    await tester.pumpAndSettle();

    expect(find.text('لا توجد أسئلة متاحة لهذه المادة'), findsOneWidget);
  });
}
