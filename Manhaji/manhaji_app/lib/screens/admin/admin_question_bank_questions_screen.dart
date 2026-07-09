import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/route_args.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/question_bank.dart';
import '../../providers/question_bank_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/question_preview_card.dart';
import '../../widgets/staff_web_shell.dart';
import 'admin_shell_navigation.dart';

/// Questions of a single subject for the admin — view-only (the backend
/// exposes no create/edit/delete question endpoints). Stays inside the
/// staff shell so the sidebar keeps its active «بنك الأسئلة» state.
class AdminQuestionBankQuestionsScreen extends StatefulWidget {
  const AdminQuestionBankQuestionsScreen({super.key});

  @override
  State<AdminQuestionBankQuestionsScreen> createState() =>
      _AdminQuestionBankQuestionsScreenState();
}

class _AdminQuestionBankQuestionsScreenState
    extends State<AdminQuestionBankQuestionsScreen> {
  bool _loaded = false;
  SubjectSummary? _subject;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AdminQuestionBankSubjectArgs) {
      _subject = args.subject;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _load();
      });
    }
  }

  Future<void> _load() async {
    final subject = _subject;
    if (subject == null) return;
    await context.read<QuestionBankProvider>().loadQuestionsForAdmin(
      subject.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subject = _subject;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: subject?.name ?? 'بنك الأسئلة',
        subtitle: 'عرض أسئلة المادة كما وصلت من الخادم',
        roleLabel: 'مساحة المشرف',
        currentRoute: AppRoutes.adminQuestionBank,
        items: adminShellItems(context),
        actions: [
          if (subject != null)
            IconButton(
              tooltip: 'تحديث البيانات',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
        child: subject == null
            ? ErrorState(
                message: 'لم يتم تحديد المادة بشكل صحيح',
                onRetry: () => Navigator.of(context).pop(),
                retryLabel: 'رجوع',
              )
            : Consumer<QuestionBankProvider>(
                builder: (context, provider, _) {
                  final response = provider.currentResponse;
                  if (provider.loadingQuestions && response == null) {
                    return const LoadingState();
                  }
                  if (provider.error != null && response == null) {
                    return ErrorState(
                      message: provider.error!,
                      onRetry: _load,
                    );
                  }
                  if (response == null) {
                    return const SizedBox.shrink();
                  }

                  return RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.space6),
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _BackBar(subjectName: subject.name),
                                const SizedBox(height: AppTheme.space4),
                                _FiltersPanel(
                                  provider: provider,
                                  response: response,
                                ),
                                const SizedBox(height: AppTheme.space5),
                                if (response.questions.isEmpty)
                                  const _EmptyQuestions()
                                else
                                  _QuestionsList(response: response),
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

class _BackBar extends StatelessWidget {
  const _BackBar({required this.subjectName});

  final String subjectName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          key: const ValueKey('admin-question-bank-back'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const Text(
            'عودة إلى المواد',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryGreen,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space3),
        Expanded(
          child: Text(
            subjectName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
        ),
      ],
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({required this.provider, required this.response});

  final QuestionBankProvider provider;
  final QuestionBankResponse response;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _badge(
                '${response.questions.length} / ${response.totalQuestionsInSubject} سؤال',
                AppTheme.primaryGreen,
              ),
              const SizedBox(width: AppTheme.space2),
              _badge('الصف ${response.gradeLevel}', AppTheme.primaryBlue),
              if (provider.loadingQuestions) ...[
                const SizedBox(width: AppTheme.space3),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          Row(
            children: [
              const Text(
                'الصعوبة:',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _difficultyChip(null, 'الكل'),
                      const SizedBox(width: AppTheme.space2),
                      _difficultyChip(1, 'سهل'),
                      const SizedBox(width: AppTheme.space2),
                      _difficultyChip(2, 'متوسط'),
                      const SizedBox(width: AppTheme.space2),
                      _difficultyChip(3, 'صعب'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (response.lessons.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space3),
            Row(
              children: [
                const Text(
                  'الدرس:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(child: _lessonDropdown()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
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
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  Widget _difficultyChip(int? value, String label) {
    final selected = provider.selectedDifficulty == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AppTheme.textDark,
        ),
      ),
      selected: selected,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: AppTheme.surfaceSubtle,
      onSelected: (_) => provider.setDifficulty(value, asAdmin: true),
    );
  }

  Widget _lessonDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: provider.selectedLessonId,
          hint: const Text(
            'كل الدروس',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'كل الدروس',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
            ),
            for (final lesson in response.lessons)
              DropdownMenuItem<int?>(
                value: lesson.id,
                child: Text(
                  '${lesson.title} (${lesson.questionCount})',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => provider.setLesson(value, asAdmin: true),
        ),
      ),
    );
  }
}

class _QuestionsList extends StatelessWidget {
  const _QuestionsList({required this.response});

  final QuestionBankResponse response;

  @override
  Widget build(BuildContext context) {
    // Group questions by lesson, preserving the lessons list order.
    final Map<int, List<QuestionBankItem>> grouped = {};
    for (final question in response.questions) {
      if (question.lessonId == null) continue;
      grouped.putIfAbsent(question.lessonId!, () => []).add(question);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final lesson in response.lessons)
          if ((grouped[lesson.id] ?? const []).isNotEmpty) ...[
            _LessonHeader(lesson: lesson),
            const SizedBox(height: AppTheme.space3),
            for (var i = 0; i < grouped[lesson.id]!.length; i++)
              QuestionPreviewCard(
                question: grouped[lesson.id]![i],
                index: i + 1,
              ),
            const SizedBox(height: AppTheme.space4),
          ],
      ],
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.lesson});

  final LessonSummary lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Text(
              lesson.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Text(
            '${lesson.questionCount} سؤال',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyQuestions extends StatelessWidget {
  const _EmptyQuestions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.filter_alt_off_rounded,
            size: 64,
            color: AppTheme.textLight,
          ),
          SizedBox(height: AppTheme.space3),
          Text(
            'لا توجد أسئلة مطابقة للفلاتر الحالية',
            textAlign: TextAlign.center,
            style: TextStyle(
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
