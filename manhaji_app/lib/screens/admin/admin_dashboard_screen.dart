import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final admin = context.read<AdminProvider>();
      admin.loadStats();
      admin.loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المشرف'),
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
        body: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.stats == null) {
              return const LoadingState();
            }
            if (provider.error != null && provider.stats == null) {
              return ErrorState(
                message: provider.error!,
                onRetry: () {
                  provider.loadStats();
                  provider.loadUsers();
                },
              );
            }
            final stats = provider.stats;
            if (stats == null) return const SizedBox.shrink();

            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadStats();
                await provider.loadUsers();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'إحصائيات النظام',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Users grid
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.people,
                        color: AppTheme.primaryBlue,
                        title: 'الطلاب',
                        value: '${stats.totalStudents}',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.school,
                        color: AppTheme.primaryGreen,
                        title: 'المعلمون',
                        value: '${stats.totalTeachers}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.family_restroom,
                        color: AppTheme.primaryOrange,
                        title: 'أولياء الأمور',
                        value: '${stats.totalParents}',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.admin_panel_settings,
                        color: AppTheme.primaryPurple,
                        title: 'المشرفون',
                        value: '${stats.totalAdmins}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Content stats
                  const Text(
                    'المحتوى التعليمي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.menu_book,
                        color: AppTheme.primaryBlue,
                        title: 'المواد',
                        value: '${stats.totalSubjects}',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.library_books,
                        color: AppTheme.primaryGreen,
                        title: 'الدروس',
                        value: '${stats.totalLessons}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.quiz,
                        color: AppTheme.primaryYellow,
                        title: 'اختبارات مكتملة',
                        value: '${stats.totalAttempts}',
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.check_circle,
                        color: AppTheme.primaryGreen,
                        title: 'دروس مكتملة',
                        value: '${stats.totalCompletedLessons}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up,
                            color: AppTheme.primaryBlue, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'طلاب نشطون هذا الأسبوع: ${stats.activeStudentsThisWeek}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent users list
                  const Text(
                    'المستخدمون',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (provider.users != null)
                    ...provider.users!.take(10).map((u) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _roleColor(u.role)
                                  .withValues(alpha: 0.1),
                              child: Icon(_roleIcon(u.role),
                                  color: _roleColor(u.role), size: 20),
                            ),
                            title: Text(u.fullName,
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${_roleLabel(u.role)}  •  ${u.email ?? u.phone ?? ""}',
                              style: const TextStyle(
                                  fontFamily: 'Cairo', fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: u.isActive
                                    ? AppTheme.primaryGreen
                                        .withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                u.isActive ? 'نشط' : 'غير نشط',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  color: u.isActive
                                      ? AppTheme.primaryGreen
                                      : Colors.red,
                                ),
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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

  Color _roleColor(String role) {
    return switch (role) {
      'STUDENT' => AppTheme.primaryBlue,
      'TEACHER' => AppTheme.primaryGreen,
      'PARENT' => AppTheme.primaryOrange,
      'ADMIN' => AppTheme.primaryPurple,
      _ => AppTheme.textGray,
    };
  }

  IconData _roleIcon(String role) {
    return switch (role) {
      'STUDENT' => Icons.person,
      'TEACHER' => Icons.school,
      'PARENT' => Icons.family_restroom,
      'ADMIN' => Icons.admin_panel_settings,
      _ => Icons.person,
    };
  }

  String _roleLabel(String role) {
    return switch (role) {
      'STUDENT' => 'طالب',
      'TEACHER' => 'معلم',
      'PARENT' => 'ولي أمر',
      'ADMIN' => 'مشرف',
      _ => role,
    };
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
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
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
