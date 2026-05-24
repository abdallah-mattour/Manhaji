import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/subject.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/mascot.dart';
import '../../widgets/stat_card.dart';
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
        body: Consumer<LessonProvider>(
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
                color: AppTheme.primaryGreen,
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
                    // Section header for subjects — bumped to titleLarge so it
                    // reads cleanly above the grid even on small phones.
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Row(
                          children: [
                            EightPointStar(
                              size: 16,
                              color: AppTheme.primaryGreen,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'المواد الدراسية',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                            // Post-screenshot fix (2026-05-24): was 0.98 (almost
                            // square), which clipped long Arabic subject names
                            // like "التربية الإسلامية" that wrap to 2 lines.
                            // 0.85 gives enough vertical room for the title + bar.
                            childAspectRatio: 0.85,
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

  /// Olive gradient header with Hakeem, name, and logout. Text is white at
  /// high alpha for clarity against the olive gradient.
  Widget _buildHeader(String name, int points, int streak) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDeep],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative motif — large eight-point star in the corner at
          // very low alpha so it's a watermark, not competition for text.
          Positioned(
            top: -16,
            right: -20,
            child: EightPointStar(
              size: 84,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Mascot(
                  mood: MascotMood.idle,
                  size: 60,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً! 👋',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showLogoutDialog(),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int points, int streak, int completed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.space4, AppTheme.space5, AppTheme.space4, AppTheme.space2),
      child: Row(
        children: [
          StatCard(
            emoji: '⭐',
            value: '$points',
            label: 'نقطة',
            color: AppTheme.primaryYellow,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            labelFontSize: 12,
          ),
          const SizedBox(width: 10),
          StatCard(
            emoji: '🔥',
            value: '$streak',
            label: 'أيام متتالية',
            color: AppTheme.primaryOrange,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            labelFontSize: 12,
          ),
          const SizedBox(width: 10),
          StatCard(
            emoji: '✅',
            value: '$completed',
            label: 'درس مكتمل',
            color: AppTheme.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            labelFontSize: 12,
          ),
        ],
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
    final lightColor = AppTheme.subjectLightColors[colorSlot];
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
            scale: _pressed ? 0.97 : 1.0,
            duration: AppTheme.motionInstant,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                boxShadow: AppTheme.coloredGlow(color),
                border: Border.all(
                  color: color.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Watermark star bottom-corner — far behind text.
                  Positioned(
                    bottom: -10,
                    left: -10,
                    child: EightPointStar(
                      size: 60,
                      color: color.withValues(alpha: 0.07),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.space4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon block with gradient fill
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                lightColor,
                                Color.lerp(lightColor, color, 0.25)!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusL),
                          ),
                          child: Icon(icon, size: 30, color: color),
                        ),
                        // Subject name — bumped to 16, w800 for clarity
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            widget.subject.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                              height: 1.2,
                            ),
                          ),
                        ),
                        // Progress with explicit count, clearer bg color.
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                              child: LinearProgressIndicator(
                                value: widget.subject.progressPercent,
                                backgroundColor: AppTheme.surfaceSubtle,
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${widget.subject.completedLessons} / ${widget.subject.totalLessons} درس',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
