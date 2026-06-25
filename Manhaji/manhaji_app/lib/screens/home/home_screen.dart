import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../config/api_config.dart';
import '../../models/subject.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../services/local_storage_service.dart';
import '../../services/quiz_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/mascot.dart';
import '../../widgets/vibrant_background.dart';
import '../learning/learning_screen.dart';
import '../subject/subject_lessons_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final lessonProvider = context.read<LessonProvider>();
    await lessonProvider.loadDashboard();
    if (!mounted) return;
    if (lessonProvider.dashboard == null && lessonProvider.errorMessage != null) {
      final storage = context.read<LocalStorageService>();
      if (!storage.isLoggedIn) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login, (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: VibrantBackground(
          child: Consumer<LessonProvider>(
          builder: (context, lessonProvider, _) {
            if (lessonProvider.isLoading && lessonProvider.dashboard == null) {
              return const LoadingState();
            }

            if (lessonProvider.errorMessage != null &&
                lessonProvider.dashboard == null) {
              return ErrorState(
                message: lessonProvider.errorMessage!,
                onRetry: lessonProvider.loadDashboard,
              );
            }

            final dashboard = lessonProvider.dashboard;
            if (dashboard == null) {
              return ErrorState(
                message: 'تعذّر تحميل البيانات',
                onRetry: lessonProvider.loadDashboard,
              );
            }

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () => lessonProvider.loadDashboard(),
                color: AppTheme.primaryTerracotta,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(dashboard.fullName,
                          dashboard.totalPoints, dashboard.currentStreak),
                    ),
                    SliverToBoxAdapter(
                      child: _buildStatsRow(
                        dashboard.totalPoints,
                        dashboard.currentStreak,
                        dashboard.subjects.fold<int>(
                            0, (sum, s) => sum + s.completedLessons),
                      ),
                    ),
                    // Daily-goal progress card — overall lessons completed vs
                    // total across all subjects, with a warm progress bar.
                    if (dashboard.subjects.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _DailyGoalCard(
                          completed: dashboard.subjects.fold<int>(
                              0, (sum, s) => sum + s.completedLessons),
                          total: dashboard.subjects.fold<int>(
                              0, (sum, s) => sum + s.totalLessons),
                        ),
                      ),
                    // Knowledge Tracing "Challenge Me" — personalized adaptive
                    // quiz entry point. Only shown when the student has
                    // subjects to be challenged on.
                    if (dashboard.subjects.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _ChallengeMeBanner(
                          onTap: () => _openChallengePicker(dashboard.subjects),
                        ),
                      ),
                    // Section header removed as it's now part of _buildStatsRow/Header style
                    if (dashboard.subjects.isEmpty)
                      // Defensive empty state — without this the user just
                      // sees a section header over blank space and assumes
                      // the app is broken. Most common cause: the student's
                      // grade has no Subject rows yet (DataSeeder didn't run
                      // for that grade's curriculum JSON). Tell the user
                      // what's wrong and what to do.
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppTheme.space5,
                              AppTheme.space6,
                              AppTheme.space5,
                              AppTheme.space8),
                          child: _NoSubjectsCard(
                            gradeLevel: dashboard.gradeLevel,
                            onRetry: () => lessonProvider.loadDashboard(),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space4),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            // Post-screenshot fix v2 (2026-05-24): 0.85 still
                            // overflowed by 1.3px after the icon grew to 72px
                            // and title bumped to 18pt w900. 0.78 gives a
                            // comfortable ~10px of vertical headroom for the
                            // longest 2-line Arabic name ("التربية الإسلامية").
                            childAspectRatio: 0.78,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _SubjectCard(
                                subject: dashboard.subjects[index],
                                index: index,
                                onTap: () => _openSubject(
                                    dashboard.subjects[index], index),
                              );
                            },
                            childCount: dashboard.subjects.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            );
          },
        ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  void _openSubject(Subject subject, int index) {
    // Same name-based dispatch as the card itself, so the subject screen's
    // app bar tints to the right colour regardless of API order.
    final slot = _SubjectColorRouter.indexForName(subject.name);
    final color = AppTheme.subjectColors[slot];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectLessonsScreen(
          subjectId: subject.id,
          subjectName: subject.name,
          subjectColor: color,
        ),
      ),
    );
  }

  /// "Challenge Me": pick a subject, then generate a personalized adaptive
  /// quiz for it. Scope is one subject at a time (per the project proposal),
  /// so we present a simple subject chooser bottom sheet.
  void _openChallengePicker(List<Subject> subjects) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ChallengeSubjectPicker(
        subjects: subjects,
        onPick: (subject) {
          Navigator.pop(sheetCtx);
          _startChallenge(subject);
        },
      ),
    );
  }

  /// Generate the personalized quiz for [subject] then push the quiz UI.
  /// Shows a brief loading dialog while the backend's BKT selector runs.
  Future<void> _startChallenge(Subject subject) async {
    final quizService = context.read<QuizApiService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryTerracotta),
      ),
    );

    try {
      final quiz = await quizService.generatePersonalizedQuiz(subject.id);
      navigator.pop(); // dismiss loading dialog
      if (quiz.questions.isEmpty) {
        messenger.showSnackBar(const SnackBar(
          content: Text('لا توجد أسئلة كافية لهذا التحدّي بعد.',
              style: TextStyle(fontFamily: 'Cairo')),
        ));
        return;
      }
      navigator.push(MaterialPageRoute(
        builder: (_) => LearningScreen(
          lessonId: -1, // unused in personalized mode
          lessonTitle: quiz.title,
          personalizedQuiz: quiz,
        ),
      ));
    } catch (e) {
      navigator.pop(); // dismiss loading dialog
      messenger.showSnackBar(SnackBar(
        content: Text(extractError(e),
            style: const TextStyle(fontFamily: 'Cairo')),
      ));
    }
  }

  /// Duolingo-style top bar with stats.
  Widget _buildHeader(String name, int points, int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceMuted, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mascot Avatar (Left)
          GestureDetector(
            onTap: () => _showLogoutDialog(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surfaceMuted, width: 2),
              ),
              child: const ClipOval(
                child: Mascot(mood: MascotMood.idle, size: 36),
              ),
            ),
          ),
          
          // Stats Row (Center)
          Row(
            children: [
              _buildStatItem('🔥', '$streak', AppTheme.primaryOrange),
              const SizedBox(width: 16),
              _buildStatItem('⭐', '$points', AppTheme.primaryYellow),
              const SizedBox(width: 16),
              _buildStatItem('💎', '0', AppTheme.primaryBlue), // Mock Gems
            ],
          ),

          // Settings/Profile icon (Right)
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.person_rounded, color: AppTheme.textGray, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int points, int streak, int completed) {
    // We moved stats to the header, so this can return a minimal sub-header
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        'موادي الدراسية',
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.cardWhite,
          elevation: 0,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.textLight,
          selectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600),
          onTap: (index) {
            if (index == 1) {
              Navigator.pushNamed(context, AppRoutes.progress);
            } else if (index == 2) {
              Navigator.pushNamed(context, AppRoutes.settings);
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded), label: 'تقدمي'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
          title: const Text(
            'تسجيل الخروج',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.textDark,
            ),
          ),
          content: const Text(
            'هل تريد تسجيل الخروج؟',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                color: AppTheme.textDark,
                height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppTheme.textGray,
                    fontWeight: FontWeight.w700,
                  )),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthProvider>().logout();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                minimumSize: const Size(120, 48),
              ),
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared subject-name → colour-slot dispatcher. Same heuristic as
/// `_SubjectCardState._colorIndexForSubject` — kept as a top-level helper so
/// `_HomeScreenState._openSubject` can use it without making the per-card
/// State public.
class _SubjectColorRouter {
  static int indexForName(String name) {
    final lower = name.toLowerCase();
    if (name.contains('الرياضيات') || lower.contains('math')) return 1;
    if (name.contains('الإسلامية') ||
        name.contains('الاسلامية') ||
        name.contains('التربية الإسلام') ||
        lower.contains('islam')) {
      return 2;
    }
    if (name.contains('الإنجليزية') || lower.contains('english')) return 3;
    return 0; // Arabic + unknown both fall to olive.
  }

  /// Subject icon by name — same semantic mapping as `_SubjectCard`'s
  /// instance helper, exposed statically so off-card widgets (the Challenge
  /// Me subject picker) can render the matching icon.
  static IconData iconForName(String name) {
    switch (indexForName(name)) {
      case 1:
        return Icons.calculate_rounded;   // math
      case 2:
        return Icons.mosque_rounded;      // islamic
      case 3:
        return Icons.language_rounded;    // english
      default:
        return Icons.menu_book_rounded;   // arabic + unknown
    }
  }
}

enum _SubjectKind { arabic, math, islamic, english, unknown }

/// Empty-state when the dashboard returns zero subjects for the student's
/// grade. Most common cause: the student is in a grade whose curriculum JSON
/// hasn't been seeded into MySQL yet — usually because the backend was
/// running before the Grade 2 (or 3, 4) JSON files landed and needs a
/// restart. Surface this clearly instead of silently rendering an empty
/// grid that looks like the app is broken.
class _NoSubjectsCard extends StatelessWidget {
  final int gradeLevel;
  final VoidCallback onRetry;

  const _NoSubjectsCard({required this.gradeLevel, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: AppTheme.elevationLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Mascot(mood: MascotMood.sad, size: 110),
          ),
          const AppGap.v4(),
          Text(
            'لا توجد مواد للصف $gradeLevel بعد',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const AppGap.v2(),
          const Text(
            'يبدو أن المنهج لهذا الصف لم يُحمَّل على الخادم. أعِد تشغيل الخادم لمزامنة المواد، ثم اسحب للأسفل للتحديث.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
              height: 1.6,
            ),
          ),
          const AppGap.v5(),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تحديث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subject grid card — large icon block, clear text, animated bar.
///
/// Pulled out as its own widget so the staggered entrance + tap-scale
/// doesn't bloat the parent build method. The decorative star sits
/// behind the icon with low alpha so it doesn't compete with the
/// subject name.
class _SubjectCard extends StatefulWidget {
  final Subject subject;
  final int index;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _pressed = false;

  /// Post-screenshot fix (2026-05-24): the previous index-based icon array
  /// assumed a specific subject order from the API and got scrambled when
  /// the actual order was different (English showed calculator, Math showed
  /// mosque, Islamic showed globe). Dispatch by subject name instead — works
  /// regardless of API ordering, and a brand-new subject just falls back to
  /// the default book icon instead of stealing some other subject's icon.
  ///
  /// The same fix applies to `_colorIndexForSubject` below — the
  /// AppTheme.subjectColors palette is meant to be semantically tied to the
  /// subject (Arabic=olive, Math=terracotta, Islamic=gold, English=teal),
  /// but index-by-position scrambled that whenever the API returned a
  /// different order.
  IconData _iconForSubject(String name) {
    final kind = _subjectKind(name);
    switch (kind) {
      case _SubjectKind.math:
        return Icons.calculate_rounded;
      case _SubjectKind.islamic:
        return Icons.mosque_rounded;
      case _SubjectKind.english:
        return Icons.language_rounded;
      case _SubjectKind.arabic:
      case _SubjectKind.unknown:
        return Icons.menu_book_rounded;
    }
  }

  /// Maps a subject to its slot in AppTheme.subjectColors / subjectLightColors
  /// (slot 0 = olive, 1 = terracotta, 2 = gold, 3 = teal). When the API
  /// returns subjects in a different order this keeps the semantic colour
  /// stable per subject. Unknown subjects fall back to olive.
  int _colorIndexForSubject(String name) {
    switch (_subjectKind(name)) {
      case _SubjectKind.arabic:
      case _SubjectKind.unknown:
        return 0; // olive — heritage
      case _SubjectKind.math:
        return 1; // terracotta — energy
      case _SubjectKind.islamic:
        return 2; // gold — sacred
      case _SubjectKind.english:
        return 3; // teal — international
    }
  }

  _SubjectKind _subjectKind(String name) {
    final lower = name.toLowerCase();
    if (name.contains('الرياضيات') || lower.contains('math')) {
      return _SubjectKind.math;
    }
    if (name.contains('الإسلامية') ||
        name.contains('الاسلامية') ||
        name.contains('التربية الإسلام') ||
        lower.contains('islam')) {
      return _SubjectKind.islamic;
    }
    if (name.contains('الإنجليزية') || lower.contains('english')) {
      return _SubjectKind.english;
    }
    if (name.contains('العربية') || lower.contains('arabic')) {
      return _SubjectKind.arabic;
    }
    return _SubjectKind.unknown;
  }

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
    );
    _opacity = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    // Stagger each card 80ms after the previous so the grid waves in.
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorSlot = _colorIndexForSubject(widget.subject.name);
    final color = AppTheme.subjectColors[colorSlot];
    final icon = _iconForSubject(widget.subject.name);

    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: AppTheme.motionInstant,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                border: Border.all(
                  color: AppTheme.surfaceMuted,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.surfaceMuted,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover image when the backend provides one; otherwise a
                    // colored icon bubble (image-ready with graceful fallback).
                    Center(
                      child: _SubjectVisual(
                        coverImage: widget.subject.coverImage,
                        icon: icon,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Subject name — Flexible so the text always gets the
                    // available vertical space without pushing the progress
                    // bar past the card boundary. ellipsis on long names.
                    Flexible(
                      child: Text(
                        widget.subject.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      child: LinearProgressIndicator(
                        value: widget.subject.progressPercent,
                        backgroundColor: AppTheme.surfaceSubtle,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Challenge Me" entry banner — the personalized adaptive-quiz call to action.
/// Visually distinct from the subject cards (purple gradient + bolt) so it
/// reads as a special action, not just another subject.
/// Subject card visual: a rounded cover image when the backend supplies one,
/// otherwise the colored icon bubble (our existing design as the fallback).
/// Makes the subject cards image-ready with no backend change required today.
class _SubjectVisual extends StatelessWidget {
  final String? coverImage;
  final IconData icon;
  final Color color;

  const _SubjectVisual({
    required this.coverImage,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final url = coverImage;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: CachedNetworkImage(
          imageUrl: ApiConfig.resolveMediaUrl(url),
          width: 84,
          height: 84,
          fit: BoxFit.cover,
          placeholder: (context, url) => _bubble(),
          errorWidget: (context, url, error) => _bubble(),
        ),
      );
    }
    return _bubble();
  }

  Widget _bubble() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Icon(icon, size: 36, color: color),
    );
  }
}

/// Daily-goal progress card — borrowed composition (warm card, fraction,
/// progress bar, encouraging line) re-created with our tokens + Arabic + RTL.
class _DailyGoalCard extends StatelessWidget {
  final int completed;
  final int total;

  const _DailyGoalCard({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction =
        total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0).toDouble();
    final allDone = fraction >= 1.0;
    final message = total == 0
        ? 'ستبدأ دروسك قريباً!'
        : allDone
            ? 'أحسنت! أكملت كل الدروس 🎉'
            : 'استمرّ، أنت تتقدّم بشكل رائع!';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space2),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppTheme.primaryYellow, width: 2),
          boxShadow: AppTheme.elevationLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                const Text(
                  'هدف اليوم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  total == 0 ? '—' : '$completed / $total',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryTerracotta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space3),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 14,
                backgroundColor: AppTheme.surfaceMuted,
                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryYellow),
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeMeBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _ChallengeMeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.space4, AppTheme.space2, AppTheme.space4, AppTheme.space2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.primaryPurpleDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurpleDeep,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space5, vertical: AppTheme.space4),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 34)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'تحدَّ نفسك!',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'اختبار ذكيّ يركّز على ما تحتاج تدريبه',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet subject chooser for "Challenge Me". One subject at a time,
/// per the project proposal's scope for the personalized quiz.
class _ChallengeSubjectPicker extends StatelessWidget {
  final List<Subject> subjects;
  final void Function(Subject) onPick;

  const _ChallengeSubjectPicker({required this.subjects, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'اختر مادّة للتحدّي',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ...subjects.map((s) {
            final slot = _SubjectColorRouter.indexForName(s.name);
            final color = AppTheme.subjectColors[slot];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  onTap: () => onPick(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    child: Row(
                      children: [
                        Icon(_SubjectColorRouter.iconForName(s.name),
                            color: color, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            s.name,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        Icon(Icons.bolt_rounded, color: color, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
