import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/parent_dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parent_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
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
        body: Consumer<ParentProvider>(
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
                  const SizedBox(height: 4),
                  Text(
                    'تابع تقدم ${dash.children.length == 1 ? "طفلك" : "أطفالك"} الدراسي',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (dash.children.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.child_care,
                              size: 60, color: AppTheme.textLight),
                          SizedBox(height: 12),
                          Text(
                            'لا يوجد أطفال مرتبطين بحسابك بعد',
                            style: TextStyle(
                                fontFamily: 'Cairo', color: AppTheme.textGray),
                          ),
                        ],
                      ),
                    ),

                  ...dash.children.map((child) => _ChildCard(
                        child: child,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.childProgress,
                          arguments: child.studentId,
                        ),
                      )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final ChildSummary child;
  final VoidCallback onTap;

  const _ChildCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress =
        child.totalLessons > 0 ? child.lessonsCompleted / child.totalLessons : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.1),
                    child: Text(
                      child.fullName.isNotEmpty ? child.fullName[0] : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
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
                          child.fullName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'الصف ${child.gradeLevel}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios, size: 16,
                      color: AppTheme.textGray),
                ],
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(
                      icon: Icons.star,
                      label: 'النقاط',
                      value: '${child.totalPoints}',
                      color: AppTheme.primaryYellow),
                  _MiniStat(
                      icon: Icons.local_fire_department,
                      label: 'السلسلة',
                      value: '${child.currentStreak}',
                      color: AppTheme.primaryOrange),
                  _MiniStat(
                      icon: Icons.school,
                      label: 'الإتقان',
                      value: '${child.overallMastery.toStringAsFixed(0)}%',
                      color: AppTheme.primaryPurple),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
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
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${child.lessonsCompleted}/${child.totalLessons}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textGray)),
      ],
    );
  }
}
