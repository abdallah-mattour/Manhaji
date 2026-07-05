import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../widgets/vibrant_background.dart';
import 'preview_banner.dart';
import 'preview_config.dart';

/// Teacher preview only.
/// Local Arabic sample data, no providers, no API calls, no auth, no persistence.
class PreviewTeacherScreen extends StatelessWidget {
  const PreviewTeacherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المعلم'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          bottom: kScreenshotMode
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(28),
                  child: PreviewBanner(),
                )
              : null,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 24 : 16,
                      18,
                      isWide ? 24 : 16,
                      34,
                    ),
                    children: [
                      const _TeacherHeader(),
                      const SizedBox(height: 18),
                      const _KpiGrid(),
                      const SizedBox(height: 22),
                      _ResponsivePair(
                        isWide: isWide,
                        leftFlex: 7,
                        rightFlex: 5,
                        left: const _ClassPerformanceOverview(),
                        right: const _MasteryDistributionSection(),
                      ),
                      const SizedBox(height: 22),
                      _ResponsivePair(
                        isWide: isWide,
                        leftFlex: 7,
                        rightFlex: 5,
                        left: const _SubjectAnalysisSection(),
                        right: const _WeakSkillsSection(),
                      ),
                      const SizedBox(height: 22),
                      _Section(
                        title: 'طلاب يحتاجون متابعة',
                        icon: Icons.priority_high_rounded,
                        child: _StudentCardGrid(
                          students: _atRiskStudents,
                          variant: _StudentCardVariant.risk,
                          onOpen: (student) => _openStudent(context, student),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _Section(
                        title: 'أفضل الطلاب',
                        icon: Icons.workspace_premium_rounded,
                        child: _StudentCardGrid(
                          students: _topStudents,
                          variant: _StudentCardVariant.top,
                          onOpen: (student) => _openStudent(context, student),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _RecentQuizResultsSection(),
                      const SizedBox(height: 22),
                      _StudentTableSection(
                        onOpen: (student) => _openStudent(context, student),
                      ),
                      const SizedBox(height: 22),
                      const _ShortcutSection(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static void _openStudent(BuildContext context, _StudentAnalytics student) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StudentAnalyticsPreviewScreen(student: student),
        settings: const RouteSettings(name: '/preview/teacher/student'),
      ),
    );
  }
}

class _StudentAnalyticsPreviewScreen extends StatelessWidget {
  final _StudentAnalytics student;

  const _StudentAnalyticsPreviewScreen({required this.student});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تحليل أداء الطالب'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          leading: IconButton(
            tooltip: 'رجوع',
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          bottom: kScreenshotMode
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(28),
                  child: PreviewBanner(),
                )
              : null,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 24 : 16,
                      18,
                      isWide ? 24 : 16,
                      34,
                    ),
                    children: [
                      _StudentProfileHeader(student: student),
                      const SizedBox(height: 18),
                      _StudentSummaryGrid(student: student),
                      const SizedBox(height: 22),
                      _ResponsivePair(
                        isWide: isWide,
                        leftFlex: 7,
                        rightFlex: 5,
                        left: _StudentSubjectProgressSection(student: student),
                        right: _StudentQuizPerformanceSection(student: student),
                      ),
                      const SizedBox(height: 22),
                      _ResponsivePair(
                        isWide: isWide,
                        leftFlex: 1,
                        rightFlex: 1,
                        left: _StudentStrengthsSection(student: student),
                        right: _StudentWeaknessesSection(student: student),
                      ),
                      const SizedBox(height: 22),
                      _ResponsivePair(
                        isWide: isWide,
                        leftFlex: 1,
                        rightFlex: 1,
                        left: _StudentRecommendationsSection(student: student),
                        right: _InterventionPlanSection(student: student),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(
        borderColor: AppTheme.primaryGreen.withValues(alpha: 0.16),
        shadow: AppTheme.elevationMedium,
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Color(0x1F58CC02),
            child: Icon(
              Icons.school_rounded,
              color: AppTheme.primaryGreen,
              size: 34,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لوحة المعلم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'مرحباً، أحمد محمد السالم',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'تابع أداء الصف والطلاب من لوحة تحليلية واحدة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(label: 'الصف الأول - أ', color: AppTheme.primaryBlue),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1080
            ? 6
            : width >= 760
            ? 3
            : width >= 520
            ? 2
            : 1;
        return _ResponsiveGrid(
          columns: columns,
          spacing: 12,
          runSpacing: 12,
          children: [for (final item in _kpis) _KpiCard(data: item)],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        borderColor: data.color.withValues(alpha: 0.16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(data.icon, color: data.color, size: 23),
              ),
              const Spacer(),
              _StatusBadge(label: data.trend, color: data.color),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassPerformanceOverview extends StatelessWidget {
  const _ClassPerformanceOverview();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'نظرة عامة على أداء الصف',
      icon: Icons.analytics_rounded,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            for (var i = 0; i < _classProgress.length; i++) ...[
              _ProgressMetricTile(metric: _classProgress[i]),
              if (i != _classProgress.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressMetricTile extends StatelessWidget {
  final _ProgressMetric metric;

  const _ProgressMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final progress = metric.progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(metric.icon, color: metric.color, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    metric.note,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: metric.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: progress,
            backgroundColor: metric.color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(metric.color),
          ),
        ),
      ],
    );
  }
}

class _MasteryDistributionSection extends StatelessWidget {
  const _MasteryDistributionSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'توزيع مستويات الإتقان',
      icon: Icons.stacked_bar_chart_rounded,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            for (var i = 0; i < _masteryBands.length; i++) ...[
              _MasteryBandTile(band: _masteryBands[i]),
              if (i != _masteryBands.length - 1) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _MasteryBandTile extends StatelessWidget {
  final _MasteryBand band;

  const _MasteryBandTile({required this.band});

  @override
  Widget build(BuildContext context) {
    final progress = (band.count / 24).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                band.label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            _StatusBadge(label: '${band.count} طلاب', color: band.color),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress,
            backgroundColor: band.color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(band.color),
          ),
        ),
      ],
    );
  }
}

class _SubjectAnalysisSection extends StatelessWidget {
  const _SubjectAnalysisSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'تحليل المواد',
      icon: Icons.menu_book_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 680 ? 2 : 1;
          return _ResponsiveGrid(
            columns: columns,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final subject in _subjects)
                _SubjectAnalysisCard(subject: subject),
            ],
          );
        },
      ),
    );
  }
}

class _SubjectAnalysisCard extends StatelessWidget {
  final _SubjectAnalysis subject;

  const _SubjectAnalysisCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final progress = (subject.mastery / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        borderColor: subject.color.withValues(alpha: 0.16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              _StatusBadge(label: subject.status, color: subject.color),
            ],
          ),
          const SizedBox(height: 10),
          _ProgressLine(
            label: '${subject.mastery}%',
            value: '${subject.completedLessons} درس مكتمل',
            progress: progress,
            color: subject.color,
          ),
          const SizedBox(height: 12),
          _DetailLine(
            icon: Icons.warning_amber_rounded,
            color: AppTheme.primaryOrange,
            text: subject.weakSkill,
          ),
          const SizedBox(height: 8),
          _DetailLine(
            icon: Icons.tips_and_updates_rounded,
            color: AppTheme.primaryGreen,
            text: subject.recommendation,
          ),
        ],
      ),
    );
  }
}

class _WeakSkillsSection extends StatelessWidget {
  const _WeakSkillsSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'المهارات التي تحتاج مراجعة',
      icon: Icons.psychology_alt_rounded,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            for (var i = 0; i < _weakSkills.length; i++) ...[
              _WeakSkillTile(skill: _weakSkills[i]),
              if (i != _weakSkills.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeakSkillTile extends StatelessWidget {
  final _WeakSkill skill;

  const _WeakSkillTile({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: skill.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.flag_rounded, color: skill.color, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      skill.title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  _StatusBadge(label: skill.severity, color: skill.color),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${skill.affectedStudents} طلاب - ${skill.action}',
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

enum _StudentCardVariant { risk, top }

class _StudentCardGrid extends StatelessWidget {
  final List<_StudentAnalytics> students;
  final _StudentCardVariant variant;
  final ValueChanged<_StudentAnalytics> onOpen;

  const _StudentCardGrid({
    required this.students,
    required this.variant,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 4
            : constraints.maxWidth >= 760
            ? 2
            : 1;
        return _ResponsiveGrid(
          columns: columns,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final student in students)
              _StudentSummaryCard(
                student: student,
                variant: variant,
                onOpen: () => onOpen(student),
              ),
          ],
        );
      },
    );
  }
}

class _StudentSummaryCard extends StatelessWidget {
  final _StudentAnalytics student;
  final _StudentCardVariant variant;
  final VoidCallback onOpen;

  const _StudentSummaryCard({
    required this.student,
    required this.variant,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final accent = variant == _StudentCardVariant.risk
        ? AppTheme.primaryOrange
        : student.color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(borderColor: accent.withValues(alpha: 0.16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accent.withValues(alpha: 0.12),
                child: Text(
                  student.initial,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      student.status,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MiniMetricsRow(
            items: [
              _MiniMetric('الإتقان', '${student.mastery}%'),
              _MiniMetric('الاختبارات', '${student.quizAverage}%'),
              _MiniMetric('دروس فائتة', '${student.missedLessons}'),
            ],
          ),
          const SizedBox(height: 12),
          _DetailLine(
            icon: Icons.psychology_alt_rounded,
            color: AppTheme.primaryOrange,
            text: student.weakSkill,
          ),
          const SizedBox(height: 7),
          _DetailLine(
            icon: Icons.tips_and_updates_rounded,
            color: AppTheme.primaryGreen,
            text: student.recommendation,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.insights_rounded, size: 18),
              label: const Text('عرض التحليل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentQuizResultsSection extends StatelessWidget {
  const _RecentQuizResultsSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'آخر نتائج الاختبارات',
      icon: Icons.quiz_rounded,
      child: _TableCard(
        minWidth: 850,
        columns: const [
          DataColumn(label: Text('اسم الاختبار')),
          DataColumn(label: Text('المادة')),
          DataColumn(label: Text('متوسط الصف')),
          DataColumn(label: Text('عدد المشاركين')),
          DataColumn(label: Text('التاريخ')),
          DataColumn(label: Text('الحالة')),
        ],
        rows: [
          for (final quiz in _recentQuizzes)
            DataRow(
              cells: [
                DataCell(Text(quiz.title)),
                DataCell(Text(quiz.subject)),
                DataCell(Text('${quiz.classAverage}%')),
                DataCell(Text('${quiz.participants} طالب')),
                DataCell(Text(quiz.date)),
                DataCell(_StatusBadge(label: quiz.status, color: quiz.color)),
              ],
            ),
        ],
      ),
    );
  }
}

class _StudentTableSection extends StatelessWidget {
  final ValueChanged<_StudentAnalytics> onOpen;

  const _StudentTableSection({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'قائمة الطلاب',
      icon: Icons.format_list_bulleted_rounded,
      child: _TableCard(
        minWidth: 980,
        columns: const [
          DataColumn(label: Text('الطالب')),
          DataColumn(label: Text('الإتقان')),
          DataColumn(label: Text('متوسط الاختبارات')),
          DataColumn(label: Text('الدروس المكتملة')),
          DataColumn(label: Text('آخر نشاط')),
          DataColumn(label: Text('الحالة')),
          DataColumn(label: Text('إجراء')),
        ],
        rows: [
          for (final student in _allStudents)
            DataRow(
              cells: [
                DataCell(_TableStudentName(student: student)),
                DataCell(Text('${student.mastery}%')),
                DataCell(Text('${student.quizAverage}%')),
                DataCell(Text('${student.completedLessons}/18')),
                DataCell(Text(student.lastActivity)),
                DataCell(
                  _StatusBadge(label: student.status, color: student.color),
                ),
                DataCell(
                  TextButton.icon(
                    onPressed: () => onOpen(student),
                    icon: const Icon(Icons.insights_rounded, size: 17),
                    label: const Text('عرض التحليل'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ShortcutSection extends StatelessWidget {
  const _ShortcutSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'إجراءات سريعة',
      icon: Icons.dashboard_customize_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 980
              ? 4
              : constraints.maxWidth >= 620
              ? 2
              : 1;
          return _ResponsiveGrid(
            columns: columns,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in _shortcuts) _ShortcutCard(data: item),
            ],
          );
        },
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final _ShortcutData data;

  const _ShortcutCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        borderColor: data.color.withValues(alpha: 0.15),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                    height: 1.35,
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

class _StudentProfileHeader extends StatelessWidget {
  final _StudentAnalytics student;

  const _StudentProfileHeader({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(
        borderColor: student.color.withValues(alpha: 0.16),
        shadow: AppTheme.elevationMedium,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: student.color.withValues(alpha: 0.12),
            child: Text(
              student.initial,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: student.color,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${student.grade} - آخر نشاط: ${student.lastActivity}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(label: student.status, color: student.color),
        ],
      ),
    );
  }
}

class _StudentSummaryGrid extends StatelessWidget {
  final _StudentAnalytics student;

  const _StudentSummaryGrid({required this.student});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _KpiData(
        icon: Icons.task_alt_rounded,
        label: 'الدروس المكتملة',
        value: '${student.completedLessons}',
        trend: 'من 18 درس',
        color: AppTheme.primaryGreen,
      ),
      _KpiData(
        icon: Icons.quiz_rounded,
        label: 'الاختبارات المنجزة',
        value: '${student.quizCount}',
        trend: '${student.quizAverage}%',
        color: AppTheme.primaryBlue,
      ),
      _KpiData(
        icon: Icons.workspace_premium_rounded,
        label: 'المهارات المتقنة',
        value: '${student.masteredSkills}',
        trend: 'جيد',
        color: AppTheme.primaryPurple,
      ),
      _KpiData(
        icon: Icons.psychology_alt_rounded,
        label: 'المهارات الضعيفة',
        value: '${student.weakSkillsCount}',
        trend: 'متابعة',
        color: AppTheme.primaryOrange,
      ),
      _KpiData(
        icon: Icons.bolt_rounded,
        label: 'نسبة النشاط الأسبوعي',
        value: '${student.weeklyActivity}%',
        trend: 'نشاط أسبوعي',
        color: student.color,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 5
            : constraints.maxWidth >= 700
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 1;
        return _ResponsiveGrid(
          columns: columns,
          spacing: 12,
          runSpacing: 12,
          children: [for (final metric in metrics) _KpiCard(data: metric)],
        );
      },
    );
  }
}

class _StudentSubjectProgressSection extends StatelessWidget {
  final _StudentAnalytics student;

  const _StudentSubjectProgressSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'التقدم حسب المادة',
      icon: Icons.auto_stories_rounded,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            for (var i = 0; i < student.subjects.length; i++) ...[
              _StudentSubjectTile(subject: student.subjects[i]),
              if (i != student.subjects.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentSubjectTile extends StatelessWidget {
  final _StudentSubject subject;

  const _StudentSubjectTile({required this.subject});

  @override
  Widget build(BuildContext context) {
    final progress = (subject.progress / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                subject.name,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            _StatusBadge(label: subject.status, color: subject.color),
          ],
        ),
        const SizedBox(height: 8),
        _ProgressLine(
          label: '${subject.progress}%',
          value:
              '${subject.completedLessons} درس - اختبار ${subject.quizAverage}%',
          progress: progress,
          color: subject.color,
        ),
        const SizedBox(height: 8),
        _DetailLine(
          icon: Icons.warning_amber_rounded,
          color: AppTheme.primaryOrange,
          text: subject.weakSkill,
        ),
      ],
    );
  }
}

class _StudentQuizPerformanceSection extends StatelessWidget {
  final _StudentAnalytics student;

  const _StudentQuizPerformanceSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'أداء الاختبارات الأخيرة',
      icon: Icons.fact_check_rounded,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            for (var i = 0; i < student.quizzes.length; i++) ...[
              _StudentQuizTile(quiz: student.quizzes[i]),
              if (i != student.quizzes.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudentQuizTile extends StatelessWidget {
  final _StudentQuiz quiz;

  const _StudentQuizTile({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: quiz.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.quiz_rounded, color: quiz.color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                '${quiz.subject} - ${quiz.date}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
        _StatusBadge(label: '${quiz.score}% ${quiz.status}', color: quiz.color),
      ],
    );
  }
}

class _StudentStrengthsSection extends StatelessWidget {
  final _StudentAnalytics student;

  const _StudentStrengthsSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return _SimpleListSection(
      title: 'نقاط القوة',
      icon: Icons.workspace_premium_rounded,
      color: AppTheme.primaryGreen,
      items: student.strengths,
    );
  }
}

class _StudentWeaknessesSection extends StatelessWidget {
  final _StudentAnalytics student;

  const _StudentWeaknessesSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return _SimpleListSection(
      title: 'نقاط تحتاج مراجعة',
      icon: Icons.flag_rounded,
      color: AppTheme.primaryOrange,
      items: student.weaknesses,
    );
  }
}

class _StudentRecommendationsSection extends StatelessWidget {
  final _StudentAnalytics student;

  const _StudentRecommendationsSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return _SimpleListSection(
      title: 'توصيات المعلم',
      icon: Icons.tips_and_updates_rounded,
      color: AppTheme.primaryBlue,
      items: student.teacherRecommendations,
    );
  }
}

class _InterventionPlanSection extends StatelessWidget {
  final _StudentAnalytics student;

  const _InterventionPlanSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return _SimpleListSection(
      title: 'خطة متابعة مقترحة',
      icon: Icons.route_rounded,
      color: AppTheme.primaryPurple,
      items: student.interventionPlan,
      numbered: true,
    );
  }
}

class _SimpleListSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final bool numbered;

  const _SimpleListSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    this.numbered = false,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      icon: icon,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(borderColor: color.withValues(alpha: 0.14)),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _InfoLine(
                icon: numbered ? Icons.looks_one_rounded : icon,
                number: numbered ? '${i + 1}' : null,
                color: color,
                text: items[i],
              ),
              if (i != items.length - 1) const Divider(height: 22),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String? number;
  final Color color;
  final String text;

  const _InfoLine({
    required this.icon,
    required this.color,
    required this.text,
    this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: number == null
              ? Icon(icon, color: color, size: 18)
              : Text(
                  number!,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  final bool isWide;
  final int leftFlex;
  final int rightFlex;
  final Widget left;
  final Widget right;

  const _ResponsivePair({
    required this.isWide,
    required this.leftFlex,
    required this.rightFlex,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(children: [left, const SizedBox(height: 22), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        const SizedBox(width: 16),
        Expanded(flex: rightFlex, child: right),
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final int columns;
  final double spacing;
  final double runSpacing;
  final List<Widget> children;

  const _ResponsiveGrid({
    required this.columns,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usableWidth = constraints.maxWidth - (spacing * (columns - 1));
        final itemWidth = usableWidth / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 21),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;

  const _ProgressLine({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: clamped,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _DetailLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGray,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMetricsRow extends StatelessWidget {
  final List<_MiniMetric> items;

  const _MiniMetricsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _MiniMetricBox(item: items[i])),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _MiniMetricBox extends StatelessWidget {
  final _MiniMetric item;

  const _MiniMetricBox({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final double minWidth;
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const _TableCard({
    required this.minWidth,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              AppTheme.primaryGreen.withValues(alpha: 0.08),
            ),
            headingTextStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
            dataTextStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
            dividerThickness: 0.6,
            columnSpacing: 28,
            horizontalMargin: 14,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }
}

class _TableStudentName extends StatelessWidget {
  final _StudentAnalytics student;

  const _TableStudentName({required this.student});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: student.color.withValues(alpha: 0.12),
          child: Text(
            student.initial,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: student.color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(student.name),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({Color? borderColor, List<BoxShadow>? shadow}) {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusL),
    border: Border.all(color: borderColor ?? AppTheme.surfaceSubtle, width: 1),
    boxShadow: shadow ?? AppTheme.elevationLow,
  );
}

class _KpiData {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final Color color;

  const _KpiData({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
  });
}

class _ProgressMetric {
  final IconData icon;
  final String label;
  final String note;
  final double progress;
  final Color color;

  const _ProgressMetric({
    required this.icon,
    required this.label,
    required this.note,
    required this.progress,
    required this.color,
  });
}

class _MasteryBand {
  final String label;
  final int count;
  final Color color;

  const _MasteryBand(this.label, this.count, this.color);
}

class _SubjectAnalysis {
  final String name;
  final int mastery;
  final String status;
  final int completedLessons;
  final String weakSkill;
  final String recommendation;
  final Color color;

  const _SubjectAnalysis({
    required this.name,
    required this.mastery,
    required this.status,
    required this.completedLessons,
    required this.weakSkill,
    required this.recommendation,
    required this.color,
  });
}

class _WeakSkill {
  final String title;
  final int affectedStudents;
  final String severity;
  final String action;
  final Color color;

  const _WeakSkill({
    required this.title,
    required this.affectedStudents,
    required this.severity,
    required this.action,
    required this.color,
  });
}

class _QuizResult {
  final String title;
  final String subject;
  final int classAverage;
  final int participants;
  final String date;
  final String status;
  final Color color;

  const _QuizResult({
    required this.title,
    required this.subject,
    required this.classAverage,
    required this.participants,
    required this.date,
    required this.status,
    required this.color,
  });
}

class _ShortcutData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ShortcutData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _MiniMetric {
  final String label;
  final String value;

  const _MiniMetric(this.label, this.value);
}

class _StudentSubject {
  final String name;
  final int progress;
  final int completedLessons;
  final int quizAverage;
  final String weakSkill;
  final String status;
  final Color color;

  const _StudentSubject({
    required this.name,
    required this.progress,
    required this.completedLessons,
    required this.quizAverage,
    required this.weakSkill,
    required this.status,
    required this.color,
  });
}

class _StudentQuiz {
  final String title;
  final String subject;
  final int score;
  final String date;
  final String status;
  final Color color;

  const _StudentQuiz({
    required this.title,
    required this.subject,
    required this.score,
    required this.date,
    required this.status,
    required this.color,
  });
}

class _StudentAnalytics {
  final String name;
  final String grade;
  final int mastery;
  final int quizAverage;
  final int points;
  final String lastActivity;
  final String status;
  final int completedLessons;
  final int quizCount;
  final int masteredSkills;
  final int weakSkillsCount;
  final int weeklyActivity;
  final int missedLessons;
  final String weakSkill;
  final String recommendation;
  final Color color;
  final List<_StudentSubject> subjects;
  final List<_StudentQuiz> quizzes;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> teacherRecommendations;
  final List<String> interventionPlan;

  const _StudentAnalytics({
    required this.name,
    required this.grade,
    required this.mastery,
    required this.quizAverage,
    required this.points,
    required this.lastActivity,
    required this.status,
    required this.completedLessons,
    required this.quizCount,
    required this.masteredSkills,
    required this.weakSkillsCount,
    required this.weeklyActivity,
    required this.missedLessons,
    required this.weakSkill,
    required this.recommendation,
    required this.color,
    required this.subjects,
    required this.quizzes,
    required this.strengths,
    required this.weaknesses,
    required this.teacherRecommendations,
    required this.interventionPlan,
  });

  String get initial => name.isEmpty ? '؟' : name.characters.first;
}

const _kpis = [
  _KpiData(
    icon: Icons.people_alt_rounded,
    label: 'عدد الطلاب',
    value: '24',
    trend: 'صف كامل',
    color: AppTheme.primaryBlue,
  ),
  _KpiData(
    icon: Icons.bolt_rounded,
    label: 'الطلاب النشطون هذا الأسبوع',
    value: '18',
    trend: '+8%',
    color: AppTheme.primaryGreen,
  ),
  _KpiData(
    icon: Icons.verified_rounded,
    label: 'متوسط الإتقان',
    value: '76%',
    trend: 'جيد',
    color: AppTheme.primaryPurple,
  ),
  _KpiData(
    icon: Icons.task_alt_rounded,
    label: 'الدروس المكتملة',
    value: '52',
    trend: '+12 درس',
    color: AppTheme.primaryGreen,
  ),
  _KpiData(
    icon: Icons.quiz_rounded,
    label: 'متوسط نتائج الاختبارات',
    value: '82%',
    trend: '+5%',
    color: AppTheme.primaryBlue,
  ),
  _KpiData(
    icon: Icons.priority_high_rounded,
    label: 'طلاب يحتاجون متابعة',
    value: '6',
    trend: 'يحتاج متابعة',
    color: AppTheme.primaryOrange,
  ),
];

const _classProgress = [
  _ProgressMetric(
    icon: Icons.workspace_premium_rounded,
    label: 'الإتقان العام',
    note: 'متوسط أداء الصف في المهارات الأساسية',
    progress: 0.76,
    color: AppTheme.primaryGreen,
  ),
  _ProgressMetric(
    icon: Icons.calendar_month_rounded,
    label: 'النشاط الأسبوعي',
    note: '18 طالباً شاركوا في أنشطة هذا الأسبوع',
    progress: 0.75,
    color: AppTheme.primaryBlue,
  ),
  _ProgressMetric(
    icon: Icons.menu_book_rounded,
    label: 'إكمال الدروس',
    note: '52 درساً مكتملاً من الخطة الحالية',
    progress: 0.68,
    color: AppTheme.primaryPurple,
  ),
  _ProgressMetric(
    icon: Icons.fact_check_rounded,
    label: 'متوسط الاختبارات',
    note: 'مؤشر جيد مع فجوة واضحة في الرياضيات',
    progress: 0.82,
    color: AppTheme.primaryOrange,
  ),
];

const _masteryBands = [
  _MasteryBand('ممتاز', 8, AppTheme.primaryGreen),
  _MasteryBand('جيد', 10, AppTheme.primaryBlue),
  _MasteryBand('يحتاج مراجعة', 4, AppTheme.primaryOrange),
  _MasteryBand('يحتاج متابعة مكثفة', 2, AppTheme.primaryPurple),
];

const _subjects = [
  _SubjectAnalysis(
    name: 'اللغة العربية',
    mastery: 84,
    status: 'ممتاز',
    completedLessons: 16,
    weakSkill: 'ملاحظة: بعض الطلاب يحتاجون دعماً في القراءة الجهرية.',
    recommendation: 'ابدأ الحصة القادمة بقراءة قصيرة جماعية لمدة 8 دقائق.',
    color: AppTheme.primaryGreen,
  ),
  _SubjectAnalysis(
    name: 'الرياضيات',
    mastery: 69,
    status: 'يحتاج مراجعة',
    completedLessons: 12,
    weakSkill: 'ملاحظة: الجمع ضمن 20 هو أضعف مهارة حالياً.',
    recommendation: 'خصص نشاطاً تدريبياً قصيراً قبل الانتقال للطرح.',
    color: AppTheme.primaryOrange,
  ),
  _SubjectAnalysis(
    name: 'العلوم',
    mastery: 78,
    status: 'جيد',
    completedLessons: 13,
    weakSkill: 'ملاحظة: التصنيف والمقارنة يحتاجان أمثلة مرئية أكثر.',
    recommendation: 'استخدم بطاقات صور لتصنيف الكائنات في مجموعات صغيرة.',
    color: AppTheme.primaryBlue,
  ),
  _SubjectAnalysis(
    name: 'اللغة الإنجليزية',
    mastery: 73,
    status: 'جيد',
    completedLessons: 11,
    weakSkill: 'ملاحظة: الربط بين الألوان والأشكال يحتاج تكراراً.',
    recommendation: 'نفذ لعبة مطابقة سريعة في نهاية الحصة.',
    color: AppTheme.primaryPurple,
  ),
];

const _weakSkills = [
  _WeakSkill(
    title: 'القراءة الجهرية',
    affectedStudents: 6,
    severity: 'متوسط',
    action: 'نفذ تدريب قراءة صوتية قصير',
    color: AppTheme.primaryBlue,
  ),
  _WeakSkill(
    title: 'الجمع ضمن 20',
    affectedStudents: 7,
    severity: 'يحتاج مراجعة',
    action: 'خصص نشاطاً تدريبياً قصيراً',
    color: AppTheme.primaryOrange,
  ),
  _WeakSkill(
    title: 'فهم المقروء',
    affectedStudents: 5,
    severity: 'متوسط',
    action: 'استخدم أسئلة مباشرة بعد كل فقرة',
    color: AppTheme.primaryPurple,
  ),
  _WeakSkill(
    title: 'التصنيف والمقارنة',
    affectedStudents: 4,
    severity: 'خفيف',
    action: 'اعرض أمثلة بصرية على السبورة',
    color: AppTheme.primaryGreen,
  ),
  _WeakSkill(
    title: 'ترتيب الجمل',
    affectedStudents: 5,
    severity: 'متوسط',
    action: 'استخدم بطاقات كلمات قابلة للترتيب',
    color: AppTheme.primaryBlue,
  ),
];

const _recentQuizzes = [
  _QuizResult(
    title: 'جمع الأعداد ضمن 20',
    subject: 'الرياضيات',
    classAverage: 74,
    participants: 22,
    date: '2026/06/24',
    status: 'يحتاج مراجعة',
    color: AppTheme.primaryOrange,
  ),
  _QuizResult(
    title: 'قراءة حرف الميم',
    subject: 'اللغة العربية',
    classAverage: 88,
    participants: 24,
    date: '2026/06/23',
    status: 'ممتاز',
    color: AppTheme.primaryGreen,
  ),
  _QuizResult(
    title: 'تصنيف الكائنات الحية',
    subject: 'العلوم',
    classAverage: 81,
    participants: 21,
    date: '2026/06/22',
    status: 'جيد',
    color: AppTheme.primaryBlue,
  ),
  _QuizResult(
    title: 'فهم المقروء',
    subject: 'اللغة العربية',
    classAverage: 76,
    participants: 23,
    date: '2026/06/20',
    status: 'جيد',
    color: AppTheme.primaryBlue,
  ),
  _QuizResult(
    title: 'ألوان وأشكال',
    subject: 'اللغة الإنجليزية',
    classAverage: 79,
    participants: 20,
    date: '2026/06/19',
    status: 'جيد',
    color: AppTheme.primaryPurple,
  ),
];

const _shortcuts = [
  _ShortcutData(
    icon: Icons.quiz_rounded,
    title: 'بنك الأسئلة',
    subtitle: 'راجع الأسئلة حسب المادة والدرس',
    color: AppTheme.primaryGreen,
  ),
  _ShortcutData(
    icon: Icons.description_rounded,
    title: 'تقارير الصف',
    subtitle: 'ملخص أسبوعي وشهري للأداء',
    color: AppTheme.primaryBlue,
  ),
  _ShortcutData(
    icon: Icons.priority_high_rounded,
    title: 'الطلاب المتعثرون',
    subtitle: 'قائمة تحتاج متابعة مباشرة',
    color: AppTheme.primaryOrange,
  ),
  _ShortcutData(
    icon: Icons.route_rounded,
    title: 'خطة مراجعة المهارات',
    subtitle: 'أنشطة قصيرة للمهارات الضعيفة',
    color: AppTheme.primaryPurple,
  ),
];

const _defaultSubjects = [
  _StudentSubject(
    name: 'اللغة العربية',
    progress: 82,
    completedLessons: 5,
    quizAverage: 86,
    weakSkill: 'القراءة الجهرية',
    status: 'جيد',
    color: AppTheme.primaryGreen,
  ),
  _StudentSubject(
    name: 'الرياضيات',
    progress: 68,
    completedLessons: 4,
    quizAverage: 72,
    weakSkill: 'الجمع ضمن 20',
    status: 'يحتاج مراجعة',
    color: AppTheme.primaryOrange,
  ),
  _StudentSubject(
    name: 'العلوم',
    progress: 78,
    completedLessons: 4,
    quizAverage: 80,
    weakSkill: 'التصنيف والمقارنة',
    status: 'جيد',
    color: AppTheme.primaryBlue,
  ),
  _StudentSubject(
    name: 'اللغة الإنجليزية',
    progress: 74,
    completedLessons: 3,
    quizAverage: 78,
    weakSkill: 'ألوان وأشكال',
    status: 'جيد',
    color: AppTheme.primaryPurple,
  ),
];

const _defaultQuizzes = [
  _StudentQuiz(
    title: 'جمع الأعداد ضمن 20',
    subject: 'الرياضيات',
    score: 72,
    date: '2026/06/24',
    status: 'مراجعة',
    color: AppTheme.primaryOrange,
  ),
  _StudentQuiz(
    title: 'قراءة حرف الميم',
    subject: 'اللغة العربية',
    score: 88,
    date: '2026/06/23',
    status: 'ممتاز',
    color: AppTheme.primaryGreen,
  ),
  _StudentQuiz(
    title: 'تصنيف الكائنات الحية',
    subject: 'العلوم',
    score: 81,
    date: '2026/06/22',
    status: 'جيد',
    color: AppTheme.primaryBlue,
  ),
  _StudentQuiz(
    title: 'فهم المقروء',
    subject: 'اللغة العربية',
    score: 76,
    date: '2026/06/20',
    status: 'جيد',
    color: AppTheme.primaryPurple,
  ),
];

const _students = [
  _StudentAnalytics(
    name: 'نور إبراهيم حسن',
    grade: 'الصف الأول',
    mastery: 61,
    quizAverage: 70,
    points: 340,
    lastActivity: 'منذ يومين',
    status: 'يحتاج متابعة',
    completedLessons: 11,
    quizCount: 8,
    masteredSkills: 4,
    weakSkillsCount: 3,
    weeklyActivity: 54,
    missedLessons: 3,
    weakSkill: 'القراءة الجهرية',
    recommendation: 'مراجعة القراءة الجهرية مع أمثلة صوتية قصيرة.',
    color: AppTheme.primaryOrange,
    subjects: _defaultSubjects,
    quizzes: _defaultQuizzes,
    strengths: [
      'تمييز الحروف',
      'حل الأسئلة البصرية',
      'الالتزام بالأنشطة اليومية',
    ],
    weaknesses: ['القراءة الجهرية', 'فهم المقروء', 'ترتيب الجمل'],
    teacherRecommendations: [
      'مراجعة درس القراءة الجهرية مع أمثلة صوتية.',
      'متابعة الطالب في الاختبار القادم.',
      'إعطاء نشاط قراءة قصير في بداية الحصة.',
    ],
    interventionPlan: [
      'تحديد فقرة قصيرة للقراءة الفردية.',
      'تسجيل ملاحظة أداء بعد كل تدريب.',
      'مقارنة نتيجة الاختبار القادم بنتيجة الأسبوع الحالي.',
    ],
  ),
  _StudentAnalytics(
    name: 'أحمد وليد عساف',
    grade: 'الصف الأول',
    mastery: 58,
    quizAverage: 66,
    points: 310,
    lastActivity: 'أمس',
    status: 'متابعة مكثفة',
    completedLessons: 10,
    quizCount: 7,
    masteredSkills: 3,
    weakSkillsCount: 4,
    weeklyActivity: 48,
    missedLessons: 4,
    weakSkill: 'الجمع ضمن 20',
    recommendation: 'تدريب قصير على الجمع لمدة 10 دقائق.',
    color: AppTheme.primaryOrange,
    subjects: _defaultSubjects,
    quizzes: _defaultQuizzes,
    strengths: ['التفاعل الشفهي', 'تمييز الألوان', 'المشاركة عند التشجيع'],
    weaknesses: ['الجمع ضمن 20', 'فهم المقروء', 'ترتيب الجمل'],
    teacherRecommendations: [
      'إعطاء الطالب تدريباً قصيراً على الجمع لمدة 10 دقائق.',
      'استخدام مكعبات العد قبل حل المسائل الورقية.',
      'متابعة الطالب في الاختبار القادم.',
    ],
    interventionPlan: [
      'بدء كل حصة رياضيات بخمس مسائل بسيطة.',
      'تسجيل الأخطاء المتكررة في بطاقة متابعة.',
      'إعادة اختبار مصغر بعد أسبوع.',
    ],
  ),
  _StudentAnalytics(
    name: 'عمر سعيد المصري',
    grade: 'الصف الأول',
    mastery: 64,
    quizAverage: 73,
    points: 370,
    lastActivity: 'اليوم',
    status: 'يحتاج مراجعة',
    completedLessons: 12,
    quizCount: 8,
    masteredSkills: 5,
    weakSkillsCount: 3,
    weeklyActivity: 62,
    missedLessons: 2,
    weakSkill: 'فهم المقروء',
    recommendation: 'استخدام أسئلة قصيرة بعد قراءة الفقرة.',
    color: AppTheme.primaryBlue,
    subjects: _defaultSubjects,
    quizzes: _defaultQuizzes,
    strengths: ['حل الأسئلة البصرية', 'التصنيف والمقارنة', 'المشاركة الجماعية'],
    weaknesses: ['فهم المقروء', 'القراءة الجهرية', 'الجمع ضمن 20'],
    teacherRecommendations: [
      'طرح سؤالين بعد كل فقرة قراءة.',
      'استخدام صور داعمة لفهم النص.',
      'متابعة الطالب في الاختبار القادم.',
    ],
    interventionPlan: [
      'اختيار قصة قصيرة مناسبة للمستوى.',
      'تطبيق أسئلة من نوع ماذا ولماذا.',
      'مراجعة الإجابات مع الطالب شفهياً.',
    ],
  ),
  _StudentAnalytics(
    name: 'ليلى خالد أبو عمر',
    grade: 'الصف الأول',
    mastery: 67,
    quizAverage: 75,
    points: 390,
    lastActivity: 'اليوم',
    status: 'يحتاج متابعة',
    completedLessons: 13,
    quizCount: 9,
    masteredSkills: 5,
    weakSkillsCount: 2,
    weeklyActivity: 68,
    missedLessons: 2,
    weakSkill: 'ترتيب الجمل',
    recommendation: 'نشاط بطاقات لترتيب الكلمات والجمل.',
    color: AppTheme.primaryPurple,
    subjects: _defaultSubjects,
    quizzes: _defaultQuizzes,
    strengths: [
      'الالتزام بالأنشطة اليومية',
      'تمييز الحروف',
      'حل الأسئلة البصرية',
    ],
    weaknesses: ['ترتيب الجمل', 'فهم المقروء', 'القراءة الجهرية'],
    teacherRecommendations: [
      'تدريب ترتيب الجمل باستخدام بطاقات كلمات.',
      'ربط الجمل بصورة واضحة.',
      'متابعة الطالب في الاختبار القادم.',
    ],
    interventionPlan: [
      'تحضير ثلاث جمل قصيرة مبعثرة.',
      'مراجعة الترتيب الصحيح مع سبب الاختيار.',
      'إعادة النشاط في نهاية الأسبوع.',
    ],
  ),
  _StudentAnalytics(
    name: 'سارة محمود خليل',
    grade: 'الصف الأول',
    mastery: 92,
    quizAverage: 94,
    points: 620,
    lastActivity: 'اليوم',
    status: 'ممتاز',
    completedLessons: 18,
    quizCount: 11,
    masteredSkills: 9,
    weakSkillsCount: 1,
    weeklyActivity: 96,
    missedLessons: 0,
    weakSkill: 'لا توجد فجوة مؤثرة',
    recommendation: 'منح نشاط إثرائي قصير للحفاظ على التقدم.',
    color: AppTheme.primaryGreen,
    subjects: _defaultSubjects,
    quizzes: _defaultQuizzes,
    strengths: [
      'تمييز الحروف',
      'حل الأسئلة البصرية',
      'الالتزام بالأنشطة اليومية',
    ],
    weaknesses: ['مراجعة خفيفة في ترتيب الجمل'],
    teacherRecommendations: [
      'تقديم نشاط إثرائي قصير.',
      'إشراك الطالبة في مساعدة الزملاء خلال التدريب.',
      'متابعة الاستمرارية الأسبوعية.',
    ],
    interventionPlan: [
      'تكليف نشاط تحد إضافي.',
      'مراقبة الدقة في الأسئلة السريعة.',
      'تقديم تغذية راجعة إيجابية.',
    ],
  ),
  _StudentAnalytics(
    name: 'محمد سامر عودة',
    grade: 'الصف الأول',
    mastery: 89,
    quizAverage: 90,
    points: 590,
    lastActivity: 'اليوم',
    status: 'ممتاز',
    completedLessons: 17,
    quizCount: 10,
    masteredSkills: 8,
    weakSkillsCount: 1,
    weeklyActivity: 92,
    missedLessons: 0,
    weakSkill: 'مراجعة خفيفة في فهم المقروء',
    recommendation: 'نشاط قراءة إثرائي قصير.',
    color: AppTheme.primaryGreen,
    subjects: _defaultSubjects,
    quizzes: _defaultQuizzes,
    strengths: [
      'حل الأسئلة البصرية',
      'التصنيف والمقارنة',
      'الالتزام بالأنشطة اليومية',
    ],
    weaknesses: ['مراجعة خفيفة في فهم المقروء'],
    teacherRecommendations: [
      'تكليف قراءة قصيرة إضافية.',
      'تشجيع الطالب على شرح الحل لزميل.',
      'متابعة مستوى الصعوبة في الاختبارات القادمة.',
    ],
    interventionPlan: [
      'اختيار سؤال تحد إضافي.',
      'تسجيل ملاحظة حول سرعة الحل.',
      'مراجعة النتيجة نهاية الأسبوع.',
    ],
  ),
  _StudentAnalytics(
    name: 'تالا يوسف حمدان',
    grade: 'الصف الأول',
    mastery: 86,
    quizAverage: 88,
    points: 560,
    lastActivity: 'أمس',
    status: 'جيد جداً',
    completedLessons: 16,
    quizCount: 10,
    masteredSkills: 8,
    weakSkillsCount: 1,
    weeklyActivity: 88,
    missedLessons: 1,
    weakSkill: 'مراجعة خفيفة في الجمع ضمن 20',
    recommendation: 'أسئلة تدريبية قصيرة للحفاظ على الدقة.',
    color: AppTheme.primaryBlue,
    subjects: _defaultSubjects,
    quizzes: _defaultQuizzes,
    strengths: [
      'تمييز الحروف',
      'الالتزام بالأنشطة اليومية',
      'حل الأسئلة البصرية',
    ],
    weaknesses: ['مراجعة خفيفة في الجمع ضمن 20'],
    teacherRecommendations: [
      'تقديم تمرين سريع للحفاظ على الدقة.',
      'تعزيز المشاركة في النقاش.',
      'متابعة نشاط الأسبوع القادم.',
    ],
    interventionPlan: [
      'سؤالان تدريبيان في بداية الحصة.',
      'ملاحظة سرعة الإجابة.',
      'تقديم نشاط إثرائي عند الثبات.',
    ],
  ),
  _StudentAnalytics(
    name: 'يوسف رامي نزال',
    grade: 'الصف الأول',
    mastery: 83,
    quizAverage: 86,
    points: 540,
    lastActivity: 'اليوم',
    status: 'جيد جداً',
    completedLessons: 16,
    quizCount: 9,
    masteredSkills: 7,
    weakSkillsCount: 1,
    weeklyActivity: 84,
    missedLessons: 1,
    weakSkill: 'مراجعة خفيفة في القراءة الجهرية',
    recommendation: 'قراءة فقرة قصيرة بصوت واضح.',
    color: AppTheme.primaryBlue,
    subjects: _defaultSubjects,
    quizzes: _defaultQuizzes,
    strengths: [
      'التصنيف والمقارنة',
      'حل الأسئلة البصرية',
      'الالتزام بالأنشطة اليومية',
    ],
    weaknesses: ['مراجعة خفيفة في القراءة الجهرية'],
    teacherRecommendations: [
      'قراءة فقرة قصيرة بصوت واضح.',
      'تقديم تغذية راجعة على النطق.',
      'متابعة الأداء في حصة القراءة.',
    ],
    interventionPlan: [
      'قراءة دقيقة واحدة أمام المعلم.',
      'تحديد كلمة واحدة للتحسين.',
      'إعادة القراءة بعد التدريب.',
    ],
  ),
];

final _atRiskStudents = [
  _students[0],
  _students[1],
  _students[2],
  _students[3],
];
final _topStudents = [_students[4], _students[5], _students[6], _students[7]];
final _allStudents = [
  _students[4],
  _students[5],
  _students[6],
  _students[7],
  _students[0],
  _students[1],
  _students[2],
  _students[3],
];
