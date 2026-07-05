import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/route_args.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/parent_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parent_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/vibrant_background.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ParentProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة ولي الأمر'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              },
            ),
          ],
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: Consumer<ParentProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.dashboard == null) {
                return const LoadingState();
              }
              if (provider.error != null && provider.dashboard == null) {
                return ErrorState(
                  message: provider.error!,
                  onRetry: provider.loadDashboard,
                );
              }

              final dash = provider.dashboard;
              if (dash == null) return const SizedBox.shrink();

              return RefreshIndicator(
                onRefresh: () => provider.loadDashboard(),
                child: _ParentDashboardContent(
                  dashboard: dash,
                  onOpenChild: (studentId) => Navigator.pushNamed(
                    context,
                    AppRoutes.childProgress,
                    arguments: ChildProgressArgs(studentId),
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

class _ParentDashboardContent extends StatelessWidget {
  final ParentDashboard dashboard;
  final ValueChanged<int> onOpenChild;

  const _ParentDashboardContent({
    required this.dashboard,
    required this.onOpenChild,
  });

  @override
  Widget build(BuildContext context) {
    final children = dashboard.children;
    final summary = _AnalyticsSummary.fromDashboard(dashboard);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        _DashboardHeader(parentName: dashboard.fullName),
        const SizedBox(height: 20),
        if (children.isEmpty)
          const _EmptyChildrenCard()
        else ...[
          for (final child in children)
            _ChildOverviewCard(
              child: child,
              hasAttention: dashboard.alerts
                  .any((a) => a.studentId == child.studentId),
              onDetails: () => onOpenChild(child.studentId),
            ),
          const SizedBox(height: 8),
          const _SectionTitle(
            title: 'لمحة تحليلية',
            subtitle: 'ملخص عام مبني على بيانات الأطفال المرتبطين بحسابك',
          ),
          const SizedBox(height: 10),
          _AnalyticsSummaryGrid(summary: summary),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'نتائج الاختبارات الأخيرة'),
          const SizedBox(height: 10),
          _RecentActivitySection(
              activities: dashboard.recentActivityAcrossChildren),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'أطفال يحتاجون متابعة'),
          const SizedBox(height: 10),
          _ChildrenNeedingAttention(children: children, alerts: dashboard.alerts),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'توصيات منزلية'),
          const SizedBox(height: 10),
          _HomeRecommendations(recommendations: dashboard.recommendations),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'الإشعارات والتنبيهات'),
          const SizedBox(height: 10),
          _AlertsSection(alerts: dashboard.alerts),
        ],
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String parentName;

  const _DashboardHeader({required this.parentName});

  @override
  Widget build(BuildContext context) {
    final displayName = parentName.trim().isEmpty ? 'ولي الأمر' : parentName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'لوحة ولي الأمر',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'مرحباً، $displayName',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
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
  final ChildSummary child;
  final bool hasAttention;
  final VoidCallback onDetails;

  const _ChildOverviewCard({
    required this.child,
    required this.hasAttention,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _lessonProgress(
      child.lessonsCompleted,
      child.totalLessons,
      fallbackPercent: child.overallMastery,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.elevationMedium,
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.14),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                child: Text(
                  _initial(child.fullName),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 25,
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
                      child.fullName.trim().isEmpty
                          ? 'طفل بدون اسم'
                          : child.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الصف ${child.gradeLevel}',
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
              _StatusBadge(
                label: _progressStatus(child.overallMastery),
                color: _statusColor(child.overallMastery),
              ),
            ],
          ),
          if (hasAttention) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.priority_high_rounded,
                    color: AppTheme.primaryOrangeDeep,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'يحتاج بعض المتابعة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryOrangeDeep,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InlineMetric(
                  icon: Icons.local_fire_department_rounded,
                  label: 'السلسلة',
                  value: '${child.currentStreak} أيام',
                  color: AppTheme.primaryOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineMetric(
                  icon: Icons.star_rounded,
                  label: 'النقاط',
                  value: '${child.totalPoints}',
                  color: AppTheme.primaryYellowDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InlineMetric(
                  icon: Icons.check_circle_rounded,
                  label: 'الدروس',
                  value: '${child.lessonsCompleted}/${child.totalLessons}',
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineMetric(
                  icon: Icons.history_rounded,
                  label: 'آخر نشاط',
                  value: _formatLastActivity(child.lastLoginAt),
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.10,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
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

class _AnalyticsSummaryGrid extends StatelessWidget {
  final _AnalyticsSummary summary;

  const _AnalyticsSummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.family_restroom_rounded,
                title: 'عدد الأطفال',
                value: '${summary.childCount}',
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.wifi_tethering_rounded,
                title: 'أطفال نشطون هذا الأسبوع',
                value: '${summary.activeChildren}',
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.tips_and_updates_rounded,
                title: 'يحتاجون متابعة',
                value: '${summary.attentionCount}',
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.school_rounded,
                title: 'متوسط الإتقان',
                value: summary.hasChildren
                    ? '${summary.averageMastery.toStringAsFixed(0)}%'
                    : 'بلا بيانات بعد',
                color: AppTheme.primaryPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.fact_check_rounded,
                title: 'اختبارات مصححة حديثاً',
                value: '${summary.recentGradedAttemptsCount}',
                color: AppTheme.primaryGreenDeep,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.event_available_rounded,
                title: 'آخر نشاط مسجل',
                value: summary.latestActivityLabel,
                color: AppTheme.primaryBlueDeep,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
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
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.elevationLow,
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 25),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _ChildrenNeedingAttention extends StatelessWidget {
  final List<ChildSummary> children;
  final List<ParentAlert> alerts;

  const _ChildrenNeedingAttention({required this.children, required this.alerts});

  @override
  Widget build(BuildContext context) {
    final needingSupport = children
        .where((child) => alerts.any((a) => a.studentId == child.studentId))
        .toList();
    if (needingSupport.isEmpty) {
      return const _DashboardDataPlaceholder(
        icon: Icons.psychology_alt_rounded,
        title: 'لا توجد مؤشرات متابعة حرجة',
        message: 'كل الأطفال المرتبطين بحسابك يسيرون بشكل جيد حالياً.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < needingSupport.length; i++) ...[
            _AttentionChildTile(
              child: needingSupport[i],
              childAlerts: alerts
                  .where((a) => a.studentId == needingSupport[i].studentId)
                  .toList(),
            ),
            if (i != needingSupport.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _AttentionChildTile extends StatelessWidget {
  final ChildSummary child;
  final List<ParentAlert> childAlerts;

  const _AttentionChildTile({
    required this.child,
    required this.childAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.flag_rounded, color: AppTheme.primaryOrange, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      child.fullName.trim().isEmpty
                          ? 'طفل بدون اسم'
                          : child.fullName,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    label: '${child.overallMastery.toStringAsFixed(0)}%',
                    color: AppTheme.primaryOrange,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final alert in childAlerts)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '• ${alert.message}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardDataPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _DashboardDataPlaceholder({
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
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGray,
                    height: 1.5,
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

class _EmptyChildrenCard extends StatelessWidget {
  const _EmptyChildrenCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.child_care_rounded, size: 58, color: AppTheme.textLight),
          SizedBox(height: 12),
          Text(
            'لا يوجد أطفال مرتبطين بحسابك بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

class _AnalyticsSummary {
  final bool hasChildren;
  final int childCount;
  final int activeChildren;
  final int attentionCount;
  final double averageMastery;
  final int recentGradedAttemptsCount;
  final String latestActivityLabel;

  const _AnalyticsSummary({
    required this.hasChildren,
    required this.childCount,
    required this.activeChildren,
    required this.attentionCount,
    required this.averageMastery,
    required this.recentGradedAttemptsCount,
    required this.latestActivityLabel,
  });

  factory _AnalyticsSummary.fromDashboard(ParentDashboard dashboard) {
    final children = dashboard.children;
    final recentCount = dashboard.recentActivityAcrossChildren.length;

    if (children.isEmpty) {
      return _AnalyticsSummary(
        hasChildren: false,
        childCount: 0,
        activeChildren: 0,
        attentionCount: 0,
        averageMastery: 0,
        recentGradedAttemptsCount: recentCount,
        latestActivityLabel: 'لا يوجد نشاط مسجل بعد',
      );
    }

    final now = DateTime.now();
    var active = 0;
    DateTime? latest;
    for (final child in children) {
      final parsed = DateTime.tryParse(child.lastLoginAt ?? '');
      if (parsed == null) continue;
      if (latest == null || parsed.isAfter(latest)) latest = parsed;
      if (now.difference(parsed).inDays <= 7) active++;
    }

    final attentionCount = dashboard.alerts
        .where((a) => a.studentId != null)
        .map((a) => a.studentId)
        .toSet()
        .length;

    final averageMastery =
        children.fold<double>(0, (sum, child) => sum + child.overallMastery) /
            children.length;

    return _AnalyticsSummary(
      hasChildren: true,
      childCount: children.length,
      activeChildren: active,
      attentionCount: attentionCount,
      averageMastery: averageMastery,
      recentGradedAttemptsCount: recentCount,
      latestActivityLabel: latest == null
          ? 'لا يوجد نشاط مسجل بعد'
          : _formatLastActivity(latest.toIso8601String()),
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

double _lessonProgress(
  int completed,
  int total, {
  required double fallbackPercent,
}) {
  if (total > 0) {
    return (completed / total).clamp(0.0, 1.0).toDouble();
  }
  return (fallbackPercent / 100).clamp(0.0, 1.0).toDouble();
}

String _formatLastActivity(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'لا يوجد نشاط';
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final now = DateTime.now();
  final diff = now.difference(parsed);
  if (diff.inDays <= 0) return 'اليوم';
  if (diff.inDays == 1) return 'أمس';
  if (diff.inDays < 7) return 'قبل ${diff.inDays} أيام';
  return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
}

String _progressStatus(double mastery) {
  if (mastery >= 80) return 'ممتاز';
  if (mastery >= 60) return 'جيد';
  if (mastery > 0) return 'يحتاج دعم';
  return 'بانتظار بيانات';
}

Color _statusColor(double mastery) {
  if (mastery >= 80) return AppTheme.primaryGreen;
  if (mastery >= 60) return AppTheme.primaryBlue;
  if (mastery > 0) return AppTheme.primaryOrange;
  return AppTheme.textGray;
}

class _RecentActivitySection extends StatelessWidget {
  final List<QuizAttemptSummary> activities;

  const _RecentActivitySection({required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const _DashboardDataPlaceholder(
        icon: Icons.quiz_rounded,
        title: 'لا توجد نتائج اختبارات حديثة بعد',
        message: 'عندما يكمل الطفل اختباراً ستظهر هنا النتيجة والمادة.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < activities.length; i++) ...[
            _AttemptTile(activity: activities[i]),
            if (i != activities.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  final QuizAttemptSummary activity;

  const _AttemptTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final score = activity.score;
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
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.quiz_rounded, color: scoreColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.quizTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
              if (activity.subjectName != null || activity.lessonTitle != null)
                Text(
                  [activity.subjectName, activity.lessonTitle]
                      .whereType<String>()
                      .join(' — '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        const SizedBox(width: 8),
        _StatusBadge(
          label: score != null ? '${score.toStringAsFixed(0)}%' : 'قيد التقدم',
          color: scoreColor,
        ),
      ],
    );
  }
}

class _AlertsSection extends StatelessWidget {
  final List<ParentAlert> alerts;

  const _AlertsSection({required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const _DashboardDataPlaceholder(
        icon: Icons.notifications_none_rounded,
        title: 'لا توجد تنبيهات جديدة',
        message: 'ستظهر التنبيهات هنا عند حدوث تغييرات في تقدم الأطفال.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < alerts.length; i++) ...[
            _AlertTile(alert: alerts[i]),
            if (i != alerts.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final ParentAlert alert;

  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final isHigh = alert.severity == 'HIGH';
    final color = isHigh ? AppTheme.primaryRed : AppTheme.primaryOrange;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isHigh ? Icons.warning_rounded : Icons.info_outline_rounded,
          color: color,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            alert.message,
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

class _HomeRecommendations extends StatelessWidget {
  final List<ParentRecommendation> recommendations;

  const _HomeRecommendations({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const _DashboardDataPlaceholder(
        icon: Icons.home_work_rounded,
        title: 'لا توجد توصيات حالياً',
        message: 'أطفالك يسيرون بشكل جيد! ستظهر التوصيات هنا عند الحاجة لمتابعة إضافية.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < recommendations.length; i++) ...[
            _DashboardRecommendationTile(recommendation: recommendations[i]),
            if (i != recommendations.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _DashboardRecommendationTile extends StatelessWidget {
  final ParentRecommendation recommendation;

  const _DashboardRecommendationTile({required this.recommendation});

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
