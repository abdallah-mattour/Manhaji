import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/question_bank.dart';
import '../../providers/question_bank_provider.dart';
import 'question_bank_questions_screen.dart';

/// Grid of subjects available to the current teacher/admin.
///
/// Teachers see only subjects at their assigned grade (backend-scoped).
/// Admins see all subjects; they can filter by grade via a chip row.
class QuestionBankSubjectsScreen extends StatefulWidget {
  final bool asAdmin;

  const QuestionBankSubjectsScreen({super.key, required this.asAdmin});

  @override
  State<QuestionBankSubjectsScreen> createState() =>
      _QuestionBankSubjectsScreenState();
}

class _QuestionBankSubjectsScreenState
    extends State<QuestionBankSubjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<QuestionBankProvider>();
    if (widget.asAdmin) {
      await provider.loadSubjectsForAdmin(grade: provider.adminGradeFilter);
    } else {
      await provider.loadSubjectsForTeacher();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'بنك الأسئلة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Consumer<QuestionBankProvider>(
          builder: (context, provider, _) {
            if (provider.loadingSubjects && provider.subjects.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && provider.subjects.isEmpty) {
              return _errorState(provider.error!);
            }
            return RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  if (widget.asAdmin)
                    SliverToBoxAdapter(child: _adminGradeFilterBar(provider)),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: provider.subjects.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _emptyState(),
                          )
                        : _subjectsGrid(provider.subjects),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _adminGradeFilterBar(QuestionBankProvider provider) {
    const grades = [1, 2, 3, 4, 5, 6];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'الصف:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _gradeChip(
                    label: 'الكل',
                    selected: provider.adminGradeFilter == null,
                    onSelected: () async {
                      await provider.loadSubjectsForAdmin();
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final g in grades) ...[
                    _gradeChip(
                      label: 'الصف $g',
                      selected: provider.adminGradeFilter == g,
                      onSelected: () async {
                        await provider.loadSubjectsForAdmin(grade: g);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          color: selected ? Colors.white : AppTheme.textDark,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      selected: selected,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _subjectsGrid(List<SubjectSummary> subjects) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final cols = width > 1100
            ? 4
            : width > 780
                ? 3
                : width > 500
                    ? 2
                    : 1;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: cols == 1 ? 2.6 : 1.35,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => _subjectCard(subjects[i]),
            childCount: subjects.length,
          ),
        );
      },
    );
  }

  Widget _subjectCard(SubjectSummary s) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSubject(s),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      color: _subjectColor(s.name).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _subjectIcon(s.name),
                      color: _subjectColor(s.name),
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'الصف ${s.gradeLevel}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                s.name,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  _metaIcon(Icons.menu_book_rounded, '${s.lessonCount} درس'),
                  const SizedBox(width: 12),
                  _metaIcon(Icons.quiz_rounded, '${s.questionCount} سؤال'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textGray),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }

  void _openSubject(SubjectSummary s) {
    final provider = context.read<QuestionBankProvider>();
    provider.resetForSubject(s.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionBankQuestionsScreen(
          subject: s,
          asAdmin: widget.asAdmin,
        ),
      ),
    );
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
    if (name.contains('دين') || name.contains('Religion')) {
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
    if (name.contains('دين') || name.contains('Religion')) {
      return AppTheme.primaryRed;
    }
    return AppTheme.textGray;
  }

  Widget _emptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_rounded, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Text(
          'لا توجد مواد حاليًا',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }

  Widget _errorState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppTheme.primaryRed),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation helpers so dashboards can push without knowing internals.
extension QuestionBankRoutes on BuildContext {
  void openTeacherQuestionBank() {
    Navigator.of(this).push(
      MaterialPageRoute(
        builder: (_) => const QuestionBankSubjectsScreen(asAdmin: false),
      ),
    );
  }

  void openAdminQuestionBank() {
    Navigator.of(this).push(
      MaterialPageRoute(
        builder: (_) => const QuestionBankSubjectsScreen(asAdmin: true),
      ),
    );
  }
}
