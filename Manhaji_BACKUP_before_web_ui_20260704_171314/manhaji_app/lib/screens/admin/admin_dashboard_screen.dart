import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/admin_stats.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/vibrant_background.dart';
import '../../widgets/loading_state.dart';
import '../question_bank/question_bank_subjects_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
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
          child: Consumer<AdminProvider>(
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
                child: _AdminDashboardContent(
                  stats: stats,
                  users: provider.users,
                  isLoadingUsers: provider.isLoading && provider.users == null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  final AdminStats stats;
  final List<UserSummary>? users;
  final bool isLoadingUsers;

  const _AdminDashboardContent({
    required this.stats,
    required this.users,
    required this.isLoadingUsers,
  });

  @override
  Widget build(BuildContext context) {
    final totalUsers =
        stats.totalStudents +
        stats.totalTeachers +
        stats.totalParents +
        stats.totalAdmins;
    final activeUsers = users?.where((user) => user.isActive).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 1040
            ? 1040.0
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: maxWidth,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                _AdminHeader(totalUsers: totalUsers, activeUsers: activeUsers),
                const SizedBox(height: 18),
                const _SectionHeader(title: 'المستخدمون'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.people_rounded,
                      color: AppTheme.primaryBlue,
                      title: 'الطلاب',
                      value: '${stats.totalStudents}',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.school_rounded,
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
                      icon: Icons.family_restroom_rounded,
                      color: AppTheme.primaryOrange,
                      title: 'أولياء الأمور',
                      value: '${stats.totalParents}',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.admin_panel_settings_rounded,
                      color: AppTheme.primaryPurple,
                      title: 'المشرفون',
                      value: '${stats.totalAdmins}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionHeader(title: 'المحتوى والتفاعل'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.menu_book_rounded,
                      color: AppTheme.primaryBlue,
                      title: 'المواد',
                      value: '${stats.totalSubjects}',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.library_books_rounded,
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
                      icon: Icons.quiz_rounded,
                      color: AppTheme.primaryYellowDeep,
                      title: 'اختبارات مكتملة',
                      value: '${stats.totalAttempts}',
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.primaryGreen,
                      title: 'دروس مكتملة',
                      value: '${stats.totalCompletedLessons}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActiveStudentsCard(value: stats.activeStudentsThisWeek),
                const SizedBox(height: 20),
                const _SectionHeader(title: 'إجراءات الإدارة'),
                const SizedBox(height: 10),
                _NavTile(
                  icon: Icons.manage_accounts_rounded,
                  accentColor: AppTheme.primaryBlue,
                  title: 'إدارة المستخدمين',
                  subtitle:
                      'أضف أو عدّل أو احذف الطلاب والمعلمين وأولياء الأمور',
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminManageUsers),
                ),
                const SizedBox(height: 10),
                _NavTile(
                  icon: Icons.quiz_rounded,
                  accentColor: AppTheme.primaryGreen,
                  title: 'بنك الأسئلة',
                  subtitle: 'استعرض أسئلة جميع المواد عبر كل الصفوف',
                  onTap: () => context.openAdminQuestionBank(),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'آخر المستخدمين'),
                const SizedBox(height: 10),
                _RecentUsersSection(users: users, isLoading: isLoadingUsers),
                const SizedBox(height: 20),
                const _SectionHeader(title: 'أقسام تحتاج بيانات إضافية'),
                const SizedBox(height: 10),
                const _AdminEmptyCard(
                  icon: Icons.apartment_rounded,
                  title: 'إحصاءات المدارس والاشتراكات غير متاحة',
                  message:
                      'سيتم عرضها عندما يوفر الخادم بيانات المدارس والاشتراكات.',
                ),
                const SizedBox(height: 10),
                const _AdminEmptyCard(
                  icon: Icons.fact_check_rounded,
                  title: 'مراجعة المحتوى غير متاحة حالياً',
                  message:
                      'لا يوجد endpoint حالي لقائمة اعتماد المحتوى داخل لوحة المشرف.',
                ),
                const SizedBox(height: 10),
                const _AdminEmptyCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'سجل النشاط غير متاح حالياً',
                  message:
                      'سيظهر ملخص السجلات عند توفر بيانات audit/activity من الخادم.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final int totalUsers;
  final int? activeUsers;

  const _AdminHeader({required this.totalUsers, required this.activeUsers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppTheme.primaryPurple,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لوحة المشرف',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activeUsers == null
                      ? 'إجمالي المستخدمين: $totalUsers'
                      : 'إجمالي المستخدمين: $totalUsers • النشطون: $activeUsers',
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
        ],
      ),
    );
  }
}

class _ActiveStudentsCard extends StatelessWidget {
  final int value;

  const _ActiveStudentsCard({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.trending_up_rounded,
            color: AppTheme.primaryBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'طلاب نشطون هذا الأسبوع: $value',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentUsersSection extends StatelessWidget {
  final List<UserSummary>? users;
  final bool isLoading;

  const _RecentUsersSection({required this.users, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _AdminEmptyCard(
        icon: Icons.hourglass_top_rounded,
        title: 'جاري تحميل المستخدمين',
        message: 'يتم جلب قائمة المستخدمين من الخادم.',
      );
    }

    final list = users ?? const [];
    if (list.isEmpty) {
      return const _AdminEmptyCard(
        icon: Icons.people_outline_rounded,
        title: 'لا توجد بيانات مستخدمين',
        message: 'ستظهر آخر الحسابات هنا بعد تحميلها من الخادم.',
      );
    }

    return Column(
      children: [for (final user in list.take(10)) _UserTile(user: user)],
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserSummary user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(radius: 14),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.1),
          child: Icon(_roleIcon(user.role), color: roleColor, size: 20),
        ),
        title: Text(
          user.fullName.trim().isEmpty ? 'مستخدم بدون اسم' : user.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          '${_roleLabel(user.role)}  •  ${user.email ?? user.phone ?? "لا توجد وسيلة تواصل"}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
        ),
        trailing: _StatusBadge(
          label: user.isActive ? 'نشط' : 'موقوف',
          color: user.isActive ? AppTheme.primaryGreen : AppTheme.primaryRed,
        ),
      ),
    );
  }
}

class _AdminEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _AdminEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.textLight, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
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
                    height: 1.45,
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 19,
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

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AppTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: AppTheme.textGray,
              ),
            ],
          ),
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

BoxDecoration _cardDecoration({double radius = AppTheme.radiusL}) {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: AppTheme.elevationLow,
    border: Border.all(color: AppTheme.surfaceSubtle, width: 1),
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
