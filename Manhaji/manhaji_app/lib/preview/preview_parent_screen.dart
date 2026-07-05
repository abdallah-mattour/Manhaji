import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../widgets/vibrant_background.dart';
import 'preview_banner.dart';

/// Parent preview only.
/// Local sample data, no providers, no API calls, no auth, no persistence.
class PreviewParentScreen extends StatelessWidget {
  const PreviewParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة ولي الأمر'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(28),
            child: PreviewBanner(),
          ),
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              const _Header(),
              const SizedBox(height: 18),
              _ChildOverviewCard(
                onDetails: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _PreviewChildDetailsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'إحصاءات سريعة'),
              const SizedBox(height: 10),
              const _QuickStatsGrid(),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'التقدم حسب المادة'),
              const SizedBox(height: 10),
              const _SubjectProgressList(),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'نتائج الاختبارات الأخيرة'),
              const SizedBox(height: 10),
              const _RecentQuizList(),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'مهارات تحتاج مراجعة'),
              const SizedBox(height: 10),
              const _WeakSkillsList(),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'توصيات منزلية'),
              const SizedBox(height: 10),
              const _RecommendationList(),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'الإشعارات والتنبيهات'),
              const SizedBox(height: 10),
              const _NotificationList(),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'التقارير'),
              const SizedBox(height: 10),
              const _ReportsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewChildDetailsScreen extends StatelessWidget {
  const _PreviewChildDetailsScreen();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الطفل'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          leading: IconButton(
            tooltip: 'رجوع',
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(28),
            child: PreviewBanner(),
          ),
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: const [
              _ChildProfileCard(),
              SizedBox(height: 16),
              _OverallProgressCard(),
              SizedBox(height: 20),
              _SectionTitle(title: 'التقدم حسب المادة'),
              SizedBox(height: 10),
              _SubjectProgressList(),
              SizedBox(height: 20),
              _SectionTitle(title: 'إنجاز الدروس'),
              SizedBox(height: 10),
              _LessonCompletionList(),
              SizedBox(height: 20),
              _SectionTitle(title: 'أداء الاختبارات الأخيرة'),
              SizedBox(height: 10),
              _RecentQuizList(),
              SizedBox(height: 20),
              _SectionTitle(title: 'نقاط القوة'),
              SizedBox(height: 10),
              _StrengthsList(),
              SizedBox(height: 20),
              _SectionTitle(title: 'نقاط تحتاج مراجعة'),
              SizedBox(height: 10),
              _WeakSkillsList(),
              SizedBox(height: 20),
              _SectionTitle(title: 'توصيات لولي الأمر'),
              SizedBox(height: 10),
              _RecommendationList(),
              SizedBox(height: 20),
              _SectionTitle(title: 'التقارير'),
              SizedBox(height: 10),
              _ReportsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'لوحة ولي الأمر',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'مرحباً، سعاد خالد ناصر',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryGreen,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'تابع تقدم طفلك الدراسي بسهولة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }
}

class _ChildOverviewCard extends StatelessWidget {
  final VoidCallback onDetails;

  const _ChildOverviewCard({required this.onDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(
        borderColor: AppTheme.primaryGreen.withValues(alpha: 0.16),
        shadow: AppTheme.elevationMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Color(0x1F58CC02),
                child: Text(
                  'م',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'محمد سعاد ناصر',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'الصف الأول',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: 'نشط اليوم', color: AppTheme.primaryGreen),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: _InlineMetric(
                  icon: Icons.local_fire_department_rounded,
                  label: 'السلسلة',
                  value: '7 أيام',
                  color: AppTheme.primaryOrange,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _InlineMetric(
                  icon: Icons.star_rounded,
                  label: 'النقاط',
                  value: '540',
                  color: AppTheme.primaryYellowDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                child: _InlineMetric(
                  icon: Icons.check_circle_rounded,
                  label: 'الدروس',
                  value: '18/26',
                  color: AppTheme.primaryGreen,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _InlineMetric(
                  icon: Icons.history_rounded,
                  label: 'آخر نشاط',
                  value: 'اليوم',
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _ProgressLine(
            label: 'التقدم العام',
            value: '72%',
            progress: 0.72,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onDetails,
              icon: const Icon(Icons.insights_rounded, size: 20),
              label: const Text('عرض التفاصيل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.task_alt_rounded,
                title: 'الدروس المكتملة',
                value: '18',
                color: AppTheme.primaryGreen,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.quiz_rounded,
                title: 'متوسط الاختبارات',
                value: '84%',
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.workspace_premium_rounded,
                title: 'المهارات المتقنة',
                value: '6',
                color: AppTheme.primaryPurple,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.tips_and_updates_rounded,
                title: 'مهارات تحتاج مراجعة',
                value: '3',
                color: AppTheme.primaryOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubjectProgressList extends StatelessWidget {
  const _SubjectProgressList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final subject in _subjects) _SubjectProgressCard(subject: subject),
      ],
    );
  }
}

class _SubjectProgressCard extends StatelessWidget {
  final _SubjectData subject;

  const _SubjectProgressCard({required this.subject});

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 10),
          _ProgressLine(
            label: '${subject.percent.toStringAsFixed(0)}%',
            value: '${subject.completedLessons}/${subject.totalLessons} درس',
            progress: subject.percent / 100,
            color: subject.color,
          ),
        ],
      ),
    );
  }
}

class _RecentQuizList extends StatelessWidget {
  const _RecentQuizList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < _quizzes.length; i++) ...[
            _QuizTile(quiz: _quizzes[i]),
            if (i != _quizzes.length - 1) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  final _QuizData quiz;

  const _QuizTile({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final color = quiz.score >= 85
        ? AppTheme.primaryGreen
        : quiz.score >= 75
        ? AppTheme.primaryBlue
        : AppTheme.primaryOrange;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(Icons.quiz_rounded, color: color, size: 22),
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
                quiz.subject,
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
        _StatusBadge(label: '${quiz.score}%', color: color),
      ],
    );
  }
}

class _WeakSkillsList extends StatelessWidget {
  const _WeakSkillsList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < _weakSkills.length; i++) ...[
            _WeakSkillTile(skill: _weakSkills[i]),
            if (i != _weakSkills.length - 1) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _WeakSkillTile extends StatelessWidget {
  final _WeakSkillData skill;

  const _WeakSkillTile({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.flag_rounded, color: skill.color, size: 22),
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
                  _StatusBadge(label: skill.status, color: skill.color),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                skill.recommendation,
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

class _RecommendationList extends StatelessWidget {
  const _RecommendationList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          _InfoRow(
            icon: Icons.home_work_rounded,
            color: AppTheme.primaryGreen,
            title: 'راجع درس حرف الميم لمدة 10 دقائق.',
          ),
          Divider(height: 20),
          _InfoRow(
            icon: Icons.record_voice_over_rounded,
            color: AppTheme.primaryBlue,
            title: 'شجع الطفل على قراءة فقرة قصيرة بصوت عال.',
          ),
          Divider(height: 20),
          _InfoRow(
            icon: Icons.calculate_rounded,
            color: AppTheme.primaryOrange,
            title: 'حل 5 أسئلة تدريبية في الجمع.',
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          _InfoRow(
            icon: Icons.description_rounded,
            color: AppTheme.primaryBlue,
            title: 'تقرير أسبوعي جديد متاح.',
          ),
          Divider(height: 20),
          _InfoRow(
            icon: Icons.trending_up_rounded,
            color: AppTheme.primaryGreen,
            title: 'تحسن في اللغة العربية.',
          ),
          Divider(height: 20),
          _InfoRow(
            icon: Icons.warning_amber_rounded,
            color: AppTheme.primaryOrange,
            title: 'يحتاج مراجعة في الرياضيات.',
          ),
        ],
      ),
    );
  }
}

class _ReportsSection extends StatelessWidget {
  const _ReportsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          _ReportTile(
            title: 'التقرير الأسبوعي',
            subtitle: 'ملخص تقدم الطفل خلال آخر 7 أيام',
          ),
          Divider(height: 22),
          _ReportTile(
            title: 'التقرير الشهري',
            subtitle: 'نظرة أوسع على الأداء والمهارات',
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ReportTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_rounded,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
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
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('عرض التقرير'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('تحميل'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  const _ChildProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Color(0x1F58CC02),
                child: Text(
                  'م',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'محمد سعاد ناصر',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'الصف الأول - آخر نشاط اليوم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: 'نشط', color: AppTheme.primaryGreen),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  icon: Icons.star_rounded,
                  label: 'النقاط',
                  value: '540',
                  color: AppTheme.primaryYellowDeep,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _SmallStat(
                  icon: Icons.local_fire_department_rounded,
                  label: 'السلسلة',
                  value: '7',
                  color: AppTheme.primaryOrange,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _SmallStat(
                  icon: Icons.school_rounded,
                  label: 'الإتقان',
                  value: '72%',
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
  const _OverallProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التقدم العام',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 12),
          _ProgressLine(
            label: '72%',
            value: '18/26 درس',
            progress: 0.72,
            color: AppTheme.primaryGreen,
          ),
          SizedBox(height: 14),
          _DetailRow(label: 'دروس مكتملة', value: '18'),
          _DetailRow(label: 'دروس قيد التقدم', value: '4'),
          _DetailRow(label: 'محاولات الاختبار', value: '14'),
          _DetailRow(label: 'متوسط الاختبارات', value: '84%'),
        ],
      ),
    );
  }
}

class _LessonCompletionList extends StatelessWidget {
  const _LessonCompletionList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          _LessonRow(title: 'حرف الميم', status: 'مكتمل'),
          Divider(height: 20),
          _LessonRow(title: 'جمع الأعداد ضمن 20', status: 'قيد المراجعة'),
          Divider(height: 20),
          _LessonRow(title: 'تصنيف الكائنات الحية', status: 'مكتمل'),
          Divider(height: 20),
          _LessonRow(title: 'ألوان وأشكال', status: 'مكتمل'),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final String title;
  final String status;

  const _LessonRow({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    final completed = status == 'مكتمل';
    return Row(
      children: [
        Icon(
          completed ? Icons.check_circle_rounded : Icons.pending_rounded,
          color: completed ? AppTheme.primaryGreen : AppTheme.primaryOrange,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
        ),
        _StatusBadge(
          label: status,
          color: completed ? AppTheme.primaryGreen : AppTheme.primaryOrange,
        ),
      ],
    );
  }
}

class _StrengthsList extends StatelessWidget {
  const _StrengthsList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          _InfoRow(
            icon: Icons.workspace_premium_rounded,
            color: AppTheme.primaryGreen,
            title: 'تمييز الحروف والكلمات القصيرة.',
          ),
          Divider(height: 20),
          _InfoRow(
            icon: Icons.workspace_premium_rounded,
            color: AppTheme.primaryGreen,
            title: 'حل أسئلة الأشكال والألوان بثقة.',
          ),
        ],
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InlineMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
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
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(borderColor: color.withValues(alpha: 0.12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 25),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
              height: 1.25,
            ),
          ),
        ],
      ),
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
    final safe = progress.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: safe,
                  minHeight: 10,
                  backgroundColor: color.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textGray,
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
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13.5,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppTheme.textDark,
      ),
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

BoxDecoration _cardDecoration({
  Color borderColor = AppTheme.surfaceSubtle,
  List<BoxShadow>? shadow,
}) {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusL),
    boxShadow: shadow ?? AppTheme.elevationLow,
    border: Border.all(color: borderColor, width: 1),
  );
}

class _SubjectData {
  final String name;
  final double percent;
  final int completedLessons;
  final int totalLessons;
  final String status;
  final Color color;

  const _SubjectData({
    required this.name,
    required this.percent,
    required this.completedLessons,
    required this.totalLessons,
    required this.status,
    required this.color,
  });
}

class _QuizData {
  final String title;
  final String subject;
  final int score;

  const _QuizData(this.title, this.subject, this.score);
}

class _WeakSkillData {
  final String title;
  final String status;
  final String recommendation;
  final Color color;

  const _WeakSkillData({
    required this.title,
    required this.status,
    required this.recommendation,
    required this.color,
  });
}

const _subjects = [
  _SubjectData(
    name: 'اللغة العربية',
    percent: 82,
    completedLessons: 7,
    totalLessons: 9,
    status: 'ممتاز',
    color: AppTheme.primaryGreen,
  ),
  _SubjectData(
    name: 'الرياضيات',
    percent: 64,
    completedLessons: 5,
    totalLessons: 8,
    status: 'يحتاج مراجعة',
    color: AppTheme.primaryOrange,
  ),
  _SubjectData(
    name: 'العلوم',
    percent: 76,
    completedLessons: 4,
    totalLessons: 5,
    status: 'جيد',
    color: AppTheme.primaryBlue,
  ),
  _SubjectData(
    name: 'اللغة الإنجليزية',
    percent: 70,
    completedLessons: 2,
    totalLessons: 4,
    status: 'جيد',
    color: AppTheme.primaryPurple,
  ),
];

const _quizzes = [
  _QuizData('جمع الأعداد ضمن 20', 'الرياضيات', 72),
  _QuizData('قراءة حرف الميم', 'اللغة العربية', 88),
  _QuizData('تصنيف الكائنات الحية', 'العلوم', 81),
  _QuizData('ألوان وأشكال', 'اللغة الإنجليزية', 78),
];

const _weakSkills = [
  _WeakSkillData(
    title: 'القراءة الجهرية',
    status: 'متوسط',
    recommendation: 'كرر قراءة فقرة قصيرة بصوت واضح يومياً.',
    color: AppTheme.primaryBlue,
  ),
  _WeakSkillData(
    title: 'الجمع ضمن 20',
    status: 'أولوية',
    recommendation: 'حل 5 أسئلة تدريبية مع استخدام العد بالمكعبات.',
    color: AppTheme.primaryOrange,
  ),
  _WeakSkillData(
    title: 'فهم المقروء',
    status: 'يحتاج متابعة',
    recommendation: 'اسأل الطفل سؤالين بعد كل قصة قصيرة.',
    color: AppTheme.primaryPurple,
  ),
];
