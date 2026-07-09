import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/teacher_mistake_analytics.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/staff_web_shell.dart';
import 'teacher_shell_navigation.dart';

class TeacherMistakeAnalyticsScreen extends StatefulWidget {
  const TeacherMistakeAnalyticsScreen({super.key});

  @override
  State<TeacherMistakeAnalyticsScreen> createState() =>
      _TeacherMistakeAnalyticsScreenState();
}

class _TeacherMistakeAnalyticsScreenState
    extends State<TeacherMistakeAnalyticsScreen> {
  int? _subjectId;
  int? _lessonId;
  String _studentQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TeacherProvider>().loadMistakeAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: 'تحليل أخطاء الطلاب',
        subtitle: 'مبني على إجابات الطلاب ومحاولاتهم',
        roleLabel: 'مساحة المعلم',
        currentRoute: AppRoutes.teacherMistakes,
        items: teacherShellItems(context),
        child: Consumer<TeacherProvider>(
          builder: (context, provider, _) {
            if (provider.isMistakeAnalyticsLoading &&
                provider.mistakeAnalytics == null) {
              return const LoadingState();
            }
            if (provider.mistakeAnalyticsError != null &&
                provider.mistakeAnalytics == null) {
              return ErrorState(
                message: provider.mistakeAnalyticsError!,
                onRetry: provider.loadMistakeAnalytics,
              );
            }

            final analytics =
                provider.mistakeAnalytics ??
                const TeacherMistakeAnalytics(
                  summary: TeacherMistakeSummary(
                    totalMistakes: 0,
                    affectedStudents: 0,
                  ),
                  mistakes: [],
                );
            return RefreshIndicator(
              onRefresh: () => provider.loadMistakeAnalytics(),
              child: _MistakeAnalyticsContent(
                analytics: analytics,
                selectedSubjectId: _subjectId,
                selectedLessonId: _lessonId,
                studentQuery: _studentQuery,
                onSubjectChanged: (value) {
                  setState(() {
                    _subjectId = value;
                    _lessonId = null;
                  });
                },
                onLessonChanged: (value) => setState(() => _lessonId = value),
                onStudentQueryChanged: (value) =>
                    setState(() => _studentQuery = value),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MistakeAnalyticsContent extends StatelessWidget {
  const _MistakeAnalyticsContent({
    required this.analytics,
    required this.selectedSubjectId,
    required this.selectedLessonId,
    required this.studentQuery,
    required this.onSubjectChanged,
    required this.onLessonChanged,
    required this.onStudentQueryChanged,
  });

  final TeacherMistakeAnalytics analytics;
  final int? selectedSubjectId;
  final int? selectedLessonId;
  final String studentQuery;
  final ValueChanged<int?> onSubjectChanged;
  final ValueChanged<int?> onLessonChanged;
  final ValueChanged<String> onStudentQueryChanged;

  @override
  Widget build(BuildContext context) {
    final rows = _filteredRows();
    final subjectOptions = _subjectOptions(analytics.mistakes);
    final lessonOptions = _lessonOptions(analytics.mistakes, selectedSubjectId);

    return ListView(
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
                _SummaryCards(summary: analytics.summary),
                const SizedBox(height: AppTheme.space4),
                _FiltersPanel(
                  subjects: subjectOptions,
                  lessons: lessonOptions,
                  selectedSubjectId: selectedSubjectId,
                  selectedLessonId: selectedLessonId,
                  studentQuery: studentQuery,
                  onSubjectChanged: onSubjectChanged,
                  onLessonChanged: onLessonChanged,
                  onStudentQueryChanged: onStudentQueryChanged,
                ),
                const SizedBox(height: AppTheme.space5),
                if (rows.isEmpty)
                  const _EmptyMistakesPanel()
                else
                  _MistakeRowsPanel(rows: rows),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<TeacherMistakeRow> _filteredRows() {
    final query = studentQuery.trim().toLowerCase();
    return analytics.mistakes.where((row) {
      final subjectMatches =
          selectedSubjectId == null || row.subjectId == selectedSubjectId;
      final lessonMatches =
          selectedLessonId == null || row.lessonId == selectedLessonId;
      final queryMatches =
          query.isEmpty ||
          [
            row.studentName,
            row.questionText,
            row.subjectName,
            row.lessonTitle,
          ].join(' ').toLowerCase().contains(query);
      return subjectMatches && lessonMatches && queryMatches;
    }).toList();
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final TeacherMistakeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.space4,
      runSpacing: AppTheme.space4,
      children: [
        _SummaryCard(
          icon: Icons.error_outline_rounded,
          label: 'إجمالي الأخطاء',
          value: '${summary.totalMistakes}',
          color: AppTheme.primaryRed,
        ),
        _SummaryCard(
          icon: Icons.people_alt_rounded,
          label: 'الطلاب المتأثرون',
          value: '${summary.affectedStudents}',
          color: AppTheme.primaryBlue,
        ),
        _SummaryCard(
          icon: Icons.menu_book_rounded,
          label: 'أكثر درس يحتاج متابعة',
          value: _fallback(summary.mostMistakenLessonTitle),
          color: AppTheme.primaryTerracotta,
        ),
        _SummaryCard(
          icon: Icons.quiz_rounded,
          label: 'أكثر سؤال تكررت فيه الأخطاء',
          value: _fallback(summary.mostMistakenQuestionText),
          color: AppTheme.primaryOrange,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: _panelDecoration(),
        child: Row(
          children: [
            _IconBox(icon: icon, color: color),
            const SizedBox(width: AppTheme.space3),
            Expanded(
              child: Column(
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
                  const SizedBox(height: AppTheme.space1),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.subjects,
    required this.lessons,
    required this.selectedSubjectId,
    required this.selectedLessonId,
    required this.studentQuery,
    required this.onSubjectChanged,
    required this.onLessonChanged,
    required this.onStudentQueryChanged,
  });

  final List<_FilterOption> subjects;
  final List<_FilterOption> lessons;
  final int? selectedSubjectId;
  final int? selectedLessonId;
  final String studentQuery;
  final ValueChanged<int?> onSubjectChanged;
  final ValueChanged<int?> onLessonChanged;
  final ValueChanged<String> onStudentQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _panelDecoration(),
      child: Wrap(
        spacing: AppTheme.space4,
        runSpacing: AppTheme.space4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<int?>(
              initialValue: selectedSubjectId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'المادة'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('كل المواد'),
                ),
                for (final subject in subjects)
                  DropdownMenuItem<int?>(
                    value: subject.id,
                    child: Text(
                      subject.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onSubjectChanged,
            ),
          ),
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<int?>(
              initialValue: selectedLessonId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'الدرس'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('كل الدروس'),
                ),
                for (final lesson in lessons)
                  DropdownMenuItem<int?>(
                    value: lesson.id,
                    child: Text(
                      lesson.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onLessonChanged,
            ),
          ),
          SizedBox(
            width: 320,
            child: TextFormField(
              initialValue: studentQuery,
              decoration: const InputDecoration(
                labelText: 'بحث عن طالب أو سؤال',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: onStudentQueryChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeRowsPanel extends StatelessWidget {
  const _MistakeRowsPanel({required this.rows});

  final List<TeacherMistakeRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _MistakeRowCard(row: rows[i]),
            if (i != rows.length - 1)
              const Divider(
                height: AppTheme.space6,
                color: AppTheme.surfaceMuted,
              ),
          ],
        ],
      ),
    );
  }
}

class _MistakeRowCard extends StatelessWidget {
  const _MistakeRowCard({required this.row});

  final TeacherMistakeRow row;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppTheme.space3,
          runSpacing: AppTheme.space2,
          children: [
            _LabeledText(label: 'الطالب', value: _fallback(row.studentName)),
            _StatusPill(
              label: row.commonMistake ? 'خطأ شائع' : 'خطأ فردي',
              color: row.commonMistake
                  ? AppTheme.primaryOrange
                  : AppTheme.textGray,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space3),
        Wrap(
          spacing: AppTheme.space4,
          runSpacing: AppTheme.space3,
          children: [
            _LabeledText(label: 'المادة', value: _fallback(row.subjectName)),
            _LabeledText(label: 'الدرس', value: _fallback(row.lessonTitle)),
            _LabeledText(label: 'عدد مرات الخطأ', value: '${row.mistakeCount}'),
            _LabeledText(
              label: 'آخر محاولة',
              value: _formatDate(row.lastMistakeAt),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space4),
        _FullWidthField(label: 'السؤال', value: _fallback(row.questionText)),
        const SizedBox(height: AppTheme.space3),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;
            final studentAnswer = _FullWidthField(
              label: 'إجابة الطالب',
              value: _fallback(row.studentAnswer),
            );
            final correctAnswer = _FullWidthField(
              label: 'الإجابة الصحيحة',
              value: _fallback(row.correctAnswer),
            );
            if (!isWide) {
              return Column(
                children: [
                  studentAnswer,
                  const SizedBox(height: AppTheme.space3),
                  correctAnswer,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: studentAnswer),
                const SizedBox(width: AppTheme.space4),
                Expanded(child: correctAnswer),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullWidthField extends StatelessWidget {
  const _FullWidthField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: AppTheme.space1),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMistakesPanel extends StatelessWidget {
  const _EmptyMistakesPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: _panelDecoration(),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 56,
            color: AppTheme.primaryGreen,
          ),
          SizedBox(height: AppTheme.space4),
          Text(
            'لا توجد أخطاء مسجلة حاليًا',
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
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({required this.id, required this.label});

  final int id;
  final String label;
}

List<_FilterOption> _subjectOptions(List<TeacherMistakeRow> rows) {
  final byId = <int, String>{};
  for (final row in rows) {
    byId.putIfAbsent(row.subjectId, () => row.subjectName);
  }
  final options = byId.entries
      .map((entry) => _FilterOption(id: entry.key, label: entry.value))
      .toList();
  options.sort((a, b) => a.label.compareTo(b.label));
  return options;
}

List<_FilterOption> _lessonOptions(
  List<TeacherMistakeRow> rows,
  int? subjectId,
) {
  final byId = <int, String>{};
  for (final row in rows) {
    if (subjectId != null && row.subjectId != subjectId) continue;
    byId.putIfAbsent(row.lessonId, () => row.lessonTitle);
  }
  final options = byId.entries
      .map((entry) => _FilterOption(id: entry.key, label: entry.value))
      .toList();
  options.sort((a, b) => a.label.compareTo(b.label));
  return options;
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusM),
    border: Border.all(color: AppTheme.surfaceMuted),
    boxShadow: AppTheme.elevationLow,
  );
}

String _fallback(String? value) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? 'غير متوفر' : text;
}

String _formatDate(String? raw) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return 'غير متوفر';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')} '
      '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
}
