import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/route_args.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/teacher_dashboard.dart';
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
      context.read<TeacherProvider>().loadDashboard();
    });
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
                onRetry: provider.loadDashboard,
              );
            }
            final dash = provider.dashboard;
            if (dash == null) return const SizedBox.shrink();

            return RefreshIndicator(
              onRefresh: () => provider.loadDashboard(),
              child: _TeacherDashboardContent(
                dashboard: dash,
                onOpenStudents: () =>
                    Navigator.pushNamed(context, AppRoutes.classStudents),
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
    required this.onOpenStudents,
  });

  final TeacherDashboard dashboard;
  final VoidCallback onOpenStudents;

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: AppTheme.space6),
                // Phase 5H.1: quick actions (duplicated the sidebar) and the
                // permanent "غير متاحة" analytics placeholders were removed;
                // the two real data panels now share one responsive row.
                _ResponsivePair(
                  leading: _TopStudentsCard(
                    students: dashboard.topStudents,
                    onOpenAll: onOpenStudents,
                  ),
                  trailing: _ClassPulseCard(dashboard: dashboard),
                ),
              ],
            ),
          ),
        ),
      ],
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
