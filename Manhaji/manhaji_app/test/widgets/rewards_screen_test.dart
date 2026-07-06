import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/models/dashboard.dart';
import 'package:manhaji_app/models/lesson.dart';
import 'package:manhaji_app/models/subject.dart';
import 'package:manhaji_app/providers/lesson_provider.dart';
import 'package:manhaji_app/providers/student_rewards_provider.dart';
import 'package:manhaji_app/screens/rewards/rewards_screen.dart';
import 'package:manhaji_app/services/api_service.dart';
import 'package:manhaji_app/services/lesson_service.dart';
import 'package:manhaji_app/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class FakeLocalStorage extends Fake implements LocalStorageService {
  String? selectedRewardId;

  @override
  bool get isLoggedIn => true;

  @override
  String? getSelectedRewardId() => selectedRewardId;

  @override
  Future<void> setSelectedRewardId(String rewardId) async {
    selectedRewardId = rewardId;
  }
}

class FakeLessonService extends LessonApiService {
  FakeLessonService(this.dashboard, this.storage) : super(ApiService(storage));

  final Dashboard dashboard;
  final LocalStorageService storage;

  @override
  Future<Dashboard> getDashboard() async => dashboard;

  @override
  Future<List<Subject>> getSubjectsByGrade(int gradeLevel) async => const [];

  @override
  Future<List<LessonSummary>> getLessonsBySubject(int subjectId) async =>
      const [];
}

Dashboard _dashboard({required int points, int streak = 4}) {
  return Dashboard(
    studentId: 1,
    fullName: 'ليان',
    gradeLevel: 1,
    currentStreak: streak,
    totalPoints: points,
    subjects: const [],
  );
}

Widget _wrap({required int points, FakeLocalStorage? storage}) {
  final localStorage = storage ?? FakeLocalStorage();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => LessonProvider(
          FakeLessonService(_dashboard(points: points), localStorage),
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => StudentRewardsProvider(localStorage),
      ),
    ],
    child: MaterialApp(theme: AppTheme.lightTheme, home: const RewardsScreen()),
  );
}

void _useMobile(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('rewards page renders title and categories', (tester) async {
    _useMobile(tester);

    await tester.pumpWidget(_wrap(points: 220));
    await tester.pumpAndSettle();

    expect(find.text('متجر المكافآت'), findsAtLeastNWidgets(1));
    expect(find.text('الصور الرمزية'), findsOneWidget);
    await _scrollTo(tester, find.text('الإطارات'));
    expect(find.text('الإطارات'), findsOneWidget);
    await _scrollTo(tester, find.text('الشارات'));
    expect(find.text('الشارات'), findsOneWidget);
    await _scrollTo(tester, find.text('حديقة مناهجي'));
    expect(find.text('حديقة مناهجي'), findsOneWidget);
  });

  testWidgets('locked reward shows required stars and remaining stars', (
    tester,
  ) async {
    _useMobile(tester);

    await tester.pumpWidget(_wrap(points: 40));
    await tester.pumpAndSettle();

    final rewardCard = find.byKey(const ValueKey('reward-card-badge-streak'));
    await _scrollTo(tester, rewardCard);
    expect(
      find.descendant(of: rewardCard, matching: find.text('50 نجمة')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rewardCard, matching: find.text('يحتاج 10 نجمة')),
      findsOneWidget,
    );
  });

  testWidgets('unlocked reward shows usable action', (tester) async {
    _useMobile(tester);

    await tester.pumpWidget(_wrap(points: 100));
    await tester.pumpAndSettle();

    final rewardCard = find.byKey(const ValueKey('reward-card-avatar-reader'));
    expect(rewardCard, findsOneWidget);
    expect(
      find.descendant(of: rewardCard, matching: find.text('استخدم')),
      findsOneWidget,
    );
  });

  testWidgets('selecting cosmetic reward persists locally', (tester) async {
    _useMobile(tester);
    final storage = FakeLocalStorage();

    await tester.pumpWidget(_wrap(points: 100, storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reward-action-avatar-reader')));
    await tester.pumpAndSettle();

    expect(storage.selectedRewardId, 'avatar-reader');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reward-card-avatar-reader')),
        matching: find.text('مفتوح'),
      ),
      findsOneWidget,
    );
  });
}
