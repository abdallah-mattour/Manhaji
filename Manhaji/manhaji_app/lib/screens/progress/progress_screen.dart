import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/progress.dart';
import '../../app/routes.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/stat_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressProvider>().loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقدمي'),
          actions: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.aiReports),
              icon: const Icon(Icons.auto_awesome_rounded),
              tooltip: 'تقارير الذكاء الاصطناعي',
            ),
            IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.leaderboard),
              icon: const Icon(Icons.leaderboard_rounded),
              tooltip: 'لوحة المتصدرين',
            ),
          ],
        ),
        body: Consumer<ProgressProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.summary == null) {
              return const LoadingState();
            }
            if (provider.errorMessage != null && provider.summary == null) {
              return ErrorState(
                message: provider.errorMessage!,
                onRetry: provider.loadProgress,
              );
            }

            final summary = provider.summary;
            if (summary == null) return const SizedBox();

            return RefreshIndicator(
              onRefresh: () => provider.loadProgress(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOverallProgress(summary),
                    const SizedBox(height: AppTheme.spacingM),
                    _buildStatsGrid(summary),
                    const SizedBox(height: 20),
                    _buildSubjectBreakdown(summary.subjectProgress),
                    const SizedBox(height: 20),
                    _buildRecentActivity(summary.recentActivity),
                    const SizedBox(height: AppTheme.spacingL),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverallProgress(ProgressSummary summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF388E3C)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'التقدم الإجمالي',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          // Large circle progress
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: summary.completionPercent / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${summary.completionPercent.toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${summary.completedLessons}/${summary.totalLessons}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'أكملت ${summary.completedLessons} من ${summary.totalLessons} درس',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ProgressSummary summary) {
    return Row(
      children: [
        StatCard(
          emoji: '⭐',
          value: '${summary.totalPoints}',
          label: 'النقاط',
          color: AppTheme.primaryYellow,
          emojiSize: 20,
          valueFontSize: 16,
          labelFontSize: 10,
          borderRadius: 14,
        ),
        const SizedBox(width: 10),
        StatCard(
          emoji: '🔥',
          value: '${summary.currentStreak}',
          label: 'أيام متتالية',
          color: AppTheme.primaryOrange,
          emojiSize: 20,
          valueFontSize: 16,
          labelFontSize: 10,
          borderRadius: 14,
        ),
        const SizedBox(width: 10),
        StatCard(
          emoji: '📝',
          value: '${summary.totalQuizzesTaken}',
          label: 'اختبار',
          color: AppTheme.primaryBlue,
          emojiSize: 20,
          valueFontSize: 16,
          labelFontSize: 10,
          borderRadius: 14,
        ),
        const SizedBox(width: 10),
        StatCard(
          emoji: '🏆',
          value: '${summary.averageQuizScore.toInt()}%',
          label: 'معدل النجاح',
          color: AppTheme.primaryPurple,
          emojiSize: 20,
          valueFontSize: 16,
          labelFontSize: 10,
          borderRadius: 14,
        ),
      ],
    );
  }

  Widget _buildSubjectBreakdown(List<SubjectProgress> subjects) {
    final colors = AppTheme.subjectColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المواد الدراسية',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ...subjects.asMap().entries.map((entry) {
          final idx = entry.key;
          final subject = entry.value;
          final color = colors[idx % colors.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      subject.subjectName.isNotEmpty
                          ? subject.subjectName.substring(0, 1)
                          : '?',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.subjectName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: subject.progressPercent,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      '${subject.completedLessons}/${subject.totalLessons}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${subject.masteryPercent.toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentActivity(List<RecentActivity> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            'لا يوجد نشاط حديث بعد\nابدأ بدراسة الدروس! 📚',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: AppTheme.textGray,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'النشاط الأخير',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ...activities.map((activity) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: activity.isQuiz
                          ? AppTheme.primaryOrange.withValues(alpha: 0.12)
                          : AppTheme.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      activity.isQuiz
                          ? Icons.quiz_rounded
                          : Icons.auto_stories_rounded,
                      color: activity.isQuiz
                          ? AppTheme.primaryOrange
                          : AppTheme.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          activity.subjectName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activity.isQuiz && activity.score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: activity.score! >= 80
                            ? Colors.green.shade50
                            : activity.score! >= 50
                                ? Colors.orange.shade50
                                : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${activity.score!.toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: activity.score! >= 80
                              ? Colors.green
                              : activity.score! >= 50
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            )),
      ],
    );
  }
}
