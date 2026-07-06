import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/student_assigned_quiz.dart';
import '../models/student_assigned_quiz_alert.dart';

class StudentAssignedQuizAlertsSection extends StatelessWidget {
  final List<StudentAssignedQuizSummary> quizzes;
  final Future<void> Function(StudentAssignedQuizSummary quiz) onAction;
  final DateTime? now;

  const StudentAssignedQuizAlertsSection({
    super.key,
    required this.quizzes,
    required this.onAction,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final alerts = buildStudentAssignedQuizAlerts(quizzes, now: now);
    if (alerts.isEmpty) return const SizedBox.shrink();

    final visible = alerts.take(3).toList();
    final hiddenCount = alerts.length - visible.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space5,
        AppTheme.space4,
        AppTheme.space5,
        AppTheme.space1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تنبيهات الاختبارات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          for (final alert in visible) ...[
            _AssignedQuizAlertCard(alert: alert, onAction: onAction),
            const SizedBox(height: AppTheme.space2),
          ],
          if (hiddenCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.space1),
              child: Text(
                '+$hiddenCount تنبيهات أخرى',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textGray,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignedQuizAlertCard extends StatelessWidget {
  final StudentAssignedQuizAlert alert;
  final Future<void> Function(StudentAssignedQuizSummary quiz) onAction;

  const _AssignedQuizAlertCard({required this.alert, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(alert.type);
    return Container(
      key: ValueKey('assigned_quiz_alert_${alert.quiz.assignmentId}'),
      padding: const EdgeInsets.all(AppTheme.space3),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(_alertIcon(alert.type), color: color, size: 21),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Text(
                  alert.description,
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
          if (alert.canAct && alert.actionLabel != null) ...[
            const SizedBox(width: AppTheme.space2),
            TextButton(
              key: ValueKey(
                'assigned_quiz_alert_action_${alert.quiz.assignmentId}',
              ),
              onPressed: () => onAction(alert.quiz),
              child: Text(alert.actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _alertIcon(StudentAssignedQuizAlertType type) {
  return switch (type) {
    StudentAssignedQuizAlertType.expired => Icons.timer_off_rounded,
    StudentAssignedQuizAlertType.maxAttemptsUsed => Icons.block_rounded,
    StudentAssignedQuizAlertType.unavailable => Icons.lock_rounded,
    StudentAssignedQuizAlertType.endingSoon => Icons.hourglass_bottom_rounded,
    StudentAssignedQuizAlertType.available =>
      Icons.notifications_active_rounded,
  };
}

Color _alertColor(StudentAssignedQuizAlertType type) {
  return switch (type) {
    StudentAssignedQuizAlertType.expired => AppTheme.primaryRed,
    StudentAssignedQuizAlertType.maxAttemptsUsed => AppTheme.primaryOrange,
    StudentAssignedQuizAlertType.unavailable => AppTheme.textGray,
    StudentAssignedQuizAlertType.endingSoon => AppTheme.primaryYellowDeep,
    StudentAssignedQuizAlertType.available => AppTheme.primaryBlue,
  };
}
