import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/student_assigned_quiz.dart';
import 'package:manhaji_app/providers/learning_provider.dart';
import 'package:manhaji_app/providers/student_assigned_quiz_provider.dart';
import 'package:manhaji_app/screens/learning/learning_completion_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:manhaji_app/services/quiz_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {}

class FakeQuizService extends QuizApiService {
  FakeQuizService() : super(ApiService(FakeLocalStorage()));

  int assignedQuizRefreshCalls = 0;

  @override
  Future<List<StudentAssignedQuizSummary>> getAssignedQuizzes() async {
    assignedQuizRefreshCalls++;
    return const [];
  }
}

Widget _wrap({
  required LearningCompletionMode mode,
  required FakeQuizService service,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LearningProvider(service)),
      ChangeNotifierProvider(
        create: (_) => StudentAssignedQuizProvider(service),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: LearningCompletionScreen(
        lessonTitle: 'اختبار الحروف',
        lessonId: -1,
        mode: mode,
      ),
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
  testWidgets(
    'assigned quiz completion uses quiz copy and refreshes assigned quizzes',
    (tester) async {
      _useMobile(tester);
      final service = FakeQuizService();

      await tester.pumpWidget(
        _wrap(mode: LearningCompletionMode.assignedQuiz, service: service),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('الاختبار'), findsAtLeastNWidgets(1));
      expect(find.text('العودة إلى الاختبارات'), findsOneWidget);
      expect(find.text('العودة للدروس 📚'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('العودة إلى الاختبارات'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('العودة إلى الاختبارات'));
      await tester.pump();

      expect(service.assignedQuizRefreshCalls, 1);
    },
  );

  testWidgets('lesson completion keeps normal lesson action copy', (
    tester,
  ) async {
    _useMobile(tester);
    final service = FakeQuizService();

    await tester.pumpWidget(
      _wrap(mode: LearningCompletionMode.lesson, service: service),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('العودة للدروس 📚'), findsOneWidget);
    expect(find.text('العودة إلى الاختبارات'), findsNothing);
    expect(service.assignedQuizRefreshCalls, 0);
  });
}
