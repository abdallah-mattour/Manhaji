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
          pattern: BackgroundPattern.shapes,
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
                    : () => provider.generateReport(),
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

            // Reports list
            Expanded(
              child: provider.isLoading && provider.reports == null
                  ? const Center(child: CircularProgressIndicator())
                  : (provider.reports == null || provider.reports!.isEmpty)
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.assessment_outlined,
                                    size: 60, color: AppTheme.textLight),
                                SizedBox(height: 12),
                                Text(
                                  'لا توجد تقارير بعد\nاضغط الزر أعلاه لإنشاء أول تقرير',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: AppTheme.textGray),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.reports!.length,
                          itemBuilder: (context, index) {
                            final report = provider.reports![index];
                            return _ReportCard(report: report);
                          },
                        ),
            ),
          ],
        );
      },
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
              report.summary,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                height: 1.5,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
                    : () => provider.generateLearningPath(),
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
