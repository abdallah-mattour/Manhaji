import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/route_args.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/teacher_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/vibrant_background.dart';
import '../../widgets/loading_state.dart';
import '../question_bank/question_bank_subjects_screen.dart';

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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المعلم'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              },
            ),
          ],
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
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
                child: _TeacherDashboardContent(dashboard: dash),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TeacherDashboardContent extends StatelessWidget {
  final TeacherDashboard dashboard;

  const _TeacherDashboardContent({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 980
            ? 980.0
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxWidth,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                _TeacherHeader(dashboard: dashboard),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.people_rounded,
                      color: AppTheme.primaryBlue,
                      title: 'الطلاب',
                      value: '${dashboard.totalStudents}',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.trending_up_rounded,
                      color: AppTheme.primaryGreen,
                      title: 'نشطون هذا الأسبوع',
                      value: '${dashboard.activeThisWeek}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      color: AppTheme.primaryPurple,
                      title: 'دروس مكتملة',
                      value: '${dashboard.lessonsCompletedTotal}',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.school_rounded,
                      color: AppTheme.primaryOrange,
                      title: 'متوسط الإتقان',
                      value:
                          '${dashboard.averageMasteryAcrossClass.toStringAsFixed(0)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ClassPulseCard(dashboard: dashboard),
                const SizedBox(height: 18),
                _ActionTile(
                  icon: Icons.quiz_rounded,
                  title: 'بنك الأسئلة',
                  subtitle: 'استعرض الأسئلة المعتمدة لكل مادة ودرس',
                  color: AppTheme.primaryGreen,
                  onTap: () => context.openTeacherQuestionBank(),
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'أفضل الطلاب',
                  actionLabel: 'عرض الكل',
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.classStudents),
                ),
                const SizedBox(height: 8),
                if (dashboard.topStudents.isEmpty)
                  const _EmptyAnalyticsCard(
                    icon: Icons.people_outline_rounded,
                    title: 'لا يوجد طلاب حالياً',
                    message: 'ستظهر قائمة الطلاب بعد ربطهم بحساب المعلم.',
                  )
                else
                  ...dashboard.topStudents.map(
                    (student) => _StudentTile(
                      student: student,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.teacherStudentDetail,
                        arguments: StudentDetailArgs(student.studentId),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const _SectionHeader(title: 'تحليلات تحتاج بيانات إضافية'),
                const SizedBox(height: 10),
                const _EmptyAnalyticsCard(
                  icon: Icons.psychology_alt_rounded,
                  title: 'المهارات الضعيفة غير متاحة بعد',
                  message:
                      'عندما يرسل الخادم تحليلات المهارات ستظهر هنا حسب الصف والمادة.',
                ),
                const SizedBox(height: 10),
                const _EmptyAnalyticsCard(
                  icon: Icons.assignment_late_rounded,
                  title: 'قائمة الطلاب المعرضين للتأخر غير متاحة',
                  message:
                      'يمكن عرضها لاحقاً من بيانات الحضور، المحاولات، ومستويات الإتقان.',
                ),
                const SizedBox(height: 10),
                const _EmptyAnalyticsCard(
                  icon: Icons.description_rounded,
                  title: 'تقارير الصف غير متاحة حالياً',
                  message:
                      'سيظهر ملخص التقارير هنا عند توفر endpoint مخصص للتقارير.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  final TeacherDashboard dashboard;

  const _TeacherHeader({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final department = dashboard.department?.trim();
    final assignedGrade = dashboard.assignedGrade;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppTheme.primaryGreen,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
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
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                        if (department != null && department.isNotEmpty)
                          department,
                        if (assignedGrade != null) 'الصف $assignedGrade',
                      ].isEmpty
                      ? 'لوحة متابعة الصف'
                      : [
                          if (department != null && department.isNotEmpty)
                            department,
                          if (assignedGrade != null) 'الصف $assignedGrade',
                        ].join(' • '),
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
        ],
      ),
    );
  }
}

class _ClassPulseCard extends StatelessWidget {
  final TeacherDashboard dashboard;

  const _ClassPulseCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final activeRatio = dashboard.totalStudents > 0
        ? (dashboard.activeThisWeek / dashboard.totalStudents).clamp(0.0, 1.0)
        : 0.0;
    final masteryRatio = (dashboard.averageMasteryAcrossClass / 100)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نبض الصف',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'النشاط الأسبوعي',
            value: '${(activeRatio * 100).round()}%',
            progress: activeRatio.toDouble(),
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 12),
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
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

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
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 9,
            backgroundColor: color.withValues(alpha: 0.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyAnalyticsCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textLight, size: 28),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.elevationLow,
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final ClassStudentSummary student;
  final VoidCallback onTap;

  const _StudentTile({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.elevationLow,
        border: Border.all(color: AppTheme.surfaceSubtle, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
          child: Text(
            student.fullName.isNotEmpty ? student.fullName[0] : '?',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        title: Text(
          student.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'النقاط: ${student.totalPoints}  •  الإتقان: ${student.averageMastery.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_back_ios_rounded,
          size: 18,
          color: AppTheme.textGray,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.elevationLow,
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.18),
                        color.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGray,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 18,
                  color: color.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusL),
    boxShadow: AppTheme.elevationLow,
    border: Border.all(color: AppTheme.surfaceSubtle, width: 1),
  );
}
