import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/parent_provider.dart';

class ChildProgressScreen extends StatefulWidget {
  const ChildProgressScreen({super.key});

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final childId = ModalRoute.of(context)!.settings.arguments as int;
      context.read<ParentProvider>().loadChildDetail(childId);
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تقدم الطفل')),
        body: Consumer<ParentProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.childDetail == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && provider.childDetail == null) {
              return Center(
                child: Text(provider.error!,
                    style: const TextStyle(fontFamily: 'Cairo')),
              );
            }
            final s = provider.childDetail;
            if (s == null) return const SizedBox.shrink();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Child header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            AppTheme.primaryGreen.withValues(alpha: 0.1),
                        child: Text(
                          s.fullName.isNotEmpty ? s.fullName[0] : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.fullName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'الصف ${s.gradeLevel}',
                        style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: AppTheme.textGray),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Badge(
                              label: 'النقاط',
                              value: '${s.totalPoints}',
                              color: AppTheme.primaryYellow),
                          _Badge(
                              label: 'السلسلة',
                              value: '${s.currentStreak}',
                              color: AppTheme.primaryOrange),
                          _Badge(
                              label: 'الإتقان',
                              value: '${s.overallMastery.toStringAsFixed(0)}%',
                              color: AppTheme.primaryGreen),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats summary
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'ملخص الأداء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Row(label: 'دروس مكتملة', value: '${s.lessonsCompleted}'),
                      _Row(label: 'دروس قيد التقدم', value: '${s.lessonsInProgress}'),
                      _Row(label: 'محاولات الاختبار', value: '${s.totalAttempts}'),
                      _Row(
                          label: 'معدل الدرجات',
                          value: '${s.averageScore.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Subject breakdown
                const Text(
                  'التقدم حسب المادة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...s.subjectBreakdown.map((sub) {
                  final progress = sub.totalLessons > 0
                      ? sub.lessonsCompleted / sub.totalLessons
                      : 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(sub.subjectName,
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '${sub.averageMastery.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor:
                                AppTheme.primaryGreen.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryGreen),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${sub.lessonsCompleted} / ${sub.totalLessons} درس',
                          style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppTheme.textGray),
                        ),
                      ],
                    ),
                  );
                }),
                if (s.subjectBreakdown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('لا توجد بيانات حتى الآن',
                          style: TextStyle(
                              fontFamily: 'Cairo', color: AppTheme.textGray)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Badge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textGray)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Cairo', fontSize: 14, color: AppTheme.textGray)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
