import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/route_args.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/teacher_dashboard.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/staff_web_shell.dart';
import 'teacher_shell_navigation.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  bool _loaded = false;
  bool _invalidArgs = false;
  int? _studentId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is StudentDetailArgs && args.studentId > 0) {
      _studentId = args.studentId;
      final provider = context.read<TeacherProvider>();
      Future.microtask(() {
        if (!mounted) return;
        provider.loadStudentDetail(args.studentId);
      });
    } else {
      _invalidArgs = true;
    }
    _loaded = true;
  }

  void _backToStudents() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(AppRoutes.classStudents);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: 'بيانات الطالب',
        subtitle: 'تفاصيل الأداء والتقدم من بيانات الخادم',
        roleLabel: 'مساحة المعلم',
        currentRoute: AppRoutes.classStudents,
        items: teacherShellItems(context),
        actions: [
          IconButton(
            tooltip: 'العودة إلى الطلاب',
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: _backToStudents,
          ),
        ],
        child: _invalidArgs
            ? ErrorState(
                message: 'لم يتم تحديد الطالب بشكل صحيح.',
                onRetry: _backToStudents,
                retryLabel: 'العودة إلى الطلاب',
              )
            : Consumer<TeacherProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.studentDetail == null) {
                    return const LoadingState();
                  }
                  if (provider.error != null &&
                      provider.studentDetail == null) {
                    return ErrorState(
                      message: provider.error!,
                      onRetry: () => context
                          .read<TeacherProvider>()
                          .loadStudentDetail(_studentId!),
                    );
                  }

                  final student = provider.studentDetail;
                  if (student == null) {
                    return ErrorState(
                      message: 'لا توجد بيانات متاحة لهذا الطالب حالياً.',
                      onRetry: () => context
                          .read<TeacherProvider>()
                          .loadStudentDetail(_studentId!),
                    );
                  }

                  return _StudentDetailContent(student: student);
                },
              ),
      ),
    );
  }
}

class _StudentDetailContent extends StatelessWidget {
  const _StudentDetailContent({required this.student});

  final StudentDetail student;

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
                _ProfilePanel(student: student),
                const SizedBox(height: AppTheme.space5),
                _LearningSummary(student: student),
                const SizedBox(height: AppTheme.space5),
                _SubjectBreakdownPanel(subjects: student.subjectBreakdown),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.student});

  final StudentDetail student;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          final avatar = CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
            child: Text(
              student.fullName.trim().isNotEmpty ? student.fullName[0] : '؟',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryBlue,
              ),
            ),
          );
          final identity = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName.trim().isEmpty ? 'طالب' : student.fullName,
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
                student.email?.trim().isNotEmpty == true
                    ? student.email!.trim()
                    : 'البريد غير متوفر',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: AppTheme.space1),
              Text(
                'آخر نشاط: ${_formatDateTime(student.lastLoginAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          );
          final stats = Wrap(
            spacing: AppTheme.space3,
            runSpacing: AppTheme.space3,
            children: [
              _SummaryPill(
                label: 'الصف',
                value: _gradeLabel(student.gradeLevel),
              ),
              _SummaryPill(label: 'النقاط', value: '${student.totalPoints}'),
              _SummaryPill(label: 'السلسلة', value: '${student.currentStreak}'),
            ],
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: AppTheme.space4),
                    Expanded(child: identity),
                  ],
                ),
                const SizedBox(height: AppTheme.space5),
                stats,
              ],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: AppTheme.space4),
              Expanded(child: identity),
              const SizedBox(width: AppTheme.space4),
              stats,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningSummary extends StatelessWidget {
  const _LearningSummary({required this.student});

  final StudentDetail student;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'الدروس المكتملة',
        value: '${student.lessonsCompleted}',
        icon: Icons.check_circle_outline_rounded,
        color: AppTheme.primaryGreen,
      ),
      _MetricData(
        label: 'قيد التقدم',
        value: '${student.lessonsInProgress}',
        icon: Icons.timelapse_rounded,
        color: AppTheme.primaryBlue,
      ),
      _MetricData(
        label: 'متوسط الإتقان',
        value: '${student.overallMastery.toStringAsFixed(0)}%',
        icon: Icons.insights_rounded,
        color: AppTheme.primaryOrange,
      ),
      _MetricData(
        label: 'محاولات الاختبار',
        value: '${student.totalAttempts}',
        icon: Icons.quiz_rounded,
        color: AppTheme.primaryPurple,
      ),
      _MetricData(
        label: 'متوسط الدرجات',
        value: '${student.averageScore.toStringAsFixed(0)}%',
        icon: Icons.stacked_line_chart_rounded,
        color: AppTheme.primaryTerracotta,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'ملخص التعلم',
            subtitle: 'مؤشرات الطالب المتاحة من الخادم',
          ),
          const SizedBox(height: AppTheme.space4),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1040
                  ? 5
                  : constraints.maxWidth >= 760
                  ? 3
                  : constraints.maxWidth >= 480
                  ? 2
                  : 1;
              const spacing = AppTheme.space4;
              final width =
                  (constraints.maxWidth - (columns - 1) * spacing) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: width,
                      child: _MetricCard(metric: metric),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(metric.icon, color: metric.color, size: 22),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    height: 1.2,
                  ),
                ),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _SubjectBreakdownPanel extends StatelessWidget {
  const _SubjectBreakdownPanel({required this.subjects});

  final List<SubjectMasterySummary> subjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'التقدم حسب المادة',
            subtitle: 'يعرض فقط المواد التي أرجعها الخادم لهذا الطالب',
          ),
          const SizedBox(height: AppTheme.space4),
          if (subjects.isEmpty)
            const _EmptyPanel(message: 'لا توجد بيانات مواد حتى الآن.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 920 ? 2 : 1;
                const spacing = AppTheme.space4;
                final width =
                    (constraints.maxWidth - (columns - 1) * spacing) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final subject in subjects)
                      SizedBox(
                        width: width,
                        child: _SubjectCard(subject: subject),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});

  final SubjectMasterySummary subject;

  @override
  Widget build(BuildContext context) {
    final lessonProgress = subject.totalLessons > 0
        ? (subject.lessonsCompleted / subject.totalLessons)
              .clamp(0.0, 1.0)
              .toDouble()
        : 0.0;
    final masteryProgress = (subject.averageMastery / 100)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Text(
                '${subject.averageMastery.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          _ProgressLine(
            label: 'الإتقان',
            value: masteryProgress,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: AppTheme.space3),
          _ProgressLine(
            label:
                '${subject.lessonsCompleted} / ${subject.totalLessons} درس مكتمل',
            value: lessonProgress,
            color: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppTheme.textGray,
          ),
        ),
        const SizedBox(height: AppTheme.space2),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 9,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: AppTheme.space1),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppTheme.textGray,
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusM),
    border: Border.all(color: AppTheme.surfaceMuted),
    boxShadow: AppTheme.elevationLow,
  );
}

String _gradeLabel(int gradeLevel) {
  const labels = {
    1: 'الصف الأول',
    2: 'الصف الثاني',
    3: 'الصف الثالث',
    4: 'الصف الرابع',
    5: 'الصف الخامس',
    6: 'الصف السادس',
    7: 'الصف السابع',
    8: 'الصف الثامن',
    9: 'الصف التاسع',
    10: 'الصف العاشر',
    11: 'الصف الحادي عشر',
    12: 'الصف الثاني عشر',
  };
  return labels[gradeLevel] ?? 'الصف $gradeLevel';
}

String _formatDateTime(String? value) {
  if (value == null || value.trim().isEmpty) return 'غير متوفر';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
}
