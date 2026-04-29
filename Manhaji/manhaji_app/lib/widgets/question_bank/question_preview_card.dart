import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/question_bank.dart';

/// Read-only preview of a bank question for the teacher/admin viewer.
///
/// Renders one card per question, with a type-specific body so the
/// teacher can see exactly how the item looks to the student: MCQ options,
/// TF badges, tracing target letter, pronunciation target word, etc.
class QuestionPreviewCard extends StatelessWidget {
  final QuestionBankItem question;
  final int index;

  const QuestionPreviewCard({
    super.key,
    required this.question,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            const SizedBox(height: 10),
            Text(
              question.questionText,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _body(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$index',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _typeBadge(),
        const SizedBox(width: 6),
        _difficultyBadge(),
        const Spacer(),
        if (question.lessonTitle != null)
          Flexible(
            child: Text(
              question.lessonTitle!,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppTheme.textGray,
              ),
            ),
          ),
      ],
    );
  }

  Widget _typeBadge() {
    final (label, color) = _typeMeta();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _difficultyBadge() {
    final d = question.difficultyLevel;
    final label = switch (d) {
      1 => 'سهل',
      2 => 'متوسط',
      _ => 'صعب',
    };
    final color = switch (d) {
      1 => AppTheme.primaryGreen,
      2 => AppTheme.primaryOrange,
      _ => AppTheme.primaryRed,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  (String, Color) _typeMeta() {
    if (question.isMcq) return ('اختيار', AppTheme.primaryBlue);
    if (question.isTrueFalse) return ('صح / خطأ', AppTheme.primaryBlue);
    if (question.isShortAnswer) return ('إجابة قصيرة', AppTheme.primaryBlue);
    if (question.isFillBlank) return ('إكمال', AppTheme.primaryBlue);
    if (question.isOrdering) return ('ترتيب', AppTheme.primaryBlue);
    if (question.isPronunciation) return ('نطق', AppTheme.primaryOrange);
    if (question.isTracing) return ('تتبّع', AppTheme.primaryOrange);
    return (question.type, AppTheme.textGray);
  }

  Widget _body() {
    if (question.isMcq) return _mcqBody();
    if (question.isTrueFalse) return _trueFalseBody();
    if (question.isOrdering) return _orderingBody();
    if (question.isFillBlank) return _fillBlankBody();
    if (question.isPronunciation) return _pronunciationBody();
    if (question.isTracing) return _tracingBody();
    // SHORT_ANSWER and fallback
    return _answerChip();
  }

  Widget _mcqBody() {
    final correct = question.correctAnswer.trim();
    if (question.options.isEmpty) {
      return _answerChip();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in question.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _optionRow(option, option.trim() == correct),
          ),
      ],
    );
  }

  Widget _optionRow(String text, bool isCorrect) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppTheme.primaryGreen.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect
              ? AppTheme.primaryGreen.withValues(alpha: 0.45)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isCorrect ? AppTheme.primaryGreen : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                color: isCorrect ? AppTheme.textDark : AppTheme.textGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trueFalseBody() {
    final correct = question.correctAnswer.trim();
    final isTrue = correct == 'صح' || correct.toLowerCase() == 'true';
    return Row(
      children: [
        _tfChip('صح', isTrue),
        const SizedBox(width: 10),
        _tfChip('خطأ', !isTrue),
      ],
    );
  }

  Widget _tfChip(String label, bool isCorrect) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isCorrect
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCorrect
                ? AppTheme.primaryGreen.withValues(alpha: 0.45)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCorrect)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryGreen,
                size: 18,
              ),
            if (isCorrect) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isCorrect ? AppTheme.primaryGreen : AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderingBody() {
    // Correct sequence is the correctAnswer delimited by "|" in curriculum
    // JSON; fall back to options order if absent.
    final parts = question.correctAnswer.contains('|')
        ? question.correctAnswer.split('|').map((s) => s.trim()).toList()
        : question.options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < parts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      parts[i],
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _fillBlankBody() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.edit_outlined,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'الإجابة المتوقّعة: ${question.correctAnswer}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pronunciationBody() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded, color: AppTheme.primaryOrange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الكلمة المطلوب نطقها',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.correctAnswer,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tracingBody() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, color: AppTheme.primaryBlue, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الحرف المطلوب تتبّعه',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                question.correctAnswer,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'الإجابة الصحيحة: ${question.correctAnswer}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
