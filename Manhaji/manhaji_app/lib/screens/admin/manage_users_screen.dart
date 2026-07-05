import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/admin_stats.dart';
import '../../models/admin_teacher_assignment.dart';
import '../../models/question_bank.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/staff_metric_card.dart';
import '../../widgets/staff_web_shell.dart';
import 'admin_shell_navigation.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _roleFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshUsers() => context.read<AdminProvider>().loadUsers();

  Future<void> _openCreateForm(String role) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _UserFormDialog(role: role),
    );
    if (result == true && mounted) {
      _snack('تمّ إضافة المستخدم');
      await _refreshUsers();
    }
  }

  Future<void> _openEditForm(UserSummary user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _UserFormDialog(role: user.role, editing: user),
    );
    if (result == true && mounted) {
      _snack('تمّ تحديث المستخدم');
      await _refreshUsers();
    }
  }

  Future<void> _openTeacherAssignments(UserSummary user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _TeacherAssignmentsDialog(teacher: user),
    );
    if (result == true && mounted) {
      _snack('تمّ تحديث مواد المعلم');
      await _refreshUsers();
    }
  }

  Future<void> _confirmDelete(UserSummary user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'حذف المستخدم',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          content: Text(
            'هل تريد حذف "${user.fullName}" نهائياً؟ لا يمكن التراجع.',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                minimumSize: const Size(96, 44),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'حذف',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<AdminProvider>();
    final ok = await provider.deleteUser(user.userId);
    if (!mounted) return;
    _snack(ok ? 'تمّ الحذف' : (provider.error ?? 'فشل الحذف'));
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StaffWebShell(
        title: 'المستخدمون',
        subtitle: 'إدارة حسابات الطلاب والمعلمين وأولياء الأمور',
        roleLabel: 'مساحة المشرف',
        currentRoute: AppRoutes.adminManageUsers,
        items: adminShellItems(context),
        actions: [
          IconButton(
            tooltip: 'تحديث المستخدمين',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshUsers,
          ),
        ],
        child: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.users == null) {
              return const LoadingState();
            }

            if (provider.error != null && provider.users == null) {
              return ErrorState(
                message: provider.error!,
                onRetry: _refreshUsers,
              );
            }

            final users = provider.users ?? const <UserSummary>[];
            final filtered = _filteredUsers(users);

            return RefreshIndicator(
              onRefresh: _refreshUsers,
              child: ListView(
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
                          const _SectionHeading(
                            title: 'إحصائيات المستخدمين',
                            subtitle:
                                'ملخص سريع مبني على قائمة المستخدمين الحالية.',
                          ),
                          const SizedBox(height: AppTheme.space4),
                          _UserStatsGrid(users: users),
                          const SizedBox(height: AppTheme.space8),
                          _CreateUserPanel(onCreate: _openCreateForm),
                          const SizedBox(height: AppTheme.space8),
                          const _SectionHeading(
                            title: 'جدول المستخدمين',
                            subtitle: 'ابحث وصفّ الحسابات المحملة من الخادم.',
                          ),
                          const SizedBox(height: AppTheme.space4),
                          _FilterBar(
                            searchController: _searchController,
                            roleFilter: _roleFilter,
                            onQueryChanged: (_) => setState(() {}),
                            onRoleChanged: (role) {
                              setState(() => _roleFilter = role);
                            },
                          ),
                          const SizedBox(height: AppTheme.space4),
                          _UsersTablePanel(
                            users: filtered,
                            totalUsers: users.length,
                            onEdit: _openEditForm,
                            onDelete: _confirmDelete,
                            onManageAssignments: _openTeacherAssignments,
                          ),
                        ],
                      ),
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

  List<UserSummary> _filteredUsers(List<UserSummary> users) {
    final query = _searchController.text.trim().toLowerCase();
    return users
        .where((user) {
          final roleMatches = _roleFilter == 'ALL' || user.role == _roleFilter;
          if (!roleMatches) return false;
          if (query.isEmpty) return true;
          final haystack = [
            user.fullName,
            user.email,
            user.phone,
            _roleLabel(user.role),
            user.department,
          ].whereType<String>().join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }
}

class _UserStatsGrid extends StatelessWidget {
  const _UserStatsGrid({required this.users});

  final List<UserSummary> users;

  @override
  Widget build(BuildContext context) {
    final students = users.where((user) => user.role == 'STUDENT').length;
    final teachers = users.where((user) => user.role == 'TEACHER').length;
    final parents = users.where((user) => user.role == 'PARENT').length;
    final active = users.where((user) => user.isActive).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppTheme.space4;
        final width = constraints.maxWidth;
        final columns = width >= 1120
            ? 4
            : width >= 760
            ? 2
            : 1;
        final itemWidth = (width - (gap * (columns - 1))) / columns;
        final cards = [
          StaffMetricCard(
            title: 'كل المستخدمين',
            value: '${users.length}',
            icon: Icons.groups_rounded,
            color: AppTheme.primaryBlue,
          ),
          StaffMetricCard(
            title: 'الطلاب',
            value: '$students',
            icon: Icons.person_rounded,
            color: AppTheme.primaryGreen,
          ),
          StaffMetricCard(
            title: 'المعلمون',
            value: '$teachers',
            icon: Icons.school_rounded,
            color: AppTheme.primaryTerracotta,
          ),
          StaffMetricCard(
            title: 'الحسابات النشطة',
            value: '$active',
            subtitle: 'أولياء الأمور: $parents',
            icon: Icons.verified_user_rounded,
            color: AppTheme.primaryPurple,
          ),
        ];

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

class _CreateUserPanel extends StatelessWidget {
  const _CreateUserPanel({required this.onCreate});

  final void Function(String role) onCreate;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'إنشاء مستخدم',
      subtitle: 'أضف حساباً جديداً باستخدام الحقول التي يدعمها الخادم.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppTheme.space3;
          final compact = constraints.maxWidth < 720;
          final itemWidth = compact
              ? constraints.maxWidth
              : (constraints.maxWidth - gap * 2) / 3;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              SizedBox(
                width: itemWidth,
                child: _CreateRoleButton(
                  label: 'إضافة طالب',
                  icon: Icons.person_add_alt_1_rounded,
                  color: AppTheme.primaryBlue,
                  onTap: () => onCreate('STUDENT'),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _CreateRoleButton(
                  label: 'إضافة معلم',
                  icon: Icons.school_rounded,
                  color: AppTheme.primaryGreen,
                  onTap: () => onCreate('TEACHER'),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _CreateRoleButton(
                  label: 'إضافة ولي أمر',
                  icon: Icons.family_restroom_rounded,
                  color: AppTheme.primaryOrange,
                  onTap: () => onCreate('PARENT'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CreateRoleButton extends StatelessWidget {
  const _CreateRoleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(180, 52),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchController,
    required this.roleFilter,
    required this.onQueryChanged,
    required this.onRoleChanged,
  });

  final TextEditingController searchController;
  final String roleFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'بحث وتصفية',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 740;
          final search = TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            style: const TextStyle(fontFamily: 'Cairo'),
            decoration: InputDecoration(
              labelText: 'ابحث بالاسم أو البريد أو الهاتف',
              labelStyle: const TextStyle(fontFamily: 'Cairo'),
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              filled: true,
              fillColor: AppTheme.cardWhite,
            ),
          );
          final chips = Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: [
              _RoleFilterChip(
                label: 'الكل',
                value: 'ALL',
                selectedValue: roleFilter,
                onSelected: onRoleChanged,
              ),
              _RoleFilterChip(
                label: 'الطلاب',
                value: 'STUDENT',
                selectedValue: roleFilter,
                onSelected: onRoleChanged,
              ),
              _RoleFilterChip(
                label: 'المعلمون',
                value: 'TEACHER',
                selectedValue: roleFilter,
                onSelected: onRoleChanged,
              ),
              _RoleFilterChip(
                label: 'أولياء الأمور',
                value: 'PARENT',
                selectedValue: roleFilter,
                onSelected: onRoleChanged,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: AppTheme.space3),
                chips,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 4, child: search),
              const SizedBox(width: AppTheme.space4),
              Expanded(flex: 5, child: chips),
            ],
          );
        },
      ),
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AppTheme.textDark,
        ),
      ),
      selected: selected,
      selectedColor: AppTheme.primaryTerracotta,
      backgroundColor: AppTheme.surfaceSubtle,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _UsersTablePanel extends StatelessWidget {
  const _UsersTablePanel({
    required this.users,
    required this.totalUsers,
    required this.onEdit,
    required this.onDelete,
    required this.onManageAssignments,
  });

  final List<UserSummary> users;
  final int totalUsers;
  final void Function(UserSummary user) onEdit;
  final void Function(UserSummary user) onDelete;
  final void Function(UserSummary user) onManageAssignments;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'جدول المستخدمين',
      subtitle: 'يعرض ${users.length} من أصل $totalUsers حساب.',
      child: users.isEmpty
          ? const _InlineState(
              icon: Icons.people_outline_rounded,
              title: 'لا توجد حسابات مطابقة',
              message: 'جرّب تغيير البحث أو التصفية.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 980) {
                  return Column(
                    children: [
                      for (final user in users)
                        _UserCard(
                          user: user,
                          onEdit: onEdit,
                          onDelete: onDelete,
                          onManageAssignments: onManageAssignments,
                        ),
                    ],
                  );
                }

                return Column(
                  children: [
                    const _UsersTableHeader(),
                    for (final user in users)
                      _UsersTableRow(
                        user: user,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onManageAssignments: onManageAssignments,
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _UsersTableHeader extends StatelessWidget {
  const _UsersTableHeader();

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
          Expanded(flex: 2, child: _HeaderText('تفاصيل')),
          SizedBox(width: 86, child: _HeaderText('الحالة')),
          SizedBox(width: 220, child: _HeaderText('إجراءات')),
        ],
      ),
    );
  }
}

class _UsersTableRow extends StatelessWidget {
  const _UsersTableRow({
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onManageAssignments,
  });

  final UserSummary user;
  final void Function(UserSummary user) onEdit;
  final void Function(UserSummary user) onDelete;
  final void Function(UserSummary user) onManageAssignments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.surfaceSubtle)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _UserIdentity(user: user)),
          Expanded(
            flex: 2,
            child: _StatusBadge(
              label: _roleLabel(user.role),
              color: _roleColor(user.role),
            ),
          ),
          Expanded(flex: 3, child: _CellText(_contactLabel(user))),
          Expanded(flex: 2, child: _CellText(_detailLabel(user))),
          SizedBox(
            width: 86,
            child: _StatusBadge(
              label: user.isActive ? 'نشط' : 'موقوف',
              color: user.isActive
                  ? AppTheme.primaryGreen
                  : AppTheme.primaryRed,
            ),
          ),
          SizedBox(
            width: 220,
            child: _UserActions(
              user: user,
              onEdit: onEdit,
              onDelete: onDelete,
              onManageAssignments: onManageAssignments,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onManageAssignments,
  });

  final UserSummary user;
  final void Function(UserSummary user) onEdit;
  final void Function(UserSummary user) onDelete;
  final void Function(UserSummary user) onManageAssignments;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UserIdentity(user: user),
          const SizedBox(height: AppTheme.space3),
          Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: [
              _StatusBadge(
                label: _roleLabel(user.role),
                color: _roleColor(user.role),
              ),
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
          _CellText(_detailLabel(user)),
          const SizedBox(height: AppTheme.space3),
          _UserActions(
            user: user,
            onEdit: onEdit,
            onDelete: onDelete,
            onManageAssignments: onManageAssignments,
          ),
        ],
      ),
    );
  }
}

class _UserActions extends StatelessWidget {
  const _UserActions({
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onManageAssignments,
  });

  final UserSummary user;
  final void Function(UserSummary user) onEdit;
  final void Function(UserSummary user) onDelete;
  final void Function(UserSummary user) onManageAssignments;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.space2,
      runSpacing: AppTheme.space2,
      children: [
        IconButton.filledTonal(
          tooltip: 'تعديل',
          icon: const Icon(Icons.edit_rounded),
          onPressed: () => onEdit(user),
        ),
        if (user.role == 'TEACHER')
          TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(120, 42),
              foregroundColor: AppTheme.primaryGreenDeep,
            ),
            onPressed: () => onManageAssignments(user),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: const Text(
              'إدارة المواد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        IconButton.filledTonal(
          tooltip: 'حذف',
          icon: const Icon(Icons.delete_outline_rounded),
          color: AppTheme.primaryRed,
          onPressed: () => onDelete(user),
        ),
      ],
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({required this.role, this.editing});

  final String role;
  final UserSummary? editing;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final TextEditingController _password = TextEditingController();
  final TextEditingController _department = TextEditingController();
  final Set<int> _selectedSubjectIds = <int>{};
  int? _gradeLevel;
  int? _assignedGrade;
  int? _selectedParentId;
  bool _isActive = true;

  bool get _isEdit => widget.editing != null;
  bool get _isStudent => widget.role == 'STUDENT';
  bool get _isTeacher => widget.role == 'TEACHER';

  @override
  void initState() {
    super.initState();
    final user = widget.editing;
    _name = TextEditingController(text: user?.fullName ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _gradeLevel = user?.gradeLevel;
    _isActive = user?.isActive ?? true;
    if (_isTeacher && user != null) {
      _department.text = user.department ?? '';
      _assignedGrade = user.assignedGrade;
    }
    if (_isStudent) {
      _selectedParentId = user?.parentId;
    }

    if (_isTeacher && !_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AdminProvider>().loadAssignmentSubjects();
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _department.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final hasContact =
        _email.text.trim().isNotEmpty || _phone.text.trim().isNotEmpty;
    if (!hasContact) {
      _showSnack('أدخل البريد أو الهاتف على الأقل');
      return;
    }

    final provider = context.read<AdminProvider>();
    final assignmentSubjects = provider.assignmentSubjects ?? const [];
    final teacherAssignments = _selectedSubjectIds
        .map((subjectId) {
          final subject = assignmentSubjects
              .where((candidate) => candidate.id == subjectId)
              .firstOrNull;
          return subject == null
              ? null
              : TeacherAssignmentPayload(
                  subjectId: subject.id,
                  gradeLevel: subject.gradeLevel,
                );
        })
        .whereType<TeacherAssignmentPayload>()
        .toList(growable: false);

    if (_isTeacher && !_isEdit && teacherAssignments.isEmpty) {
      _showSnack('اختر مادة واحدة على الأقل للمعلم');
      return;
    }

    bool ok;
    if (_isEdit) {
      ok = await provider.updateUser(
        widget.editing!.userId,
        fullName: _name.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        password: _password.text.trim().isEmpty ? null : _password.text.trim(),
        isActive: _isActive,
        gradeLevel: _isStudent ? _gradeLevel : null,
        department: _isTeacher && _department.text.trim().isNotEmpty
            ? _department.text.trim()
            : null,
        assignedGrade: _isTeacher ? _assignedGrade : null,
      );
      if (ok && _isStudent) {
        final originalParentId = widget.editing!.parentId;
        if (_selectedParentId != originalParentId) {
          ok = await provider.linkStudentToParent(
            widget.editing!.userId,
            _selectedParentId,
          );
        }
      }
    } else {
      ok = await provider.createUser(
        fullName: _name.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        password: _password.text.trim(),
        role: widget.role,
        gradeLevel: _isStudent ? _gradeLevel : null,
        department: _isTeacher && _department.text.trim().isNotEmpty
            ? _department.text.trim()
            : null,
        assignedGrade: _isTeacher ? _assignedGrade : null,
        teacherAssignments: _isTeacher ? teacherAssignments : null,
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _showSnack(provider.error ?? 'فشل الحفظ');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final mutating = provider.isMutating;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppTheme.space5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
          child: Column(
            children: [
              _DialogHeader(
                title: _dialogTitle,
                subtitle: _isTeacher && !_isEdit
                    ? 'يجب اختيار مادة واحدة على الأقل قبل إنشاء المعلم.'
                    : 'املأ البيانات المدعومة من الخادم.',
                onClose: () => Navigator.pop(context, false),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.space5),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TextField(
                          controller: _name,
                          label: 'الاسم الكامل',
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'أدخل الاسم'
                              : null,
                        ),
                        const SizedBox(height: AppTheme.space3),
                        _TextField(
                          controller: _email,
                          label: 'البريد الإلكتروني (اختياري)',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppTheme.space3),
                        _TextField(
                          controller: _phone,
                          label: 'رقم الهاتف (اختياري)',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppTheme.space3),
                        _TextField(
                          controller: _password,
                          label: _isEdit
                              ? 'كلمة مرور جديدة (اختياري)'
                              : 'كلمة المرور',
                          obscure: true,
                          validator: (value) {
                            if (_isEdit) return null;
                            if (value == null || value.length < 6) {
                              return 'كلمة المرور 6 أحرف فأكثر';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.space3),
                        if (_isStudent)
                          _GradeDropdown(
                            label: 'الصف',
                            value: _gradeLevel,
                            onChanged: (value) {
                              setState(() => _gradeLevel = value);
                            },
                          )
                        else if (_isTeacher) ...[
                          _TextField(
                            controller: _department,
                            label: 'القسم (اختياري)',
                          ),
                          const SizedBox(height: AppTheme.space3),
                          _GradeDropdown(
                            label: 'الصف المخصص (اختياري)',
                            value: _assignedGrade,
                            onChanged: (value) {
                              setState(() => _assignedGrade = value);
                            },
                            optional: true,
                          ),
                          if (!_isEdit) ...[
                            const SizedBox(height: AppTheme.space5),
                            _SubjectAssignmentPicker(
                              title: 'مواد المعلم',
                              subjects: provider.assignmentSubjects,
                              selectedSubjectIds: _selectedSubjectIds,
                              isLoading: provider.isLoadingAssignments,
                              error: provider.assignmentError,
                              onRetry: () {
                                provider.loadAssignmentSubjects();
                              },
                              onToggle: _toggleSubject,
                            ),
                          ],
                        ],
                        if (_isStudent && _isEdit) ...[
                          const SizedBox(height: AppTheme.space3),
                          _ParentDropdown(
                            parents:
                                provider.users
                                    ?.where((user) => user.role == 'PARENT')
                                    .toList() ??
                                const [],
                            value: _selectedParentId,
                            onChanged: (value) {
                              setState(() => _selectedParentId = value);
                            },
                          ),
                        ],
                        if (_isEdit) ...[
                          const SizedBox(height: AppTheme.space3),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'الحساب نشط',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                            value: _isActive,
                            activeThumbColor: AppTheme.primaryGreen,
                            onChanged: (value) {
                              setState(() => _isActive = value);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _DialogActions(
                primaryLabel: _isEdit ? 'حفظ التعديلات' : 'إضافة',
                isBusy: mutating,
                onCancel: () => Navigator.pop(context, false),
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _dialogTitle {
    if (_isEdit) {
      return switch (widget.role) {
        'STUDENT' => 'تعديل بيانات الطالب',
        'TEACHER' => 'تعديل بيانات المعلم',
        'PARENT' => 'تعديل بيانات ولي الأمر',
        _ => 'تعديل بيانات المستخدم',
      };
    }
    return switch (widget.role) {
      'STUDENT' => 'إضافة طالب جديد',
      'TEACHER' => 'إضافة معلم جديد',
      'PARENT' => 'إضافة ولي أمر جديد',
      _ => 'إضافة مستخدم جديد',
    };
  }

  void _toggleSubject(SubjectSummary subject, bool selected) {
    setState(() {
      if (selected) {
        _selectedSubjectIds.add(subject.id);
      } else {
        _selectedSubjectIds.remove(subject.id);
      }
    });
  }
}

class _TeacherAssignmentsDialog extends StatefulWidget {
  const _TeacherAssignmentsDialog({required this.teacher});

  final UserSummary teacher;

  @override
  State<_TeacherAssignmentsDialog> createState() =>
      _TeacherAssignmentsDialogState();
}

class _TeacherAssignmentsDialogState extends State<_TeacherAssignmentsDialog> {
  final Set<int> _selectedSubjectIds = <int>{};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    final provider = context.read<AdminProvider>();
    await provider.loadAssignmentSubjects();
    if (provider.assignmentSubjects == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    await provider.loadTeacherAssignments(widget.teacher.userId);
    if (!mounted) return;
    setState(() {
      _selectedSubjectIds
        ..clear()
        ..addAll(
          (provider.teacherAssignments ?? const [])
              .where((assignment) => assignment.isActive)
              .map((assignment) => assignment.subjectId),
        );
      _loaded = true;
    });
  }

  Future<void> _save() async {
    if (_selectedSubjectIds.isEmpty) {
      _showSnack('اختر مادة واحدة على الأقل للمعلم');
      return;
    }

    final provider = context.read<AdminProvider>();
    final subjects = provider.assignmentSubjects ?? const [];
    final payloads = _selectedSubjectIds
        .map((subjectId) {
          final subject = subjects
              .where((candidate) => candidate.id == subjectId)
              .firstOrNull;
          return subject == null
              ? null
              : TeacherAssignmentPayload(
                  subjectId: subject.id,
                  gradeLevel: subject.gradeLevel,
                );
        })
        .whereType<TeacherAssignmentPayload>()
        .toList(growable: false);

    if (payloads.isEmpty) {
      _showSnack('تعذر تحديد المواد المختارة');
      return;
    }

    final ok = await provider.saveTeacherAssignments(
      widget.teacher.userId,
      payloads,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _showSnack(provider.assignmentError ?? 'فشل حفظ مواد المعلم');
    }
  }

  void _toggleSubject(SubjectSummary subject, bool selected) {
    setState(() {
      if (selected) {
        _selectedSubjectIds.add(subject.id);
      } else {
        _selectedSubjectIds.remove(subject.id);
      }
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final loading = provider.isLoadingAssignments && !_loaded;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppTheme.space5),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
          child: Column(
            children: [
              _DialogHeader(
                title: 'إدارة مواد المعلم',
                subtitle: widget.teacher.fullName,
                onClose: () => Navigator.pop(context, false),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.space5),
                  child: _SubjectAssignmentPicker(
                    title: 'المواد المخصصة',
                    subjects: provider.assignmentSubjects,
                    selectedSubjectIds: _selectedSubjectIds,
                    isLoading: loading,
                    error: provider.assignmentError,
                    onRetry: _load,
                    onToggle: _toggleSubject,
                  ),
                ),
              ),
              _DialogActions(
                primaryLabel: 'حفظ المواد',
                isBusy: provider.isMutating,
                onCancel: () => Navigator.pop(context, false),
                onSubmit: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectAssignmentPicker extends StatelessWidget {
  const _SubjectAssignmentPicker({
    required this.title,
    required this.subjects,
    required this.selectedSubjectIds,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onToggle,
  });

  final String title;
  final List<SubjectSummary>? subjects;
  final Set<int> selectedSubjectIds;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final void Function(SubjectSummary subject, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    if (isLoading && subjects == null) {
      return const _InlineState(
        icon: Icons.hourglass_top_rounded,
        title: 'جاري تحميل المواد',
        message: 'يتم جلب المواد من الخادم.',
      );
    }

    if (error != null && subjects == null) {
      return _InlineState(
        icon: Icons.cloud_off_rounded,
        title: 'تعذر تحميل المواد',
        message: error!,
        actionLabel: 'إعادة المحاولة',
        onAction: onRetry,
      );
    }

    final list = subjects ?? const <SubjectSummary>[];
    if (list.isEmpty) {
      return const _InlineState(
        icon: Icons.menu_book_outlined,
        title: 'لا توجد مواد متاحة',
        message: 'لن يمكن إنشاء معلم قبل توفر مواد من الخادم.',
      );
    }

    final grouped = <int, List<SubjectSummary>>{};
    for (final subject in list) {
      grouped.putIfAbsent(subject.gradeLevel, () => []).add(subject);
    }
    final grades = grouped.keys.toList()..sort();

    return _Panel(
      title: title,
      subtitle: 'المحدد حالياً: ${selectedSubjectIds.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final grade in grades) ...[
            Text(
              _gradeLabel(grade),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            Wrap(
              spacing: AppTheme.space2,
              runSpacing: AppTheme.space2,
              children: [
                for (final subject in grouped[grade]!)
                  _SubjectChoice(
                    subject: subject,
                    selected: selectedSubjectIds.contains(subject.id),
                    onChanged: (selected) => onToggle(subject, selected),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space4),
          ],
        ],
      ),
    );
  }
}

class _SubjectChoice extends StatelessWidget {
  const _SubjectChoice({
    required this.subject,
    required this.selected,
    required this.onChanged,
  });

  final SubjectSummary subject;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      showCheckmark: true,
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.18),
      backgroundColor: AppTheme.surfaceSubtle,
      side: BorderSide(
        color: selected
            ? AppTheme.primaryGreen.withValues(alpha: 0.45)
            : AppTheme.surfaceMuted,
      ),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(
          '${subject.name} - ${_gradeLabel(subject.gradeLevel)}',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            color: selected ? AppTheme.primaryGreenDeep : AppTheme.textDark,
          ),
        ),
      ),
      onSelected: onChanged,
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.title,
    required this.onClose,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(bottom: BorderSide(color: AppTheme.surfaceMuted)),
      ),
      child: Row(
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({
    required this.primaryLabel,
    required this.isBusy,
    required this.onCancel,
    required this.onSubmit,
  });

  final String primaryLabel;
  final bool isBusy;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        border: Border(top: BorderSide(color: AppTheme.surfaceMuted)),
      ),
      child: Row(
        children: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(96, 46)),
            onPressed: isBusy ? null : onCancel,
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              minimumSize: const Size(148, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
            onPressed: isBusy ? null : onSubmit,
            child: isBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Text(
                    primaryLabel,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
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
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textGray,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.space4),
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
          ),
        ),
        if (subtitle != null) ...[
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
              style: TextButton.styleFrom(minimumSize: const Size(148, 44)),
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
                ),
              ),
            ],
          ),
        ),
      ],
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

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscure = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
      validator: validator,
    );
  }
}

class _GradeDropdown extends StatelessWidget {
  const _GradeDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    this.optional = false,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    const grades = [1, 2, 3, 4, 5, 6];
    return DropdownButtonFormField<int>(
      initialValue: value,
      style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
      items: [
        if (optional)
          const DropdownMenuItem<int>(
            value: null,
            child: Text('غير محدد', style: TextStyle(fontFamily: 'Cairo')),
          ),
        for (final grade in grades)
          DropdownMenuItem<int>(
            value: grade,
            child: Text(
              _gradeLabel(grade),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
      ],
      onChanged: onChanged,
      validator: optional
          ? null
          : (value) => value == null ? 'اختر الصف' : null,
    );
  }
}

class _ParentDropdown extends StatelessWidget {
  const _ParentDropdown({
    required this.parents,
    required this.value,
    required this.onChanged,
  });

  final List<UserSummary> parents;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: 'ولي الأمر',
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('بدون ولي أمر', style: TextStyle(fontFamily: 'Cairo')),
        ),
        for (final parent in parents)
          DropdownMenuItem<int?>(
            value: parent.userId,
            child: Text(
              parent.fullName,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
      ],
      onChanged: onChanged,
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

String _detailLabel(UserSummary user) {
  return switch (user.role) {
    'STUDENT' =>
      user.gradeLevel == null
          ? 'الصف غير متوفر'
          : _gradeLabel(user.gradeLevel!),
    'TEACHER' =>
      user.assignedGrade == null
          ? (user.department?.trim().isNotEmpty == true
                ? user.department!.trim()
                : 'المواد من إدارة المواد')
          : 'الصف المخصص: ${_gradeLabel(user.assignedGrade!)}',
    'PARENT' => 'ولي أمر',
    _ => 'غير متوفر',
  };
}

String _gradeLabel(int grade) => grade <= 0 ? 'صف غير محدد' : 'الصف $grade';

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
