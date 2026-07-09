import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/route_args.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/teacher_dashboard.dart';
import '../../models/teacher_mistake_analytics.dart';
import '../../models/teacher_quiz.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/staff_metric_card.dart';
import '../../widgets/staff_web_shell.dart';
import 'teacher_shell_navigation.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load(context.read<TeacherProvider>());
    });
  }

  Future<void> _load(TeacherProvider provider) async {
    await Future.wait([
      provider.loadDashboard(),
      provider.loadStudents(),
      provider.loadMistakeAnalytics(limit: 5),
      provider.loadTeacherQuizzes(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: 'لوحة المعلم',
        subtitle: 'نظرة مباشرة على أداء الصف من بيانات الخادم',
        roleLabel: 'مساحة المعلم',
        currentRoute: AppRoutes.teacherDashboard,
        items: teacherShellItems(context),
        child: Consumer<TeacherProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.dashboard == null) {
              return const LoadingState();
            }
            if (provider.error != null && provider.dashboard == null) {
              return ErrorState(
                message: provider.error!,
                onRetry: () => _load(provider),
              );
            }
            final dash = provider.dashboard;
            if (dash == null) return const SizedBox.shrink();

            return RefreshIndicator(
              onRefresh: () => _load(provider),
              child: _TeacherDashboardContent(
                dashboard: dash,
                students: provider.students,
                mistakeAnalytics: provider.mistakeAnalytics,
                isMistakeAnalyticsLoading: provider.isMistakeAnalyticsLoading,
                mistakeAnalyticsError: provider.mistakeAnalyticsError,
                teacherQuizzes: provider.teacherQuizzes,
                isTeacherQuizzesLoading: provider.isTeacherQuizzesLoading,
                teacherQuizzesError: provider.teacherQuizzesError,
                onOpenStudents: () =>
                    Navigator.pushNamed(context, AppRoutes.classStudents),
                onOpenMistakes: () =>
                    Navigator.pushNamed(context, AppRoutes.teacherMistakes),
                onOpenQuizzes: () =>
                    Navigator.pushNamed(context, AppRoutes.teacherQuizzes),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TeacherDashboardContent extends StatelessWidget {
  const _TeacherDashboardContent({
    required this.dashboard,
    required this.students,
    required this.mistakeAnalytics,
    required this.isMistakeAnalyticsLoading,
    required this.mistakeAnalyticsError,
    required this.teacherQuizzes,
    required this.isTeacherQuizzesLoading,
    required this.teacherQuizzesError,
    required this.onOpenStudents,
    required this.onOpenMistakes,
    required this.onOpenQuizzes,
  });

  final TeacherDashboard dashboard;
  final List<ClassStudentSummary>? students;
  final TeacherMistakeAnalytics? mistakeAnalytics;
  final bool isMistakeAnalyticsLoading;
  final String? mistakeAnalyticsError;
  final List<TeacherQuizSummary>? teacherQuizzes;
  final bool isTeacherQuizzesLoading;
  final String? teacherQuizzesError;
  final VoidCallback onOpenStudents;
  final VoidCallback onOpenMistakes;
  final VoidCallback onOpenQuizzes;

  @override
  Widget build(BuildContext context) {
    final followUpStudents = (students ?? const <ClassStudentSummary>[])
        .where(
          (student) =>
              student.averageMastery < 60 || student.currentStreak == 0,
        )
        .toList(growable: false);
    final mistakes = mistakeAnalytics?.mistakes ?? const <TeacherMistakeRow>[];
    final publishedQuizzes = (teacherQuizzes ?? const <TeacherQuizSummary>[])
        .where((quiz) => quiz.isPublished)
        .toList(growable: false);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space6),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TeacherHeader(dashboard: dashboard),
                const SizedBox(height: AppTheme.space5),
                _MetricsGrid(
                  dashboard: dashboard,
                  onOpenStudents: onOpenStudents,
                ),
                const SizedBox(height: AppTheme.space5),
                _TeacherInsightGrid(
                  followUpCount: followUpStudents.length,
                  mistakeCount: mistakes.length,
                  publishedQuizCount: publishedQuizzes.length,
                  onOpenStudents: onOpenStudents,
                  onOpenMistakes: onOpenMistakes,
                  onOpenQuizzes: onOpenQuizzes,
                ),
                const SizedBox(height: AppTheme.space5),
                _TeacherActionStrip(
                  onOpenMistakes: onOpenMistakes,
                  onOpenQuizzes: onOpenQuizzes,
                ),
                const SizedBox(height: AppTheme.space5),
                _ResponsivePair(
                  leading: _TopStudentsCard(
                    students: dashboard.topStudents,
                    onOpenAll: onOpenStudents,
                  ),
                  trailing: _ClassPulseCard(dashboard: dashboard),
                ),
                const SizedBox(height: AppTheme.space5),
                _ResponsivePair(
                  leading: _FollowUpStudentsCard(
                    students: followUpStudents,
                    onOpenAll: onOpenStudents,
                  ),
                  trailing: _PublishedQuizzesCard(
                    quizzes: publishedQuizzes,
                    isLoading: isTeacherQuizzesLoading,
                    error: teacherQuizzesError,
                    onOpenAll: onOpenQuizzes,
                  ),
                ),
                const SizedBox(height: AppTheme.space5),
                _RecentMistakesCard(
                  mistakes: mistakes,
                  isLoading: isMistakeAnalyticsLoading,
                  error: mistakeAnalyticsError,
                  onOpenAll: onOpenMistakes,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TeacherInsightGrid extends StatelessWidget {
  const _TeacherInsightGrid({
    required this.followUpCount,
    required this.mistakeCount,
    required this.publishedQuizCount,
    required this.onOpenStudents,
    required this.onOpenMistakes,
    required this.onOpenQuizzes,
  });

  final int followUpCount;
  final int mistakeCount;
  final int publishedQuizCount;
  final VoidCallback onOpenStudents;
  final VoidCallback onOpenMistakes;
  final VoidCallback onOpenQuizzes;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _InsightCard(
        key: const ValueKey('teacher-insight-follow-up'),
        title: 'الطلاب الذين يحتاجون متابعة',
        value: '$followUpCount',
        subtitle: followUpCount == 0
            ? 'لا توجد بيانات كافية حاليًا'
            : 'إتقان منخفض أو سلسلة متوقفة',
        icon: Icons.priority_high_rounded,
        color: AppTheme.primaryRed,
        onTap: onOpenStudents,
      ),
      _InsightCard(
        key: const ValueKey('teacher-insight-mistakes'),
        title: 'آخر أخطاء الطلاب',
        value: '$mistakeCount',
        subtitle: mistakeCount == 0
            ? 'لا توجد أخطاء مسجلة'
            : 'من تحليل الأخطاء',
        icon: Icons.psychology_alt_rounded,
        color: AppTheme.primaryOrange,
        onTap: onOpenMistakes,
      ),
      _InsightCard(
        key: const ValueKey('teacher-insight-published-quizzes'),
        title: 'الاختبارات المنشورة',
        value: '$publishedQuizCount',
        subtitle: publishedQuizCount == 0
            ? 'لا توجد اختبارات منشورة'
            : 'جاهزة للطلاب',
        icon: Icons.assignment_turned_in_rounded,
        color: AppTheme.primaryGreen,
        onTap: onOpenQuizzes,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 980
            ? 3
            : width >= 640
            ? 2
            : 1;
        const gap = AppTheme.space4;
        final itemWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space5),
          decoration: _panelDecoration(),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherActionStrip extends StatelessWidget {
  const _TeacherActionStrip({
    required this.onOpenMistakes,
    required this.onOpenQuizzes,
  });

  final VoidCallback onOpenMistakes;
  final VoidCallback onOpenQuizzes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final actions = [
          _ActionButton(
            key: const ValueKey('teacher-dashboard-open-mistakes'),
            icon: Icons.analytics_rounded,
            label: 'تحليل الأخطاء',
            onPressed: onOpenMistakes,
          ),
          _ActionButton(
            key: const ValueKey('teacher-dashboard-open-quizzes'),
            icon: Icons.add_task_rounded,
            label: 'إنشاء اختبار',
            onPressed: onOpenQuizzes,
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: _panelDecoration(),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppTheme.space3),
                      actions[i],
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: actions[0]),
                    const SizedBox(width: AppTheme.space3),
                    Expanded(child: actions[1]),
                  ],
                ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w900,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryTerracotta,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({required this.dashboard});

  final TeacherDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final department = dashboard.department?.trim();
    final assignedGrade = dashboard.assignedGrade;
    final meta = [
      if (department != null && department.isNotEmpty) department,
      if (assignedGrade != null) 'الصف $assignedGrade',
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryTerracotta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppTheme.primaryTerracotta,
              size: 32,
            ),
          ),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، ${dashboard.fullName.trim().isEmpty ? "المعلم" : dashboard.fullName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Text(
                  meta.isEmpty
                      ? 'متابعة صفك من مؤشرات حقيقية'
                      : meta.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.dashboard, required this.onOpenStudents});

  final TeacherDashboard dashboard;
  final VoidCallback onOpenStudents;

  @override
  Widget build(BuildContext context) {
    final cards = [
      StaffMetricCard(
        title: 'إجمالي الطلاب',
        value: '${dashboard.totalStudents}',
        subtitle: 'افتح قائمة الطلاب',
        icon: Icons.people_alt_rounded,
        color: AppTheme.primaryBlue,
        onTap: onOpenStudents,
      ),
      StaffMetricCard(
        title: 'النشطون هذا الأسبوع',
        value: '${dashboard.activeThisWeek}',
        subtitle: 'متابعة نشاط الصف',
        icon: Icons.trending_up_rounded,
        color: AppTheme.primaryGreen,
        onTap: onOpenStudents,
      ),
      StaffMetricCard(
        title: 'الدروس المكتملة',
        value: '${dashboard.lessonsCompletedTotal}',
        subtitle: 'إنجازات الطلاب',
        icon: Icons.check_circle_outline_rounded,
        color: AppTheme.primaryPurple,
        onTap: onOpenStudents,
      ),
      StaffMetricCard(
        title: 'متوسط الإتقان',
        value: '${dashboard.averageMasteryAcrossClass.toStringAsFixed(0)}%',
        subtitle: 'متوسط الصف الحالي',
        icon: Icons.insights_rounded,
        color: AppTheme.primaryOrange,
        onTap: onOpenStudents,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1120
            ? 4
            : width >= 720
            ? 2
            : 1;
        const spacing = AppTheme.space4;
        final cardWidth = (width - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.leading, required this.trailing});

  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              leading,
              const SizedBox(height: AppTheme.space4),
              trailing,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: leading),
            const SizedBox(width: AppTheme.space4),
            Expanded(flex: 2, child: trailing),
          ],
        );
      },
    );
  }
}

class _ClassPulseCard extends StatelessWidget {
  const _ClassPulseCard({required this.dashboard});

  final TeacherDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final activeRatio = dashboard.totalStudents > 0
        ? (dashboard.activeThisWeek / dashboard.totalStudents)
              .clamp(0.0, 1.0)
              .toDouble()
        : 0.0;
    final masteryRatio = (dashboard.averageMasteryAcrossClass / 100)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'نبض الصف',
            subtitle: 'مؤشرات مختصرة من لوحة المعلم',
          ),
          const SizedBox(height: AppTheme.space5),
          _ProgressRow(
            label: 'النشاط الأسبوعي',
            value: '${(activeRatio * 100).round()}%',
            progress: activeRatio,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: AppTheme.space4),
          _ProgressRow(
            label: 'متوسط الإتقان',
            value: '${dashboard.averageMasteryAcrossClass.toStringAsFixed(0)}%',
            progress: masteryRatio,
            color: AppTheme.primaryOrange,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space2),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _TopStudentsCard extends StatelessWidget {
  const _TopStudentsCard({required this.students, required this.onOpenAll});

  final List<ClassStudentSummary> students;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'أفضل الطلاب',
            subtitle: 'ترتيب مختصر حسب بيانات الصف',
            actionLabel: 'عرض الكل',
            onAction: onOpenAll,
          ),
          const SizedBox(height: AppTheme.space4),
          if (students.isEmpty)
            const _EmptyAnalyticsCard(
              icon: Icons.people_outline_rounded,
              title: 'لا يوجد طلاب حالياً',
              message: 'ستظهر قائمة الطلاب بعد ربطهم بحساب المعلم.',
            )
          else
            Column(
              children: [
                for (var i = 0; i < students.length; i++) ...[
                  _StudentRow(student: students[i], rank: i + 1),
                  if (i != students.length - 1)
                    const Divider(height: 1, color: AppTheme.surfaceMuted),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.rank});

  final ClassStudentSummary student;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.teacherStudentDetail,
        arguments: StudentDetailArgs(student.studentId),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space3),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryTerracotta.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryTerracotta,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space3),
            CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
              child: Text(
                student.fullName.isNotEmpty ? student.fullName[0] : '?',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'النقاط: ${student.totalPoints} • الإتقان: ${student.averageMastery.toStringAsFixed(0)}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpStudentsCard extends StatelessWidget {
  const _FollowUpStudentsCard({
    required this.students,
    required this.onOpenAll,
  });

  final List<ClassStudentSummary> students;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final visible = students.take(4).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'الطلاب الذين يحتاجون متابعة',
            subtitle: 'طلاب بإتقان أقل من 60% أو سلسلة أيام متوقفة',
            actionLabel: 'عرض الطلاب',
            onAction: onOpenAll,
          ),
          const SizedBox(height: AppTheme.space4),
          if (visible.isEmpty)
            const _EmptyAnalyticsCard(
              icon: Icons.verified_rounded,
              title: 'لا توجد بيانات كافية حاليًا',
              message: 'عند توفر طلاب بإتقان منخفض ستظهر أسماؤهم هنا.',
            )
          else
            Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _FollowUpStudentRow(student: visible[i]),
                  if (i != visible.length - 1)
                    const Divider(height: 1, color: AppTheme.surfaceMuted),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _FollowUpStudentRow extends StatelessWidget {
  const _FollowUpStudentRow({required this.student});

  final ClassStudentSummary student;

  @override
  Widget build(BuildContext context) {
    final reason = student.averageMastery < 60
        ? 'الإتقان ${student.averageMastery.toStringAsFixed(0)}%'
        : 'السلسلة متوقفة';
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.teacherStudentDetail,
        arguments: StudentDetailArgs(student.studentId),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space3),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.10),
              child: Text(
                student.fullName.isNotEmpty ? student.fullName[0] : '?',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryRed,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_back_ios_rounded,
              size: 16,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _PublishedQuizzesCard extends StatelessWidget {
  const _PublishedQuizzesCard({
    required this.quizzes,
    required this.isLoading,
    required this.error,
    required this.onOpenAll,
  });

  final List<TeacherQuizSummary> quizzes;
  final bool isLoading;
  final String? error;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final visible = quizzes.take(4).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'الاختبارات المنشورة',
            subtitle: 'اختبارات منشورة من قائمة اختباراتك',
            actionLabel: 'إدارة الاختبارات',
            onAction: onOpenAll,
          ),
          const SizedBox(height: AppTheme.space4),
          if (isLoading)
            const _EmptyAnalyticsCard(
              icon: Icons.hourglass_top_rounded,
              title: 'جاري تحميل الاختبارات',
              message: 'يتم جلب قائمة الاختبارات من الخادم.',
            )
          else if (error != null)
            _EmptyAnalyticsCard(
              icon: Icons.cloud_off_rounded,
              title: 'تعذر تحميل الاختبارات',
              message: error!,
            )
          else if (visible.isEmpty)
            const _EmptyAnalyticsCard(
              icon: Icons.assignment_outlined,
              title: 'لا توجد اختبارات منشورة',
              message: 'أنشئ اختباراً ثم انشره ليظهر هنا.',
            )
          else
            Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _QuizRow(quiz: visible[i]),
                  if (i != visible.length - 1)
                    const Divider(height: 1, color: AppTheme.surfaceMuted),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _QuizRow extends StatelessWidget {
  const _QuizRow({required this.quiz});

  final TeacherQuizSummary quiz;

  @override
  Widget build(BuildContext context) {
    final subject = quiz.subjectName?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space3),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (subject != null && subject.isNotEmpty) subject,
                    '${quiz.questionCount} سؤال',
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentMistakesCard extends StatelessWidget {
  const _RecentMistakesCard({
    required this.mistakes,
    required this.isLoading,
    required this.error,
    required this.onOpenAll,
  });

  final List<TeacherMistakeRow> mistakes;
  final bool isLoading;
  final String? error;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final visible = mistakes.take(5).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'آخر أخطاء الطلاب',
            subtitle: 'أحدث الأخطاء المتاحة من تحليل الأخطاء',
            actionLabel: 'تحليل الأخطاء',
            onAction: onOpenAll,
          ),
          const SizedBox(height: AppTheme.space4),
          if (isLoading)
            const _EmptyAnalyticsCard(
              icon: Icons.hourglass_top_rounded,
              title: 'جاري تحميل الأخطاء',
              message: 'يتم جلب تحليل الأخطاء من الخادم.',
            )
          else if (error != null)
            _EmptyAnalyticsCard(
              icon: Icons.cloud_off_rounded,
              title: 'تعذر تحميل الأخطاء',
              message: error!,
            )
          else if (visible.isEmpty)
            const _EmptyAnalyticsCard(
              icon: Icons.check_circle_outline_rounded,
              title: 'لا توجد أخطاء مسجلة',
              message: 'ستظهر الأخطاء هنا بعد أن يجيب الطلاب على الأسئلة.',
            )
          else
            Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _MistakeRow(row: visible[i]),
                  if (i != visible.length - 1)
                    const Divider(height: 1, color: AppTheme.surfaceMuted),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _MistakeRow extends StatelessWidget {
  const _MistakeRow({required this.row});

  final TeacherMistakeRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space3),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.studentName.trim().isEmpty
                      ? 'طالب غير معروف'
                      : row.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.lessonTitle.trim().isEmpty
                      ? row.subjectName
                      : row.lessonTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            flex: 4,
            child: Text(
              row.questionText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textGray,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          _MiniBadge(
            label: '${row.mistakeCount} خطأ',
            color: row.commonMistake
                ? AppTheme.primaryRed
                : AppTheme.primaryOrange,
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                  height: 1.35,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: AppTheme.space1),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              actionLabel!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textLight, size: 28),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusM),
    boxShadow: AppTheme.elevationLow,
    border: Border.all(color: AppTheme.surfaceMuted, width: 1),
  );
}
