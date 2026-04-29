import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/question_bank.dart';
import '../../providers/question_bank_provider.dart';
import '../../widgets/question_bank/question_preview_card.dart';

/// Questions within one subject, grouped by lesson.
/// Top bar holds difficulty chips + a lesson dropdown filter.
class QuestionBankQuestionsScreen extends StatefulWidget {
  final SubjectSummary subject;
  final bool asAdmin;

  const QuestionBankQuestionsScreen({
    super.key,
    required this.subject,
    required this.asAdmin,
  });

  @override
  State<QuestionBankQuestionsScreen> createState() =>
      _QuestionBankQuestionsScreenState();
}

class _QuestionBankQuestionsScreenState
    extends State<QuestionBankQuestionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<QuestionBankProvider>();
    if (widget.asAdmin) {
      await provider.loadQuestionsForAdmin(widget.subject.id);
    } else {
      await provider.loadQuestionsForTeacher(widget.subject.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.subject.name,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Consumer<QuestionBankProvider>(
          builder: (context, provider, _) {
            final response = provider.currentResponse;
            if (provider.loadingQuestions && response == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && response == null) {
              return _errorState(provider.error!);
            }
            if (response == null) {
              return const SizedBox();
            }
            return Column(
              children: [
                _filterBar(provider, response),
                Expanded(child: _questionsList(response)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterBar(
    QuestionBankProvider provider,
    QuestionBankResponse response,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${response.questions.length} / ${response.totalQuestionsInSubject} سؤال',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'الصف ${response.gradeLevel}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                    fontSize: 13,
                  ),
                ),
              ),
              if (provider.loadingQuestions) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Difficulty chips
          Row(
            children: [
              const Text(
                'الصعوبة:',
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
                      _difficultyChip(provider, null, 'الكل'),
                      const SizedBox(width: 8),
                      _difficultyChip(provider, 1, 'سهل'),
                      const SizedBox(width: 8),
                      _difficultyChip(provider, 2, 'متوسط'),
                      const SizedBox(width: 8),
                      _difficultyChip(provider, 3, 'صعب'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (response.lessons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'الدرس:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _lessonDropdown(provider, response)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _difficultyChip(
      QuestionBankProvider provider, int? value, String label) {
    final selected = provider.selectedDifficulty == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : AppTheme.textDark,
        ),
      ),
      selected: selected,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) => provider.setDifficulty(
        value,
        asAdmin: widget.asAdmin,
      ),
    );
  }

  Widget _lessonDropdown(
    QuestionBankProvider provider,
    QuestionBankResponse response,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
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
            for (final l in response.lessons)
              DropdownMenuItem<int?>(
                value: l.id,
                child: Text(
                  '${l.title} (${l.questionCount})',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) => provider.setLesson(v, asAdmin: widget.asAdmin),
        ),
      ),
    );
  }

  Widget _questionsList(QuestionBankResponse response) {
    if (response.questions.isEmpty) {
      return _emptyState();
    }
    // Group questions by lesson, preserving the lessons list order.
    final Map<int, List<QuestionBankItem>> grouped = {};
    for (final q in response.questions) {
      if (q.lessonId == null) continue;
      grouped.putIfAbsent(q.lessonId!, () => []).add(q);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: response.lessons.length,
      itemBuilder: (context, i) {
        final lesson = response.lessons[i];
        final items = grouped[lesson.id] ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _lessonHeader(lesson),
            const SizedBox(height: 10),
            for (var idx = 0; idx < items.length; idx++)
              QuestionPreviewCard(
                question: items[idx],
                index: idx + 1,
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _lessonHeader(LessonSummary lesson) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.9),
            AppTheme.primaryGreen.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lesson.title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${lesson.questionCount} سؤال',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'لا توجد أسئلة مطابقة للفلاتر الحالية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
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
