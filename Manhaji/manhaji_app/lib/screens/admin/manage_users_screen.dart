import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/admin_stats.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

/// Admin CRUD surface for students + teachers. Two tabs, an edit/delete row per
/// user, a FAB that opens the create form. Self-deletion is prevented by the
/// backend; the UI just shows the resulting error in a snack bar.
class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    Future.microtask(() {
      if (!mounted) return;
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _currentRoleForTab => switch (_tabs.index) {
    0 => 'STUDENT',
    1 => 'TEACHER',
    _ => 'PARENT',
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المستخدمين'),
          bottom: TabBar(
            controller: _tabs,
            labelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'الطلاب'),
              Tab(icon: Icon(Icons.school), text: 'المعلمون'),
              Tab(icon: Icon(Icons.family_restroom), text: 'أولياء الأمور'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
                backgroundColor: AppTheme.primaryGreen,
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                label: Text(
                  switch (_tabs.index) {
                    0 => 'إضافة طالب',
                    1 => 'إضافة معلم',
                    _ => 'إضافة ولي أمر',
                  },
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => _openCreateForm(_currentRoleForTab),
              ),
        body: Consumer<AdminProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.users == null) {
              return const LoadingState();
            }
            if (provider.error != null && provider.users == null) {
              return ErrorState(
                message: provider.error!,
                onRetry: () => provider.loadUsers(),
              );
            }
            final users = provider.users ?? const [];
            final students = users.where((u) => u.role == 'STUDENT').toList();
            final teachers = users.where((u) => u.role == 'TEACHER').toList();
            final parents = users.where((u) => u.role == 'PARENT').toList();
            return TabBarView(
              controller: _tabs,
              children: [
                _UserList(
                  users: students,
                  emptyMessage: 'لا يوجد طلاب بعد',
                  onEdit: _openEditForm,
                  onDelete: _confirmDelete,
                ),
                _UserList(
                  users: teachers,
                  emptyMessage: 'لا يوجد معلمون بعد',
                  onEdit: _openEditForm,
                  onDelete: _confirmDelete,
                ),
                _UserList(
                  users: parents,
                  emptyMessage: 'لا يوجد أولياء أمور بعد',
                  onEdit: _openEditForm,
                  onDelete: _confirmDelete,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openCreateForm(String role) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserForm(role: role),
    );
    if (result == true && mounted) {
      _snack('تمّ إضافة المستخدم');
    }
  }

  Future<void> _openEditForm(UserSummary user) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserForm(role: user.role, editing: user),
    );
    if (result == true && mounted) {
      _snack('تمّ تحديث المستخدم');
    }
  }

  Future<void> _confirmDelete(UserSummary user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المستخدم', style: TextStyle(fontFamily: 'Cairo')),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'حذف',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
            ),
          ),
        ],
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
}

class _UserList extends StatelessWidget {
  final List<UserSummary> users;
  final String emptyMessage;
  final void Function(UserSummary) onEdit;
  final void Function(UserSummary) onDelete;

  const _UserList({
    required this.users,
    required this.emptyMessage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            color: AppTheme.textGray,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final u = users[i];
        final isStudent = u.role == 'STUDENT';
        final isParent = u.role == 'PARENT';
        final color = isStudent
            ? AppTheme.primaryBlue
            : isParent
                ? AppTheme.primaryOrange
                : AppTheme.primaryGreen;
        final contact = u.email ?? u.phone ?? '';
        final secondaryLine = isStudent
            ? 'الصف ${u.gradeLevel ?? "—"}  •  $contact'
            : contact;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(
                    isStudent
                        ? Icons.person
                        : isParent
                            ? Icons.family_restroom
                            : Icons.school,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.fullName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        secondaryLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: u.isActive
                        ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    u.isActive ? 'نشط' : 'موقوف',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: u.isActive ? AppTheme.primaryGreen : Colors.red,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'تعديل',
                  icon: const Icon(Icons.edit_outlined,
                      color: AppTheme.primaryBlue),
                  onPressed: () => onEdit(u),
                ),
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => onDelete(u),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Add or edit a single user. Inline form so the bottom sheet feels native;
/// uses the AdminProvider's mutation methods directly and pops with `true` on
/// success.
class _UserForm extends StatefulWidget {
  final String role; // 'STUDENT', 'TEACHER', or 'PARENT'
  final UserSummary? editing;

  const _UserForm({required this.role, this.editing});

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final TextEditingController _password = TextEditingController();
  final TextEditingController _department = TextEditingController();
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
    final u = widget.editing;
    _name = TextEditingController(text: u?.fullName ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _gradeLevel = u?.gradeLevel ?? (_isStudent ? 1 : null);
    _isActive = u?.isActive ?? true;
    if (_isTeacher && u != null) {
      _department.text = u.department ?? '';
      _assignedGrade = u.assignedGrade;
    }
    if (_isStudent) {
      _selectedParentId = u?.parentId;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل البريد أو الهاتف على الأقل',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      );
      return;
    }

    final provider = context.read<AdminProvider>();
    bool ok;
    if (_isEdit) {
      ok = await provider.updateUser(
        widget.editing!.userId,
        fullName: _name.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        password:
            _password.text.trim().isEmpty ? null : _password.text.trim(),
        isActive: _isActive,
        gradeLevel: _isStudent ? _gradeLevel : null,
        department: _isTeacher && _department.text.trim().isNotEmpty
            ? _department.text.trim()
            : null,
        assignedGrade: _isTeacher ? _assignedGrade : null,
      );
      if (ok && _isStudent) {
        final origParentId = widget.editing!.parentId;
        if (_selectedParentId != origParentId) {
          await provider.linkStudentToParent(
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
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'فشل الحفظ',
              style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final mutating = adminProvider.isMutating;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + viewInsets),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _isEdit
                    ? (_isStudent
                        ? 'تعديل بيانات الطالب'
                        : _isTeacher
                            ? 'تعديل بيانات المعلم'
                            : 'تعديل بيانات ولي الأمر')
                    : (_isStudent
                        ? 'إضافة طالب جديد'
                        : _isTeacher
                            ? 'إضافة معلم جديد'
                            : 'إضافة ولي أمر جديد'),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              _TextField(
                controller: _name,
                label: 'الاسم الكامل',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
              ),
              const SizedBox(height: 12),
              _TextField(
                controller: _email,
                label: 'البريد الإلكتروني (اختياري)',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _TextField(
                controller: _phone,
                label: 'رقم الهاتف (اختياري)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _TextField(
                controller: _password,
                label: _isEdit ? 'كلمة مرور جديدة (اختياري)' : 'كلمة المرور',
                obscure: true,
                validator: (v) {
                  if (_isEdit) return null;
                  if (v == null || v.length < 6) {
                    return 'كلمة المرور 6 أحرف فأكثر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_isStudent)
                _GradeDropdown(
                  label: 'الصف',
                  value: _gradeLevel,
                  onChanged: (v) => setState(() => _gradeLevel = v),
                )
              else if (_isTeacher) ...[
                _TextField(
                  controller: _department,
                  label: 'القسم (اختياري)',
                ),
                const SizedBox(height: 12),
                _GradeDropdown(
                  label: 'الصف المخصص (اختياري)',
                  value: _assignedGrade,
                  onChanged: (v) => setState(() => _assignedGrade = v),
                  optional: true,
                ),
              ],
              if (_isStudent && _isEdit) ...[
                const SizedBox(height: 12),
                _ParentDropdown(
                  parents: adminProvider.users
                          ?.where((u) => u.role == 'PARENT')
                          .toList() ??
                      [],
                  value: _selectedParentId,
                  onChanged: (v) => setState(() => _selectedParentId = v),
                ),
              ],
              if (_isEdit) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الحساب نشط',
                      style: TextStyle(fontFamily: 'Cairo')),
                  value: _isActive,
                  activeThumbColor: AppTheme.primaryGreen,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: mutating ? null : _submit,
                child: mutating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(
                        _isEdit ? 'حفظ التعديلات' : 'إضافة',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscure = false,
    this.validator,
  });

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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }
}

class _GradeDropdown extends StatelessWidget {
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool optional;

  const _GradeDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        if (optional)
          const DropdownMenuItem(value: null, child: Text('غير محدد')),
        for (final g in [1, 2, 3, 4])
          DropdownMenuItem(value: g, child: Text('الصف $g')),
      ],
      onChanged: onChanged,
      validator: optional
          ? null
          : (v) => v == null ? 'اختر الصف' : null,
    );
  }
}

class _ParentDropdown extends StatelessWidget {
  final List<UserSummary> parents;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _ParentDropdown({
    required this.parents,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: 'ولي الأمر',
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('بدون ولي أمر', style: TextStyle(fontFamily: 'Cairo')),
        ),
        for (final p in parents)
          DropdownMenuItem<int?>(
            value: p.userId,
            child: Text(p.fullName, style: const TextStyle(fontFamily: 'Cairo')),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
