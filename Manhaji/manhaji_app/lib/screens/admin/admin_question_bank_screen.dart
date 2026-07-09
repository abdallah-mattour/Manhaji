import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/route_args.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/question_bank.dart';
import '../../providers/question_bank_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/staff_web_shell.dart';
import 'admin_shell_navigation.dart';

/// Admin question bank — all backend-provided subjects inside the staff
/// shell. Grade filter chips are derived from the loaded subjects (no
/// hardcoded grade list) and filtering happens client-side on real data.
class AdminQuestionBankScreen extends StatefulWidget {
  const AdminQuestionBankScreen({super.key});

  @override
  State<AdminQuestionBankScreen> createState() =>
      _AdminQuestionBankScreenState();
}

class _AdminQuestionBankScreenState extends State<AdminQuestionBankScreen> {
  int? _gradeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    // Load the full subject list once; grade filtering is client-side.
    await context.read<QuestionBankProvider>().loadSubjectsForAdmin();
  }

  void _openSubject(SubjectSummary subject) {
    context.read<QuestionBankProvider>().resetForSubject(subject.id);
    Navigator.of(context).pushNamed(
      AppRoutes.adminQuestionBankQuestions,
      arguments: AdminQuestionBankSubjectArgs(subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: 'بنك الأسئلة',
        subtitle: 'كل المواد والأسئلة المعتمدة كما وصلت من الخادم',
        roleLabel: 'مساحة المشرف',
        currentRoute: AppRoutes.adminQuestionBank,
        items: adminShellItems(context),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
        child: Consumer<QuestionBankProvider>(
          builder: (context, provider, _) {
            if (provider.loadingSubjects && provider.subjects.isEmpty) {
              return const LoadingState();
            }
            if (provider.error != null && provider.subjects.isEmpty) {
              return ErrorState(message: provider.error!, onRetry: _load);
            }

            final subjects = provider.subjects;
            final grades = subjects.map((s) => s.gradeLevel).toSet().toList()
              ..sort();
            final visible = _gradeFilter == null
                ? subjects
                : subjects
                      .where((s) => s.gradeLevel == _gradeFilter)
                      .toList(growable: false);

            return RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.space6),
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (subjects.isNotEmpty) ...[
                            _GradeFilterBar(
                              grades: grades,
                              selected: _gradeFilter,
                              subjectCount: visible.length,
                              onSelected: (grade) =>
                                  setState(() => _gradeFilter = grade),
                            ),
                            const SizedBox(height: AppTheme.space5),
                          ],
                          if (subjects.isEmpty)
                            const _EmptySubjects()
                          else if (visible.isEmpty)
                            const _EmptySubjects(
                              message: 'لا توجد مواد في هذا الصف حالياً',
                            )
                          else
                            _SubjectsGrid(
                              subjects: visible,
                              onOpen: _openSubject,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GradeFilterBar extends StatelessWidget {
  const _GradeFilterBar({
    required this.grades,
    required this.selected,
    required this.subjectCount,
    required this.onSelected,
  });

  final List<int> grades;
  final int? selected;
  final int subjectCount;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted),
        boxShadow: AppTheme.elevationLow,
      ),
      child: Row(
        children: [
          const Text(
            'الصف:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(label: 'الكل', value: null),
                  for (final grade in grades) ...[
                    const SizedBox(width: AppTheme.space2),
                    _chip(label: 'الصف $grade', value: grade),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space3,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              '$subjectCount مادة',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required int? value}) {
    final isSelected = selected == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: isSelected ? Colors.white : AppTheme.textDark,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: AppTheme.surfaceSubtle,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _SubjectsGrid extends StatelessWidget {
  const _SubjectsGrid({required this.subjects, required this.onOpen});

  final List<SubjectSummary> subjects;
  final ValueChanged<SubjectSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppTheme.space4;
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 780
            ? 3
            : width >= 500
            ? 2
            : 1;
        final itemWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final subject in subjects)
              SizedBox(
                width: itemWidth,
                child: _SubjectCard(
                  subject: subject,
                  onTap: () => onOpen(subject),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onTap});

  final SubjectSummary subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(subject.name);
    return Semantics(
      button: true,
      label: subject.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 148),
              padding: const EdgeInsets.all(AppTheme.space5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: color.withValues(alpha: 0.22)),
                boxShadow: AppTheme.elevationLow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Icon(
                          _subjectIcon(subject.name),
                          color: color,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space3,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                        child: Text(
                          'الصف ${subject.gradeLevel}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space4),
                  Text(
                    subject.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space3),
                  Row(
                    children: [
                      _meta(Icons.menu_book_rounded, '${subject.lessonCount} درس'),
                      const SizedBox(width: AppTheme.space4),
                      _meta(Icons.quiz_rounded, '${subject.questionCount} سؤال'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textGray),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects({this.message = 'لا توجد مواد حاليًا'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 64, color: AppTheme.textLight),
          const SizedBox(height: AppTheme.space3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
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
  if (name.contains('دين') || name.contains('إسلام') || name.contains('Islamic')) {
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
  if (name.contains('دين') || name.contains('إسلام') || name.contains('Islamic')) {
    return AppTheme.primaryRed;
  }
  return AppTheme.textGray;
}
