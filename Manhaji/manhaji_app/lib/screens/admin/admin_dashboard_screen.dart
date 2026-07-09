import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/admin_stats.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/staff_metric_card.dart';
import '../../widgets/staff_web_shell.dart';
import 'admin_shell_navigation.dart';

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
      _load(context.read<AdminProvider>());
    });
  }

  Future<void> _load(AdminProvider provider) async {
    await provider.loadStats();
    if (provider.stats == null) return;
    await provider.loadUsers();
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    await auth.logout();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: 'لوحة التحكم',
        subtitle: 'نظرة شاملة على المستخدمين والمحتوى من بيانات الخادم',
        roleLabel: 'مساحة المشرف',
        currentRoute: AppRoutes.adminDashboard,
        items: adminShellItems(context),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _load(context.read<AdminProvider>()),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
        child: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.stats == null) {
              return const LoadingState();
            }

            if (provider.error != null && provider.stats == null) {
              return ErrorState(
                message: provider.error!,
                onRetry: () => _load(provider),
              );
            }

            final stats = provider.stats;
            if (stats == null) {
              return ErrorState(
                message: 'لا توجد بيانات لوحة التحكم حالياً.',
                onRetry: () => _load(provider),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _load(provider),
              child: _AdminDashboardContent(
                stats: stats,
                users: provider.users,
                isLoadingUsers: provider.isLoading && provider.users == null,
                usersError: provider.users == null ? provider.error : null,
                onRefresh: () => _load(provider),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent({
    required this.stats,
    required this.users,
    required this.isLoadingUsers,
    required this.usersError,
    required this.onRefresh,
  });

  final AdminStats stats;
  final List<UserSummary>? users;
  final bool isLoadingUsers;
  final String? usersError;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final totalUsers =
        stats.totalStudents +
        stats.totalTeachers +
        stats.totalParents +
        stats.totalAdmins;
    final activeUsers = users?.where((user) => user.isActive).length;
    final inactiveUsers = users == null ? null : users!.length - activeUsers!;
    final quality = _DataQualitySummary.fromUsers(users);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space6),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1320),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DashboardSummaryBand(
                  totalUsers: totalUsers,
                  activeUsers: activeUsers,
                  activeStudentsThisWeek: stats.activeStudentsThisWeek,
                ),
                const SizedBox(height: AppTheme.space6),
                const _SectionHeading(
                  title: 'مؤشرات المنصة',
                  subtitle:
                      'الأرقام الحالية كما وصلت من لوحة المشرف في الخادم.',
                ),
                const SizedBox(height: AppTheme.space4),
                _MetricsGrid(cards: _metricCards(context, stats, totalUsers)),
                const SizedBox(height: AppTheme.space5),
                const _SectionHeading(
                  title: 'جودة البيانات',
                  subtitle: 'تنبيهات مشتقة من قائمة المستخدمين المحملة فقط.',
                ),
                const SizedBox(height: AppTheme.space4),
                _DataQualityGrid(
                  summary: quality,
                  onOpenUsers: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminManageUsers),
                ),
                const SizedBox(height: AppTheme.space5),
                _DashboardColumns(
                  primary: _RecentUsersPanel(
                    users: users,
                    isLoading: isLoadingUsers,
                    error: usersError,
                    onRetry: onRefresh,
                  ),
                  insights: [
                    _RoleDistributionPanel(
                      stats: stats,
                      totalUsers: totalUsers,
                    ),
                    _AccountStatusPanel(
                      totalUsers: totalUsers,
                      activeUsers: activeUsers,
                      inactiveUsers: inactiveUsers,
                    ),
                    _ContentSnapshotPanel(stats: stats),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _metricCards(
    BuildContext context,
    AdminStats stats,
    int totalUsers,
  ) {
    void openUsers() =>
        Navigator.of(context).pushNamed(AppRoutes.adminManageUsers);

    return [
      StaffMetricCard(
        title: 'إجمالي المستخدمين',
        value: '$totalUsers',
        subtitle: 'كل الحسابات المسجلة',
        icon: Icons.groups_rounded,
        color: AppTheme.primaryBlue,
        onTap: openUsers,
      ),
      StaffMetricCard(
        title: 'الطلاب',
        value: '${stats.totalStudents}',
        subtitle: 'حسابات الطلاب',
        icon: Icons.person_rounded,
        color: AppTheme.primaryGreen,
        onTap: openUsers,
      ),
      StaffMetricCard(
        title: 'المعلمون',
        value: '${stats.totalTeachers}',
        subtitle: 'حسابات المعلمين',
        icon: Icons.school_rounded,
        color: AppTheme.primaryTerracotta,
        onTap: openUsers,
      ),
      StaffMetricCard(
        title: 'أولياء الأمور',
        value: '${stats.totalParents}',
        subtitle: 'حسابات العائلات',
        icon: Icons.family_restroom_rounded,
        color: AppTheme.primaryOrange,
        onTap: openUsers,
      ),
      StaffMetricCard(
        title: 'المشرفون',
        value: '${stats.totalAdmins}',
        subtitle: 'حسابات الإدارة',
        icon: Icons.admin_panel_settings_rounded,
        color: AppTheme.primaryPurple,
        onTap: openUsers,
      ),
      StaffMetricCard(
        title: 'المواد',
        value: '${stats.totalSubjects}',
        subtitle: 'المواد المتاحة',
        icon: Icons.menu_book_rounded,
        color: AppTheme.primaryBlueDeep,
        onTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminQuestionBank),
      ),
      StaffMetricCard(
        title: 'الدروس',
        value: '${stats.totalLessons}',
        subtitle: 'الدروس المنشورة',
        icon: Icons.library_books_rounded,
        color: AppTheme.primaryGreenDeep,
        onTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminQuestionBank),
      ),
      // «محاولات الاختبار» و«دروس مكتملة» تبقيان غير قابلتين للنقر:
      // لا توجد صفحة أدمن آمنة لعرض المحاولات أو الإنجازات حالياً.
      StaffMetricCard(
        title: 'محاولات الاختبار',
        value: '${stats.totalAttempts}',
        subtitle: 'محاولات مكتملة',
        icon: Icons.assignment_turned_in_rounded,
        color: AppTheme.primaryYellowDeep,
      ),
      StaffMetricCard(
        title: 'دروس مكتملة',
        value: '${stats.totalCompletedLessons}',
        subtitle: 'إنجازات الطلاب',
        icon: Icons.check_circle_rounded,
        color: AppTheme.primaryRed,
      ),
    ];
  }
}

class _DashboardSummaryBand extends StatelessWidget {
  const _DashboardSummaryBand({
    required this.totalUsers,
    required this.activeUsers,
    required this.activeStudentsThisWeek,
  });

  final int totalUsers;
  final int? activeUsers;
  final int activeStudentsThisWeek;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: _panelDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final headline = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إدارة المنصة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppTheme.space2),
              Text(
                'إجمالي المستخدمين: $totalUsers',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textGray,
                  height: 1.45,
                ),
              ),
            ],
          );
          final facts = Wrap(
            spacing: AppTheme.space3,
            runSpacing: AppTheme.space3,
            children: [
              _SummaryPill(
                label: 'الحسابات النشطة',
                value: activeUsers == null ? 'غير متوفر' : '$activeUsers',
                color: AppTheme.primaryGreen,
              ),
              _SummaryPill(
                label: 'طلاب نشطون هذا الأسبوع',
                value: '$activeStudentsThisWeek',
                color: AppTheme.primaryBlue,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headline,
                const SizedBox(height: AppTheme.space4),
                facts,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: headline),
              const SizedBox(width: AppTheme.space5),
              Flexible(child: facts),
            ],
          );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppTheme.space4;
        final width = constraints.maxWidth;
        final columns = width >= 1160
            ? 4
            : width >= 860
            ? 3
            : width >= 560
            ? 2
            : 1;
        final itemWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }
}

class _DataQualitySummary {
  const _DataQualitySummary({
    required this.isAvailable,
    this.parentsWithoutChildren,
    this.studentsWithoutParent,
    this.teachersWithoutMaterials,
  });

  final bool isAvailable;
  final int? parentsWithoutChildren;
  final int? studentsWithoutParent;
  final int? teachersWithoutMaterials;

  factory _DataQualitySummary.fromUsers(List<UserSummary>? users) {
    if (users == null) {
      return const _DataQualitySummary(isAvailable: false);
    }

    final parentIdsWithChildren = users
        .where((user) => user.role == 'STUDENT' && user.parentId != null)
        .map((user) => user.parentId!)
        .toSet();
    final parents = users.where((user) => user.role == 'PARENT');
    final students = users.where((user) => user.role == 'STUDENT');
    final teachers = users.where((user) => user.role == 'TEACHER');

    return _DataQualitySummary(
      isAvailable: true,
      parentsWithoutChildren: parents
          .where((parent) => !parentIdsWithChildren.contains(parent.userId))
          .length,
      studentsWithoutParent: students
          .where((student) => student.parentId == null)
          .length,
      teachersWithoutMaterials: teachers.where((teacher) {
        final department = teacher.department?.trim() ?? '';
        return teacher.assignedGrade == null && department.isEmpty;
      }).length,
    );
  }
}

class _DataQualityGrid extends StatelessWidget {
  const _DataQualityGrid({required this.summary, required this.onOpenUsers});

  final _DataQualitySummary summary;
  final VoidCallback onOpenUsers;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _DataQualityCard(
        key: const ValueKey('admin-quality-parents-without-children'),
        title: 'أولياء بلا أبناء',
        value: summary.parentsWithoutChildren,
        unavailable: !summary.isAvailable,
        icon: Icons.family_restroom_rounded,
        color: AppTheme.primaryOrange,
        onTap: onOpenUsers,
      ),
      _DataQualityCard(
        key: const ValueKey('admin-quality-students-without-parent'),
        title: 'طلاب بلا ولي أمر',
        value: summary.studentsWithoutParent,
        unavailable: !summary.isAvailable,
        icon: Icons.person_off_rounded,
        color: AppTheme.primaryRed,
        onTap: onOpenUsers,
      ),
      _DataQualityCard(
        key: const ValueKey('admin-quality-teachers-without-materials'),
        title: 'معلمون بلا مواد',
        value: summary.teachersWithoutMaterials,
        unavailable: !summary.isAvailable,
        icon: Icons.school_outlined,
        color: AppTheme.primaryBlue,
        onTap: onOpenUsers,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 3
            : width >= 560
            ? 2
            : 1;
        const gap = AppTheme.space4;
        final itemWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }
}

class _DataQualityCard extends StatelessWidget {
  const _DataQualityCard({
    super.key,
    required this.title,
    required this.value,
    required this.unavailable,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final int? value;
  final bool unavailable;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardWhite,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space5),
          decoration: _panelDecoration(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Text(
                unavailable ? 'غير متوفر' : '${value ?? 0}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: unavailable ? 13 : 22,
                  fontWeight: FontWeight.w900,
                  color: unavailable ? AppTheme.textGray : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleDistributionPanel extends StatelessWidget {
  const _RoleDistributionPanel({required this.stats, required this.totalUsers});

  final AdminStats stats;
  final int totalUsers;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _RoleDistributionRowData(
        label: 'الطلاب',
        value: stats.totalStudents,
        color: AppTheme.primaryBlue,
      ),
      _RoleDistributionRowData(
        label: 'المعلمون',
        value: stats.totalTeachers,
        color: AppTheme.primaryGreen,
      ),
      _RoleDistributionRowData(
        label: 'أولياء الأمور',
        value: stats.totalParents,
        color: AppTheme.primaryOrange,
      ),
      _RoleDistributionRowData(
        label: 'المشرفون',
        value: stats.totalAdmins,
        color: AppTheme.primaryPurple,
      ),
    ];

    return _Panel(
      title: 'توزيع المستخدمين حسب الدور',
      subtitle: 'مشتق من إحصاءات لوحة التحكم.',
      child: Column(
        children: [
          for (final row in rows)
            _RoleDistributionRow(
              data: row,
              ratio: totalUsers == 0 ? 0 : row.value / totalUsers,
            ),
        ],
      ),
    );
  }
}

class _RoleDistributionRowData {
  const _RoleDistributionRowData({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _RoleDistributionRow extends StatelessWidget {
  const _RoleDistributionRow({required this.data, required this.ratio});

  final _RoleDistributionRowData data;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textGray,
                  ),
                ),
              ),
              Text(
                '${data.value}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: data.color.withValues(alpha: 0.10),
              valueColor: AlwaysStoppedAnimation<Color>(data.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardColumns extends StatelessWidget {
  const _DashboardColumns({required this.primary, required this.insights});

  final Widget primary;
  final List<Widget> insights;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          // Narrow: stack the users list first, then the insight cards.
          return Column(
            children: [
              primary,
              for (final panel in insights) ...[
                const SizedBox(height: AppTheme.space4),
                panel,
              ],
            ],
          );
        }

        // Wide (RTL): the users table renders on the right with more
        // breathing room, the insight cards on the left of the content.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 8, child: primary),
            const SizedBox(width: AppTheme.space4),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  for (var i = 0; i < insights.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppTheme.space4),
                    insights[i],
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentUsersPanel extends StatelessWidget {
  const _RecentUsersPanel({
    required this.users,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final List<UserSummary>? users;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'آخر المستخدمين المضافين',
      subtitle: 'مرتبة حسب تاريخ الإنشاء عندما يكون متاحاً.',
      trailing: users == null
          ? null
          : _StatusBadge(
              label: '${users!.length} حساب',
              color: AppTheme.primaryBlue,
            ),
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (isLoading) {
      return const _InlineState(
        icon: Icons.hourglass_top_rounded,
        title: 'جاري تحميل المستخدمين',
        message: 'يتم جلب قائمة الحسابات من الخادم.',
      );
    }

    if (error != null) {
      return _InlineState(
        icon: Icons.cloud_off_rounded,
        title: 'تعذر تحميل المستخدمين',
        message: error!,
        actionLabel: 'إعادة المحاولة',
        onAction: () {
          onRetry();
        },
      );
    }

    final list = _sortUsersByCreatedAt(users ?? const []);
    if (list.isEmpty) {
      return const _InlineState(
        icon: Icons.people_outline_rounded,
        title: 'لا توجد بيانات مستخدمين',
        message: 'ستظهر الحسابات هنا بعد تحميلها من الخادم.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final visible = list.take(8).toList(growable: false);
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  for (final user in visible) _CompactUserRow(user: user),
                ],
              );
            }
            return _UsersTable(users: visible);
          },
        ),
        const SizedBox(height: AppTheme.space4),
        TextButton.icon(
          key: const ValueKey('admin-dashboard-view-all-users'),
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.adminManageUsers),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text(
            'عرض كل المستخدمين',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
            minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        ),
      ],
    );
  }
}

List<UserSummary> _sortUsersByCreatedAt(List<UserSummary> users) {
  final sorted = users.toList(growable: false);
  sorted.sort((a, b) {
    final aDate = DateTime.tryParse(a.createdAt ?? '');
    final bDate = DateTime.tryParse(b.createdAt ?? '');
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  });
  return sorted;
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users});

  final List<UserSummary> users;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _UserTableHeader(),
        for (var i = 0; i < users.length; i++)
          _UserTableRow(user: users[i], striped: i.isOdd),
      ],
    );
  }
}

class _UserTableHeader extends StatelessWidget {
  const _UserTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('المستخدم')),
          Expanded(flex: 2, child: _HeaderText('الدور')),
          Expanded(flex: 3, child: _HeaderText('التواصل')),
          Expanded(flex: 2, child: _HeaderText('آخر دخول')),
          SizedBox(width: 84, child: _HeaderText('الحالة')),
        ],
      ),
    );
  }
}

class _UserTableRow extends StatelessWidget {
  const _UserTableRow({required this.user, this.striped = false});

  final UserSummary user;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.role);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        color: striped
            ? AppTheme.surfaceSubtle.withValues(alpha: 0.55)
            : Colors.transparent,
        border: const Border(bottom: BorderSide(color: AppTheme.surfaceSubtle)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _UserIdentity(user: user)),
          Expanded(
            flex: 2,
            child: _StatusBadge(label: _roleLabel(user.role), color: color),
          ),
          Expanded(flex: 3, child: _CellText(_contactLabel(user))),
          Expanded(
            flex: 2,
            child: _CellText(_formatDateTime(user.lastLoginAt)),
          ),
          SizedBox(
            width: 84,
            child: _StatusBadge(
              label: user.isActive ? 'نشط' : 'موقوف',
              color: user.isActive
                  ? AppTheme.primaryGreen
                  : AppTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactUserRow extends StatelessWidget {
  const _CompactUserRow({required this.user});

  final UserSummary user;

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.role);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserIdentity(user: user),
          const SizedBox(height: AppTheme.space3),
          Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: [
              _StatusBadge(label: _roleLabel(user.role), color: color),
              _StatusBadge(
                label: user.isActive ? 'نشط' : 'موقوف',
                color: user.isActive
                    ? AppTheme.primaryGreen
                    : AppTheme.primaryRed,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          _CellText(_contactLabel(user)),
          const SizedBox(height: AppTheme.space1),
          _CellText('آخر دخول: ${_formatDateTime(user.lastLoginAt)}'),
        ],
      ),
    );
  }
}

class _UserIdentity extends StatelessWidget {
  const _UserIdentity({required this.user});

  final UserSummary user;

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.role);
    final name = user.fullName.trim().isEmpty
        ? 'مستخدم بدون اسم'
        : user.fullName;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(_roleIcon(user.role), color: color, size: 20),
        ),
        const SizedBox(width: AppTheme.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ID ${user.userId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textLight,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountStatusPanel extends StatelessWidget {
  const _AccountStatusPanel({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
  });

  final int totalUsers;
  final int? activeUsers;
  final int? inactiveUsers;

  @override
  Widget build(BuildContext context) {
    // Real ratio only: active count over the loaded users list — both come
    // from the same provider list, so the proportion is never fabricated.
    final loadedUsers = activeUsers == null || inactiveUsers == null
        ? null
        : activeUsers! + inactiveUsers!;
    final activeRatio = loadedUsers == null || loadedUsers == 0
        ? null
        : (activeUsers! / loadedUsers).clamp(0.0, 1.0);

    return _Panel(
      title: 'حالة الحسابات',
      subtitle: 'الحسابات النشطة مشتقة من قائمة المستخدمين المحملة.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activeRatio != null) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'نسبة الحسابات النشطة',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textGray,
                    ),
                  ),
                ),
                Text(
                  '${(activeRatio * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space2),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              child: LinearProgressIndicator(
                value: activeRatio.toDouble(),
                minHeight: 8,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space4),
          ],
          _InsightRow(
            icon: Icons.groups_rounded,
            label: 'إجمالي المستخدمين',
            value: '$totalUsers',
            color: AppTheme.primaryBlue,
          ),
          _InsightRow(
            icon: Icons.check_circle_rounded,
            label: 'نشط',
            value: activeUsers == null ? 'غير متوفر' : '$activeUsers',
            color: AppTheme.primaryGreen,
          ),
          _InsightRow(
            icon: Icons.block_rounded,
            label: 'موقوف',
            value: inactiveUsers == null ? 'غير متوفر' : '$inactiveUsers',
            color: AppTheme.primaryRed,
          ),
        ],
      ),
    );
  }
}

class _ContentSnapshotPanel extends StatelessWidget {
  const _ContentSnapshotPanel({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'ملخص المحتوى والتفاعل',
      subtitle: 'حقول إحصائية متاحة من الخادم حالياً.',
      child: Column(
        children: [
          _InsightRow(
            icon: Icons.menu_book_rounded,
            label: 'المواد',
            value: '${stats.totalSubjects}',
            color: AppTheme.primaryBlueDeep,
          ),
          _InsightRow(
            icon: Icons.library_books_rounded,
            label: 'الدروس',
            value: '${stats.totalLessons}',
            color: AppTheme.primaryGreenDeep,
          ),
          _InsightRow(
            icon: Icons.assignment_turned_in_rounded,
            label: 'محاولات الاختبار',
            value: '${stats.totalAttempts}',
            color: AppTheme.primaryYellowDeep,
          ),
          _InsightRow(
            icon: Icons.check_circle_rounded,
            label: 'دروس مكتملة',
            value: '${stats.totalCompletedLessons}',
            color: AppTheme.primaryTerracotta,
          ),
          _InsightRow(
            icon: Icons.trending_up_rounded,
            label: 'طلاب نشطون هذا الأسبوع',
            value: '${stats.activeStudentsThisWeek}',
            color: AppTheme.primaryPurple,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        height: 1.3,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppTheme.space1),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textGray,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppTheme.space3),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppTheme.space5),
          child,
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
            height: 1.25,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: AppTheme.space1),
          Text(
            subtitle!,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppTheme.textLight),
          const SizedBox(height: AppTheme.space3),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.space1),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGray,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppTheme.space4),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                actionLabel!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textGray,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppTheme.space1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: 5,
      ),
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
          height: 1.2,
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppTheme.textGray,
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppTheme.textGray,
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: AppTheme.cardWhite,
    borderRadius: BorderRadius.circular(AppTheme.radiusM),
    border: Border.all(color: AppTheme.surfaceMuted, width: 1),
    boxShadow: AppTheme.elevationLow,
  );
}

String _contactLabel(UserSummary user) {
  final email = user.email?.trim();
  if (email != null && email.isNotEmpty) return email;
  final phone = user.phone?.trim();
  if (phone != null && phone.isNotEmpty) return phone;
  return 'غير متوفر';
}

String _formatDateTime(String? value) {
  if (value == null || value.trim().isEmpty) return 'غير متوفر';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final date =
      '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  final time =
      '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  return '$date $time';
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
    'STUDENT' => Icons.person_rounded,
    'TEACHER' => Icons.school_rounded,
    'PARENT' => Icons.family_restroom_rounded,
    'ADMIN' => Icons.admin_panel_settings_rounded,
    _ => Icons.person_rounded,
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
