import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/student_assigned_quiz.dart';

class StudentAssignedQuizzesSection extends StatelessWidget {
  final List<StudentAssignedQuizSummary> quizzes;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Future<void> Function(StudentAssignedQuizSummary quiz) onStart;
  final DateTime? now;
  final bool compact;

  const StudentAssignedQuizzesSection({
    super.key,
    required this.quizzes,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onStart,
    this.now,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentTime = now ?? DateTime.now();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.space5,
        compact ? AppTheme.space3 : AppTheme.space5,
        AppTheme.space5,
        AppTheme.space3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 38 : 44,
                height: compact ? 38 : 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Text(
                  'اختبارات المعلم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: compact ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          if (isLoading && quizzes.isEmpty)
            const _AssignedQuizLoading()
          else if (errorMessage != null && quizzes.isEmpty)
            _AssignedQuizError(message: errorMessage!, onRetry: onRetry)
          else if (quizzes.isEmpty)
            const _AssignedQuizEmpty()
          else
            Column(
              children: [
                for (final quiz in quizzes) ...[
                  _AssignedQuizCard(
                    quiz: quiz,
                    now: currentTime,
                    onStart: onStart,
                    compact: compact,
                  ),
                  const SizedBox(height: AppTheme.space3),
                ],
                if (errorMessage != null)
                  _InlineError(message: errorMessage!, onRetry: onRetry),
              ],
            ),
        ],
      ),
    );
  }
}

class _AssignedQuizCard extends StatefulWidget {
  final StudentAssignedQuizSummary quiz;
  final DateTime now;
  final Future<void> Function(StudentAssignedQuizSummary quiz) onStart;
  final bool compact;

  const _AssignedQuizCard({
    required this.quiz,
    required this.now,
    required this.onStart,
    required this.compact,
  });

  @override
  State<_AssignedQuizCard> createState() => _AssignedQuizCardState();
}

class _AssignedQuizCardState extends State<_AssignedQuizCard> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final expired = quiz.isExpiredAt(widget.now);
    final startEnabled =
        quiz.canStart && !expired && !quiz.isClosed && !quiz.isCompleted;
    final status = _statusLabel(quiz, widget.now);
    final statusColor = _statusColor(quiz, widget.now);

    return Container(
      key: ValueKey('assigned_quiz_card_${quiz.assignmentId}'),
      padding: EdgeInsets.all(
        widget.compact ? AppTheme.space3 : AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(
          widget.compact ? AppTheme.radiusL : AppTheme.radiusXL,
        ),
        border: Border.all(color: AppTheme.surfaceMuted, width: 2),
        boxShadow: [
          BoxShadow(color: AppTheme.surfaceMuted, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: widget.compact ? 44 : 52,
                height: widget.compact ? 44 : 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTerracotta.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: AppTheme.primaryTerracotta,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title.isEmpty ? 'اختبار بدون عنوان' : quiz.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: widget.compact ? 15 : 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space1),
                    Text(
                      _fallback(quiz.subjectName),
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
              const SizedBox(width: AppTheme.space2),
              _StatusPill(label: status, color: statusColor),
            ],
          ),
          SizedBox(height: widget.compact ? AppTheme.space3 : AppTheme.space4),
          Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: [
              _InfoPill(
                icon: Icons.help_outline_rounded,
                label: '${quiz.questionCount} سؤال',
              ),
              if (!widget.compact)
                _InfoPill(
                  icon: Icons.schedule_rounded,
                  label: _deadlineLabel(quiz, widget.now),
                ),
              _InfoPill(
                icon: Icons.replay_rounded,
                label: _attemptsLabel(quiz),
              ),
            ],
          ),
          SizedBox(height: widget.compact ? AppTheme.space3 : AppTheme.space4),
          FilledButton.icon(
            key: ValueKey('assigned_quiz_start_${quiz.assignmentId}'),
            onPressed: startEnabled && !_isStarting ? _start : null,
            icon: _isStarting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(startEnabled ? 'ابدأ الاختبار' : 'غير متاح'),
            style: FilledButton.styleFrom(
              minimumSize: Size(double.infinity, widget.compact ? 44 : 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _start() async {
    setState(() => _isStarting = true);
    try {
      await widget.onStart(widget.quiz);
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.32)),
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space2,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.surfaceMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textGray),
          const SizedBox(width: AppTheme.space1),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedQuizLoading extends StatelessWidget {
  const _AssignedQuizLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppTheme.space3),
          Text(
            'جاري تحميل اختبارات المعلم...',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedQuizError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AssignedQuizError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _AssignedQuizEmpty extends StatelessWidget {
  const _AssignedQuizEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _cardDecoration(),
      child: const Text(
        'لا توجد اختبارات مخصصة حاليًا',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppTheme.textGray,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryRed,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('تحديث')),
      ],
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
    border: Border.all(color: AppTheme.surfaceMuted, width: 2),
  );
}

String _fallback(String? value) {
  if (value == null || value.trim().isEmpty) return 'غير متوفر';
  return value;
}

String _attemptsLabel(StudentAssignedQuizSummary quiz) {
  final max = quiz.maxAttempts;
  if (max == null) return 'المحاولات: ${quiz.attemptsUsed} / غير محدود';
  return 'المحاولات: ${quiz.attemptsUsed} / $max';
}

String _deadlineLabel(StudentAssignedQuizSummary quiz, DateTime now) {
  final due = quiz.dueAtDate;
  if (due == null) return 'بدون موعد نهائي';
  if (!due.isAfter(now)) return 'انتهى وقت التسليم';

  final remaining = due.difference(now);
  final hours = remaining.inHours;
  if (hours < 24) {
    if (hours <= 1) return 'ينتهي خلال ساعة';
    return 'ينتهي خلال $hours ساعة';
  }

  final days = (remaining.inHours / 24).ceil();
  if (days == 1) return 'ينتهي خلال يوم واحد';
  if (days == 2) return 'ينتهي خلال يومين';
  return 'ينتهي خلال $days أيام';
}

String _statusLabel(StudentAssignedQuizSummary quiz, DateTime now) {
  if (quiz.isClosed) return 'مغلق';
  if (quiz.isExpiredAt(now) || quiz.normalizedStatus == 'EXPIRED') {
    return 'انتهى الوقت';
  }
  if (quiz.isCompleted) return 'مكتمل';
  if (quiz.canStart) return 'متاح';
  return 'غير متاح';
}

Color _statusColor(StudentAssignedQuizSummary quiz, DateTime now) {
  if (quiz.isClosed || quiz.isCompleted) return AppTheme.textGray;
  if (quiz.isExpiredAt(now) || quiz.normalizedStatus == 'EXPIRED') {
    return AppTheme.primaryRed;
  }
  if (quiz.canStart) return AppTheme.primaryGreen;
  return AppTheme.primaryOrange;
}
