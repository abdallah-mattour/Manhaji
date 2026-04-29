import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/teacher_provider.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final studentId = ModalRoute.of(context)!.settings.arguments as int;
      context.read<TeacherProvider>().loadStudentDetail(studentId);
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('بيانات الطالب')),
        body: Consumer<TeacherProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.studentDetail == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.error != null && provider.studentDetail == null) {
              return Center(
                child: Text(provider.error!,
                    style: const TextStyle(fontFamily: 'Cairo')),
              );
            }
            final s = provider.studentDetail;
            if (s == null) return const SizedBox.shrink();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile header
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
                            AppTheme.primaryBlue.withValues(alpha: 0.1),
                        child: Text(
                          s.fullName.isNotEmpty ? s.fullName[0] : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
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
                      if (s.email != null)
                        Text(s.email!,
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: AppTheme.textGray)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InfoBadge(
                              label: 'النقاط', value: '${s.totalPoints}'),
                          _InfoBadge(
                              label: 'السلسلة', value: '${s.currentStreak}'),
                          _InfoBadge(
                              label: 'الصف', value: '${s.gradeLevel}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Overall performance
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
                        'الأداء العام',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PerformanceRow(
                          label: 'الإتقان الكلي',
                          value: '${s.overallMastery.toStringAsFixed(1)}%'),
                      _PerformanceRow(
                          label: 'دروس مكتملة',
                          value: '${s.lessonsCompleted}'),
                      _PerformanceRow(
                          label: 'دروس قيد التقدم',
                          value: '${s.lessonsInProgress}'),
                      _PerformanceRow(
                          label: 'محاولات الاختبار',
                          value: '${s.totalAttempts}'),
                      _PerformanceRow(
                          label: 'معدل الدرجات',
                          value:
                              '${s.averageScore.toStringAsFixed(1)}%'),
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
                ...s.subjectBreakdown.map((sub) => _SubjectCard(
                      name: sub.subjectName,
                      mastery: sub.averageMastery,
                      completed: sub.lessonsCompleted,
                      total: sub.totalLessons,
                    )),
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

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen)),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textGray)),
      ],
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final String label;
  final String value;

  const _PerformanceRow({required this.label, required this.value});

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

class _SubjectCard extends StatelessWidget {
  final String name;
  final double mastery;
  final int completed;
  final int total;

  const _SubjectCard({
    required this.name,
    required this.mastery,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;

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
              Text(name,
                  style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              Text('${mastery.toStringAsFixed(0)}%',
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
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$completed / $total درس',
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textGray),
          ),
        ],
      ),
    );
  }
}
