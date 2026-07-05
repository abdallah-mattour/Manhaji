import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/question_bank.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/staff_web_shell.dart';
import '../question_bank/question_bank_subjects_screen.dart';
import 'teacher_shell_navigation.dart';

class TeacherSubjectsScreen extends StatefulWidget {
  const TeacherSubjectsScreen({super.key});

  @override
  State<TeacherSubjectsScreen> createState() => _TeacherSubjectsScreenState();
}

class _TeacherSubjectsScreenState extends State<TeacherSubjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TeacherProvider>().loadAssignedSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: 'المواد المخصصة',
        subtitle: 'المواد والصفوف المرتبطة بحساب المعلم',
        roleLabel: 'مساحة المعلم',
        currentRoute: AppRoutes.teacherSubjects,
        items: teacherShellItems(context),
        actions: [
          IconButton(
            tooltip: 'فتح بنك الأسئلة',
            icon: const Icon(Icons.quiz_rounded),
            onPressed: () => context.openTeacherQuestionBank(),
          ),
        ],
        child: Consumer<TeacherProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.assignedSubjects == null) {
              return const LoadingState();
            }
            if (provider.error != null && provider.assignedSubjects == null) {
              return ErrorState(
                message: provider.error!,
                onRetry: provider.loadAssignedSubjects,
              );
            }

            final subjects = provider.assignedSubjects ?? const [];
            return RefreshIndicator(
              onRefresh: () => provider.loadAssignedSubjects(),
              child: _SubjectsContent(subjects: subjects),
            );
          },
        ),
      ),
    );
  }
}

class _SubjectsContent extends StatelessWidget {
  const _SubjectsContent({required this.subjects});

  final List<SubjectSummary> subjects;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByGrade(subjects);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space6),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OverviewPanel(subjectCount: subjects.length),
                const SizedBox(height: AppTheme.space5),
                if (subjects.isEmpty)
                  const _EmptySubjectsPanel()
                else
                  for (final entry in groups.entries) ...[
                    _GradeSubjectsSection(
                      gradeLevel: entry.key,
                      subjects: entry.value,
                    ),
                    const SizedBox(height: AppTheme.space4),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  SplayTreeMap<int, List<SubjectSummary>> _groupByGrade(
    List<SubjectSummary> subjects,
  ) {
    final groups = SplayTreeMap<int, List<SubjectSummary>>();
    for (final subject in subjects) {
      groups.putIfAbsent(subject.gradeLevel, () => []).add(subject);
    }
    for (final group in groups.values) {
      group.sort((a, b) => a.name.compareTo(b.name));
    }
    return groups;
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.subjectCount});

  final int subjectCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          _IconBox(
            icon: Icons.menu_book_rounded,
            color: AppTheme.primaryTerracotta,
          ),
          const SizedBox(width: AppTheme.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'موادك الحالية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Text(
                  subjectCount == 0
                      ? 'لا توجد مواد مخصصة حالياً'
                      : '$subjectCount مادة مخصصة لحسابك',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
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

class _GradeSubjectsSection extends StatelessWidget {
  const _GradeSubjectsSection({
    required this.gradeLevel,
    required this.subjects,
  });

  final int gradeLevel;
  final List<SubjectSummary> subjects;

  @override
  Widget build(BuildContext context) {
    final lessonCount = subjects.fold<int>(
      0,
      (sum, subject) => sum + subject.lessonCount,
    );
    final questionCount = subjects.fold<int>(
      0,
      (sum, subject) => sum + subject.questionCount,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space4,
            runSpacing: AppTheme.space2,
            children: [
              Text(
                _gradeLabel(gradeLevel),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                '${subjects.length} مادة • $lessonCount درس • $questionCount سؤال',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 940
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
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
                      child: _SubjectTile(subject: subject),
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

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject});

  final SubjectSummary subject;

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(subject.name);
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: Row(
        children: [
          _IconBox(icon: _subjectIcon(subject.name), color: color),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Text(
                  '${subject.lessonCount} درس • ${subject.questionCount} سؤال',
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

class _EmptySubjectsPanel extends StatelessWidget {
  const _EmptySubjectsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: _panelDecoration(),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: AppTheme.textLight),
          SizedBox(height: AppTheme.space4),
          Text(
            'لا توجد مواد مخصصة لهذا الحساب حالياً.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Icon(icon, color: color, size: 24),
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

IconData _subjectIcon(String name) {
  if (name.contains('عرب') || name.contains('Arabic')) {
    return Icons.menu_book_rounded;
  }
  if (name.contains('English') || name.contains('إنجل')) {
    return Icons.language_rounded;
  }
  if (name.contains('رياض') || name.contains('Math')) {
    return Icons.calculate_rounded;
  }
  if (name.contains('دين') ||
      name.contains('إسلام') ||
      name.contains('Religion')) {
    return Icons.auto_stories_rounded;
  }
  return Icons.school_rounded;
}

Color _subjectColor(String name) {
  if (name.contains('عرب') || name.contains('Arabic')) {
    return AppTheme.primaryGreen;
  }
  if (name.contains('English') || name.contains('إنجل')) {
    return AppTheme.primaryBlue;
  }
  if (name.contains('رياض') || name.contains('Math')) {
    return AppTheme.primaryOrange;
  }
  if (name.contains('دين') ||
      name.contains('إسلام') ||
      name.contains('Religion')) {
    return AppTheme.primaryPurple;
  }
  return AppTheme.primaryTerracotta;
}
