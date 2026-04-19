import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/teacher_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<TeacherProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المعلم'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthProvider>().logout();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              },
            ),
          ],
        ),
        body: Consumer<TeacherProvider>(
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome
                  Text(
                    'مرحباً، ${dash.fullName}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (dash.department != null)
                    Text(
                      dash.department!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: AppTheme.textGray,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Stats cards
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.people,
                        color: AppTheme.primaryBlue,
                        title: 'الطلاب',
                        value: '${dash.totalStudents}',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.trending_up,
                        color: AppTheme.primaryGreen,
                        title: 'نشطون هذا الأسبوع',
                        value: '${dash.activeThisWeek}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.check_circle_outline,
                        color: AppTheme.primaryPurple,
                        title: 'دروس مكتملة',
                        value: '${dash.lessonsCompletedTotal}',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.school,
                        color: AppTheme.primaryOrange,
                        title: 'متوسط الإتقان',
                        value: '${dash.averageMasteryAcrossClass.toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Top students
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'أفضل الطلاب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, AppRoutes.classStudents),
                        child: const Text(
                          'عرض الكل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...dash.topStudents.map((student) => _StudentTile(
                        student: student,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.teacherStudentDetail,
                          arguments: student.studentId,
                        ),
                      )),
                  if (dash.topStudents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('لا يوجد طلاب حالياً',
                            style: TextStyle(
                                fontFamily: 'Cairo', color: AppTheme.textGray)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final ClassStudentSummary student;
  final VoidCallback onTap;

  const _StudentTile({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          child: Text(
            student.fullName.isNotEmpty ? student.fullName[0] : '?',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'النقاط: ${student.totalPoints}  •  الإتقان: ${student.averageMastery.toStringAsFixed(0)}%',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_back_ios, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
