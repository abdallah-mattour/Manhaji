import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/ai_report.dart';
import '../../providers/report_provider.dart';
import '../../widgets/vibrant_background.dart';
import '../../widgets/duolingo_card.dart';
import '../../widgets/duolingo_button.dart';

class AiReportsScreen extends StatefulWidget {
  const AiReportsScreen({super.key});

  @override
  State<AiReportsScreen> createState() => _AiReportsScreenState();
}

class _AiReportsScreenState extends State<AiReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ReportProvider>();
      provider.loadReports();
      provider.loadLearningPath();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير الذكية'),
          backgroundColor: AppTheme.backgroundLight,
          foregroundColor: AppTheme.textDark,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryPurple,
            labelColor: AppTheme.primaryPurple,
            unselectedLabelColor: AppTheme.textGray,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'تقرير الأداء'),
              Tab(text: 'خطة التعلم'),
            ],
          ),
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: TabBarView(
            controller: _tabController,
            children: [
              _ProgressReportsTab(),
              _LearningPathTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressReportsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Generate button
            Padding(
              padding: const EdgeInsets.all(16),
              child: DuolingoButton(
                onPressed: provider.isGenerating
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await provider.generateReport();
                        if (provider.error != null) {
                          messenger.showSnackBar(SnackBar(
                            content: Text(provider.error!,
                                style: const TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: AppTheme.primaryRed,
                          ));
                        }
                      },
                color: AppTheme.primaryPurple,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.isGenerating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.auto_awesome, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      provider.isGenerating ? 'جاري الإنشاء...' : 'إنشاء تقرير جديد',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Reports list (with live stats header)
            Expanded(
              child: provider.isLoading && provider.reports == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(ReportProvider provider) {
    final stats = provider.stats;
    final reports = provider.reports ?? const [];

    // Friendly empty-state when the student has no activity at all.
    if (stats != null && !stats.hasActivity && reports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🚀', style: TextStyle(fontSize: 56)),
              SizedBox(height: 16),
              Text(
                'ابدأ رحلتك التعليمية!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'أكمل بعض الدروس والاختبارات أولاً،\nثم أنشئ تقريرك لرؤية تقدّمك بالأرقام.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Cairo', color: AppTheme.textGray, height: 1.6),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (stats != null) _StatsHeader(stats: stats),
        if (reports.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.assessment_outlined,
                    size: 48, color: AppTheme.textLight),
                SizedBox(height: 10),
                Text(
                  'لا توجد تقارير بعد\nاضغط الزر أعلاه لإنشاء أول تقرير',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontFamily: 'Cairo', color: AppTheme.textGray),
                ),
              ],
            ),
          )
        else
          ...reports.map((report) => _ReportCard(report: report)),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Live performance snapshot: headline metric cards + per-subject mastery bars.
class _StatsHeader extends StatelessWidget {
  final PerformanceStats stats;
  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Headline metric tiles (2 columns).
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _MetricTile(
                icon: Icons.menu_book_rounded,
                color: AppTheme.primaryTerracotta,
                value: '${stats.completedLessons}/${stats.totalLessons}',
                label: 'دروس مكتملة'),
            _MetricTile(
                icon: Icons.track_changes_rounded,
                color: AppTheme.primaryBlue,
                value: '${stats.averageMastery.round()}%',
                label: 'متوسط الإتقان'),
            _MetricTile(
                icon: Icons.quiz_rounded,
                color: AppTheme.primaryPurple,
                value: '${stats.averageScore.round()}%',
                label: 'متوسط الدرجات'),
            _MetricTile(
                icon: Icons.local_fire_department_rounded,
                color: AppTheme.primaryOrange,
                value: '${stats.currentStreak}',
                label: 'أيام متتالية'),
          ],
        ),
        const SizedBox(height: 16),
        if (stats.subjects.any((s) => s.totalLessons > 0)) ...[
          const Text('الإتقان حسب المادة',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          DuolingoCard(
            padding: const EdgeInsets.all(14),
            borderColor: AppTheme.surfaceMuted,
            child: Column(
              children: [
                for (final s in stats.subjects)
                  _SubjectBar(stat: s),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text('التقارير',
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _MetricTile(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: color)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  final SubjectStat stat;
  const _SubjectBar({required this.stat});

  @override
  Widget build(BuildContext context) {
    final mastery = (stat.averageMastery / 100).clamp(0.0, 1.0);
    final barColor = stat.averageMastery >= 70
        ? AppTheme.primaryGreen
        : stat.averageMastery >= 40
            ? AppTheme.primaryOrange
            : AppTheme.primaryRed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(stat.subjectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark)),
              ),
              Text(
                  '${stat.averageMastery.round()}%  ·  ${stat.completedLessons}/${stat.totalLessons}',
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textGray)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: LinearProgressIndicator(
              value: mastery,
              minHeight: 9,
              backgroundColor: AppTheme.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ProgressReportModel report;

  const _ReportCard({required this.report});

  Color _riskColor(String level) {
    return switch (level) {
      'LOW' => AppTheme.primaryGreen,
      'MEDIUM' => AppTheme.primaryOrange,
      'HIGH' => AppTheme.primaryRed,
      _ => AppTheme.textGray,
    };
  }

  String _riskLabel(String level) {
    return switch (level) {
      'LOW' => 'منخفض',
      'MEDIUM' => 'متوسط',
      'HIGH' => 'مرتفع',
      _ => level,
    };
  }

  /// Defensive cleanup so any report whose `summary` still arrives as a raw,
  /// markdown-fenced, or even TRUNCATED JSON blob (older rows saved before the
  /// backend fixes) renders as readable text instead of "json``` { ... }".
  String _cleanSummary(String raw) {
    var s = raw.trim();

    // 1) Strip a leading ```json / ``` fence even if the closing fence is
    //    missing (truncated responses have no closing fence).
    if (s.startsWith('```')) {
      final firstNewline = s.indexOf('\n');
      if (firstNewline > 0) s = s.substring(firstNewline + 1);
      final lastFence = s.lastIndexOf('```');
      if (lastFence >= 0) s = s.substring(0, lastFence);
      s = s.trim();
    }

    // 2) If it's a JSON object, pull out the summary field.
    if (s.startsWith('{')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map && decoded['summary'] is String) {
          return (decoded['summary'] as String).trim();
        }
      } catch (_) {
        // 3) Invalid/truncated JSON — salvage the summary value with a regex
        //    so even a cut-off report still shows its (partial) summary text
        //    rather than raw "summary": "... markup.
        final m =
            RegExp(r'"summary"\s*:\s*"((?:[^"\\]|\\.)*)').firstMatch(s);
        if (m != null) {
          var v = m.group(1) ?? '';
          // Unescape common JSON sequences for display.
          v = v
              .replaceAll(r'\n', '\n')
              .replaceAll(r'\"', '"')
              .replaceAll(r'\\', '\\')
              .trim();
          if (v.isNotEmpty) return v;
        }
      }
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DuolingoCard(
        padding: const EdgeInsets.all(16),
        borderColor: AppTheme.surfaceMuted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: AppTheme.textGray),
                    const SizedBox(width: 6),
                    Text(
                      '${report.periodStart} → ${report.periodEnd}',
                      style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppTheme.textGray,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _riskColor(report.riskLevel).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _riskLabel(report.riskLevel),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _riskColor(report.riskLevel),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _cleanSummary(report.summary),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                height: 1.5,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (report.strengths.isNotEmpty)
              _DetailSection(
                title: 'نقاط القوة',
                icon: Icons.star_rounded,
                color: AppTheme.primaryGreen,
                items: report.strengths,
              ),
            if (report.improvements.isNotEmpty)
              _DetailSection(
                title: 'نقاط تحتاج تحسين',
                icon: Icons.trending_up_rounded,
                color: AppTheme.primaryOrange,
                items: report.improvements,
              ),
            if (report.recommendations.isNotEmpty)
              _DetailSection(
                title: 'توصيات لولي الأمر',
                icon: Icons.lightbulb_rounded,
                color: AppTheme.primaryBlue,
                items: report.recommendations,
              ),
          ],
        ),
      ),
    );
  }
}

/// A titled, icon-bulleted list section inside a report card
/// (strengths / improvements / recommendations).
class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            color: color)),
                    Expanded(
                      child: Text(t,
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _LearningPathTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DuolingoButton(
                onPressed: provider.isGenerating
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await provider.generateLearningPath();
                        if (provider.error != null) {
                          messenger.showSnackBar(SnackBar(
                            content: Text(provider.error!,
                                style: const TextStyle(fontFamily: 'Cairo')),
                            backgroundColor: AppTheme.primaryRed,
                          ));
                        }
                      },
                color: AppTheme.primaryBlue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.isGenerating)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.route, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      provider.isGenerating ? 'جاري الإنشاء...' : 'إنشاء خطة تعلم مخصصة',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: provider.isLoading && provider.learningPath == null
                  ? const Center(child: CircularProgressIndicator())
                  : provider.learningPath == null
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.route,
                                    size: 60, color: AppTheme.textLight),
                                SizedBox(height: 12),
                                Text(
                                  'لا توجد خطة تعلم بعد\nاضغط الزر أعلاه لإنشاء خطة مخصصة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: AppTheme.textGray),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _LearningPathContent(
                          recommendations:
                              provider.learningPath!.recommendations),
            ),
          ],
        );
      },
    );
  }
}

class _LearningPathContent extends StatelessWidget {
  final String recommendations;

  const _LearningPathContent({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(recommendations);
    } catch (e) {
      debugPrint('[ai-report] JSON parse failed: $e');
      parsed = null;
    }

    if (parsed == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DuolingoCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppTheme.surfaceMuted,
          child: Text(
            recommendations,
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 14, height: 1.6, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final tips = (parsed['tips'] as List?)?.cast<String>() ?? [];
    final activities = (parsed['activities'] as List?)?.cast<String>() ?? [];
    final reviewLessons = (parsed['reviewLessons'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (reviewLessons.isNotEmpty) ...[
          const Text('دروس للمراجعة',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...reviewLessons.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DuolingoCard(
                  padding: const EdgeInsets.all(12),
                  borderColor: AppTheme.primaryOrange,
                  child: Row(
                    children: [
                      const Icon(Icons.replay_circle_filled,
                          color: AppTheme.primaryOrange, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l is Map ? (l['topic'] ?? l['subject'] ?? '') : '$l',
                              style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textDark),
                            ),
                            if (l is Map && l['reason'] != null)
                              Text(l['reason'],
                                  style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textGray)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (activities.isNotEmpty) ...[
          const Text('أنشطة مقترحة',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...activities.map((a) => _BulletItem(text: a, icon: Icons.lightbulb,
              color: AppTheme.primaryYellow)),
          const SizedBox(height: 16),
        ],
        if (tips.isNotEmpty) ...[
          const Text('نصائح',
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...tips.map((t) => _BulletItem(text: t, icon: Icons.tips_and_updates,
              color: AppTheme.primaryGreen)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _BulletItem(
      {required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DuolingoCard(
        padding: const EdgeInsets.all(12),
        borderColor: color,
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ),
          ],
        ),
      ),
    );
  }
}
