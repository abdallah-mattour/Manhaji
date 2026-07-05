import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/route_args.dart';
import '../../app/theme.dart';
import '../../models/parent_dashboard.dart';
import '../../models/teacher_dashboard.dart';
import '../../providers/parent_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/vibrant_background.dart';

class ChildProgressScreen extends StatefulWidget {
  const ChildProgressScreen({super.key});

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  bool _loaded = false;
  bool _invalidArgs = false;
  int? _studentId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ChildProgressArgs) {
        _studentId = args.studentId;
        // Defer the load past the current build — loadChildDetail notifies
        // listeners synchronously (same pattern as StudentDetailScreen).
        final provider = context.read<ParentProvider>();
        Future.microtask(() {
          if (!mounted) return;
          provider.loadChildDetail(args.studentId);
        });
      } else {
        _invalidArgs = true;
      }
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_invalidArgs) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('تفاصيل الطفل')),
          body: ErrorState(
            message: 'لم يتم تحديد الطفل بشكل صحيح',
            onRetry: () => Navigator.of(context).pop(),
            retryLabel: 'رجوع',
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الطفل'),
          leading: IconButton(
            tooltip: 'رجوع',
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: Consumer<ParentProvider>(
            builder: (context, provider, _) {
              if (provider.isChildDetailLoading &&
                  provider.childDetail == null) {
                return const LoadingState();
              }
              if (provider.childDetailError != null &&
                  provider.childDetail == null) {
                return ErrorState(
                  message: provider.childDetailError!,
                  onRetry: () => context.read<ParentProvider>().loadChildDetail(
                    _studentId!,
                  ),
                );
              }
              final student = provider.childDetail;
              if (student == null) return const SizedBox.shrink();

              return RefreshIndicator(
                onRefresh: () =>
                    context.read<ParentProvider>().loadChildDetail(_studentId!),
                child: _ChildDetailsContent(student: student),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChildDetailsContent extends StatelessWidget {
  final StudentDetail student;

  const _ChildDetailsContent({required this.student});

  @override
  Widget build(BuildContext context) {
    // Phase 6B: the page is grouped into 4 mobile sections. The previous
    // standalone "قائمة إنجاز الدروس" / "نقاط القوة" / "نقاط تحتاج مراجعة"
    // sections re-rendered the same subjectBreakdown data — their info now
    // lives inside each subject card (remaining lessons + strength/review
    // chips with the exact same thresholds: strength >= 75, review < 65).
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // ① ملخص الطفل
        const _SectionTitle(title: 'ملخص الطفل'),
        const SizedBox(height: 10),
        _ProfileSummaryCard(student: student),
        const SizedBox(height: 12),
        _OverallProgressCard(student: student),
        const SizedBox(height: 22),
        // ② المواد والتقدم
        const _SectionTitle(
          title: 'المواد والتقدم',
          subtitle: 'الإتقان والدروس المتبقية ونقاط القوة لكل مادة',
        ),
        const SizedBox(height: 10),
        if (student.subjectBreakdown.isEmpty)
          const _EmptyInfoCard(
            icon: Icons.bar_chart_rounded,
            title: 'لا توجد بيانات مواد حتى الآن',
            message: 'عند إكمال الدروس ستظهر نسب تقدم كل مادة هنا.',
          )
        else
          ...student.subjectBreakdown.map(
            (subject) => _SubjectProgressCard(subject: subject),
          ),
        const SizedBox(height: 22),
        // ③ النشاط
        const _SectionTitle(
          title: 'النشاط',
          subtitle: 'أداء الاختبارات الأخيرة',
        ),
        const SizedBox(height: 10),
        _QuizPerformanceSummary(student: student),
        const SizedBox(height: 22),
        // ④ الإرشاد
        const _SectionTitle(
          title: 'الإرشاد',
          subtitle: 'توصيات منزلية وتقارير مبنية على بيانات الخادم',
        ),
        const SizedBox(height: 10),
        _ParentRecommendations(recommendations: student.recommendations),
        const SizedBox(height: 12),
        _ReportsSection(reports: student.reports),
      ],
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  final StudentDetail student;

  const _ProfileSummaryCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                child: Text(
                  _initial(student.fullName),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName.trim().isEmpty
                          ? 'طفل بدون اسم'
                          : student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الصف ${student.gradeLevel}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textGray,
                      ),
                    ),
                    if (student.lastLoginAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'آخر نشاط: ${_formatDate(student.lastLoginAt)}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(
                label: _masteryStatus(student.overallMastery),
                color: _masteryColor(student.overallMastery),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  icon: Icons.star_rounded,
                  label: 'النقاط',
                  value: '${student.totalPoints}',
                  color: AppTheme.primaryYellowDeep,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallStat(
                  icon: Icons.local_fire_department_rounded,
                  label: 'السلسلة',
                  value: '${student.currentStreak}',
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallStat(
                  icon: Icons.school_rounded,
                  label: 'الإتقان',
                  value: '${student.overallMastery.toStringAsFixed(0)}%',
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  final StudentDetail student;

  const _OverallProgressCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final progress = _percentProgress(student.overallMastery);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'التقدم العام',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 11,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoLine(label: 'دروس مكتملة', value: '${student.lessonsCompleted}'),
          _InfoLine(
            label: 'دروس قيد التقدم',
            value: '${student.lessonsInProgress}',
          ),
          _InfoLine(
            label: 'محاولات الاختبار',
            value: '${student.totalAttempts}',
          ),
          _InfoLine(
            label: 'متوسط الاختبارات',
            value: '${student.averageScore.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }
}

class _SubjectProgressCard extends StatelessWidget {
  final SubjectMasterySummary subject;

  const _SubjectProgressCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final progress = _lessonProgress(
      subject.lessonsCompleted,
      subject.totalLessons,
      fallbackPercent: subject.averageMastery,
    );
    final color = _masteryColor(subject.averageMastery);
    final remaining = (subject.totalLessons - subject.lessonsCompleted).clamp(
      0,
      9999,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.subjectName.trim().isEmpty
                      ? 'مادة بدون اسم'
                      : subject.subjectName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              _StatusBadge(
                label: _masteryStatus(subject.averageMastery),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: color.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${subject.averageMastery.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Phase 6B: remaining-lessons state (previously the standalone
          // "قائمة إنجاز الدروس" section) and strength/review chips
          // (previously "نقاط القوة" / "نقاط تحتاج مراجعة") merged here.
          // Thresholds preserved exactly: strength >= 75, review < 65.
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${subject.lessonsCompleted} / ${subject.totalLessons} درس مكتمل',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray,
                ),
              ),
              _StatusBadge(
                label: remaining == 0 ? 'مكتمل' : 'متبقي $remaining',
                color: remaining == 0
                    ? AppTheme.primaryGreen
                    : AppTheme.primaryBlue,
              ),
              if (subject.averageMastery >= 75)
                const _StatusBadge(
                  label: 'نقطة قوة',
                  color: AppTheme.primaryGreen,
                )
              else if (subject.averageMastery < 65)
                const _StatusBadge(
                  label: 'تحتاج مراجعة',
                  color: AppTheme.primaryOrange,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizPerformanceSummary extends StatelessWidget {
  final StudentDetail student;

  const _QuizPerformanceSummary({required this.student});

  @override
  Widget build(BuildContext context) {
    if (student.totalAttempts == 0) {
      return const _EmptyInfoCard(
        icon: Icons.quiz_rounded,
        title: 'لا توجد اختبارات حديثة بعد',
        message: 'عندما يكمل الطفل اختباراً ستظهر النتيجة والتوصية هنا.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(label: 'عدد المحاولات', value: '${student.totalAttempts}'),
          _InfoLine(
            label: 'متوسط الأداء',
            value: '${student.averageScore.toStringAsFixed(1)}%',
          ),
          if (student.recentAttempts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'آخر الاختبارات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < student.recentAttempts.length; i++) ...[
              _AttemptRow(attempt: student.recentAttempts[i]),
              if (i != student.recentAttempts.length - 1)
                const Divider(height: 18),
            ],
          ],
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  final QuizAttemptSummary attempt;

  const _AttemptRow({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final score = attempt.score;
    final scoreColor = score == null
        ? AppTheme.textGray
        : score >= 80
        ? AppTheme.primaryGreen
        : score >= 60
        ? AppTheme.primaryBlue
        : AppTheme.primaryOrange;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.quiz_rounded, color: scoreColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attempt.quizTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              if (attempt.subjectName != null || attempt.lessonTitle != null)
                Text(
                  [
                    attempt.subjectName,
                    attempt.lessonTitle,
                  ].whereType<String>().join(' — '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StatusBadge(
          label: score != null ? '${score.toStringAsFixed(0)}%' : 'قيد التقدم',
          color: scoreColor,
        ),
      ],
    );
  }
}

class _ReportsSection extends StatelessWidget {
  final List<ParentReportSummary> reports;

  const _ReportsSection({required this.reports});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const _EmptyInfoCard(
        icon: Icons.description_rounded,
        title: 'لا توجد تقارير بعد',
        message:
            'ستظهر هنا التقارير الذكية عند توليدها. يمكن للطالب توليد تقرير من شاشة التقارير.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < reports.length; i++) ...[
            _ReportTile(report: reports[i]),
            if (i != reports.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final ParentReportSummary report;

  const _ReportTile({required this.report});

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(report.riskLevel);
    final riskLabel = _riskLabel(report.riskLevel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.description_rounded,
              color: AppTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _periodLabel(report.periodStart, report.periodEnd),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            if (riskLabel != null)
              _StatusBadge(label: riskLabel, color: riskColor),
          ],
        ),
        if (report.summary != null && report.summary!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            report.summary!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }

  String _periodLabel(String? start, String? end) {
    if (start == null && end == null) return 'تقرير دوري';
    return 'من $start إلى $end';
  }

  Color _riskColor(String? risk) {
    if (risk == 'HIGH') return AppTheme.primaryRed;
    if (risk == 'MEDIUM') return AppTheme.primaryOrange;
    return AppTheme.primaryGreen;
  }

  String? _riskLabel(String? risk) {
    if (risk == 'HIGH') return 'يحتاج متابعة';
    if (risk == 'MEDIUM') return 'متابعة متوسطة';
    if (risk == 'LOW') return 'وضع جيد';
    return null;
  }
}

class _ParentRecommendations extends StatelessWidget {
  final List<ParentRecommendation> recommendations;

  const _ParentRecommendations({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const _EmptyInfoCard(
        icon: Icons.home_work_rounded,
        title: 'لا توجد توصيات حالياً',
        message:
            'طفلك يسير بشكل جيد! ستظهر توصيات هنا عند الحاجة لمتابعة إضافية.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < recommendations.length; i++) ...[
            _RecommendationTile(recommendation: recommendations[i]),
            if (i != recommendations.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final ParentRecommendation recommendation;

  const _RecommendationTile({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final isHigh = recommendation.priority == 'HIGH';
    final color = isHigh ? AppTheme.primaryOrangeDeep : AppTheme.primaryGreen;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.home_work_rounded, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                recommendation.message,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SmallStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyInfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textLight, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                    height: 1.45,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusL),
    boxShadow: AppTheme.elevationLow,
    border: Border.all(color: AppTheme.surfaceSubtle, width: 1),
  );
}

String _initial(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '؟' : trimmed.substring(0, 1);
}

double _percentProgress(double percent) {
  return (percent / 100).clamp(0.0, 1.0).toDouble();
}

double _lessonProgress(
  int completed,
  int total, {
  required double fallbackPercent,
}) {
  if (total > 0) {
    return (completed / total).clamp(0.0, 1.0).toDouble();
  }
  return _percentProgress(fallbackPercent);
}

String _masteryStatus(double mastery) {
  if (mastery >= 80) return 'ممتاز';
  if (mastery >= 65) return 'جيد';
  if (mastery > 0) return 'يحتاج مراجعة';
  return 'بانتظار بيانات';
}

Color _masteryColor(double mastery) {
  if (mastery >= 80) return AppTheme.primaryGreen;
  if (mastery >= 65) return AppTheme.primaryBlue;
  if (mastery > 0) return AppTheme.primaryOrange;
  return AppTheme.textGray;
}

String _formatDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'غير متاح';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
}
