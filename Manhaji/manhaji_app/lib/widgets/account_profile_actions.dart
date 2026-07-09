import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../providers/auth_provider.dart';

class AvatarOption {
  const AvatarOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

const List<AvatarOption> accountAvatarOptions = [
  AvatarOption(
    id: 'avatar-olive',
    label: 'زيتوني',
    icon: Icons.eco_rounded,
    color: AppTheme.primaryGreen,
  ),
  AvatarOption(
    id: 'avatar-book',
    label: 'كتاب',
    icon: Icons.menu_book_rounded,
    color: AppTheme.primaryBlue,
  ),
  AvatarOption(
    id: 'avatar-star',
    label: 'نجمة',
    icon: Icons.star_rounded,
    color: AppTheme.primaryYellowDeep,
  ),
  AvatarOption(
    id: 'avatar-palette',
    label: 'ألوان',
    icon: Icons.palette_rounded,
    color: AppTheme.primaryPurpleDeep,
  ),
  AvatarOption(
    id: 'avatar-school',
    label: 'مدرسة',
    icon: Icons.school_rounded,
    color: AppTheme.primaryTerracotta,
  ),
  AvatarOption(
    id: 'avatar-light',
    label: 'فكرة',
    icon: Icons.lightbulb_rounded,
    color: AppTheme.primaryOrangeDeep,
  ),
];

AvatarOption? accountAvatarOptionFor(String? avatarId) {
  if (avatarId == null || avatarId.trim().isEmpty) return null;
  for (final option in accountAvatarOptions) {
    if (option.id == avatarId) return option;
  }
  return null;
}

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    super.key,
    required this.avatarId,
    required this.fallbackLabel,
    this.size = 58,
    this.fallbackColor = AppTheme.primaryGreen,
    this.borderRadius,
  });

  final String? avatarId;
  final String fallbackLabel;
  final double size;
  final Color fallbackColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final option = accountAvatarOptionFor(avatarId);
    final color = option?.color ?? fallbackColor;
    final label = fallbackLabel.trim();

    return Container(
      key: ValueKey('account-avatar-${avatarId ?? 'default'}'),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusM),
      ),
      child: option == null
          ? Text(
              label.isNotEmpty ? label.characters.first : 'م',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            )
          : Icon(option.icon, color: color, size: size * 0.54),
    );
  }
}

class AccountAvatarPicker extends StatelessWidget {
  const AccountAvatarPicker({
    super.key,
    required this.selectedAvatarId,
    required this.onChanged,
  });

  final String? selectedAvatarId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppTheme.space2,
      runSpacing: AppTheme.space2,
      children: accountAvatarOptions.map((option) {
        final selected = option.id == selectedAvatarId;
        return InkWell(
          key: ValueKey('avatar-option-${option.id}'),
          onTap: () => onChanged(option.id),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            width: 94,
            height: 82,
            padding: const EdgeInsets.all(AppTheme.space2),
            decoration: BoxDecoration(
              color: selected
                  ? option.color.withValues(alpha: 0.14)
                  : AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: selected ? option.color : AppTheme.surfaceMuted,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(option.icon, color: option.color, size: 28),
                const SizedBox(height: AppTheme.space1),
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: selected ? AppTheme.textDark : AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AccountSettingsActions extends StatelessWidget {
  const AccountSettingsActions({
    super.key,
    required this.keyPrefix,
    required this.decoration,
    this.padding = const EdgeInsets.all(AppTheme.space5),
  });

  final String keyPrefix;
  final BoxDecoration decoration;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'إدارة الحساب',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          _AccountActionTile(
            key: ValueKey('$keyPrefix-edit-profile-action'),
            icon: Icons.edit_rounded,
            title: 'تعديل الملف الشخصي',
            onTap: () => showAccountProfileDialog(context),
          ),
          const SizedBox(height: AppTheme.space3),
          _AccountActionTile(
            key: ValueKey('$keyPrefix-avatar-action'),
            icon: Icons.account_circle_rounded,
            title: 'الصورة الرمزية',
            onTap: () => showAccountProfileDialog(context),
          ),
          const SizedBox(height: AppTheme.space3),
          _AccountActionTile(
            key: ValueKey('$keyPrefix-change-password-action'),
            icon: Icons.lock_reset_rounded,
            title: 'تغيير كلمة المرور',
            onTap: () => showAccountPasswordDialog(context),
          ),
        ],
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceSubtle,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.surfaceMuted),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryTerracotta),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
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

Future<void> showAccountProfileDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const Directionality(
      textDirection: TextDirection.rtl,
      child: _AccountProfileDialog(),
    ),
  );
}

Future<void> showAccountPasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const Directionality(
      textDirection: TextDirection.rtl,
      child: _AccountPasswordDialog(),
    ),
  );
}

class _AccountProfileDialog extends StatefulWidget {
  const _AccountProfileDialog();

  @override
  State<_AccountProfileDialog> createState() => _AccountProfileDialogState();
}

class _AccountProfileDialogState extends State<_AccountProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final String? _initialAvatarId;
  String? _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.userName ?? '');
    _emailController = TextEditingController(text: auth.userEmail ?? '');
    _initialAvatarId = auth.userAvatarId;
    _selectedAvatarId = auth.userAvatarId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _nameController.text.trim();
    final avatarChanged = _selectedAvatarId != _initialAvatarId;
    final success = await auth.updateProfile(
      fullName: name,
      avatarId: _selectedAvatarId,
    );

    if (!mounted) return;

    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            avatarChanged
                ? 'تم تحديث الصورة الرمزية'
                : 'تم تحديث الملف الشخصي بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'حدث خطأ. حاول مرة أخرى.',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AlertDialog(
      title: const Text(
        'تعديل الملف الشخصي',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey('account-profile-name-field'),
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'أدخل الاسم';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                TextFormField(
                  key: const ValueKey('account-profile-email-field'),
                  controller: _emailController,
                  readOnly: true,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: AppTheme.space5),
                const Text(
                  'الصورة الرمزية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                const Text(
                  'اختر صورة رمزية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                AccountAvatarPicker(
                  selectedAvatarId: _selectedAvatarId,
                  onChanged: (avatarId) {
                    setState(() {
                      _selectedAvatarId = avatarId;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ElevatedButton(
          key: const ValueKey('account-profile-save-button'),
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: Text(
            isLoading ? 'جارٍ الحفظ...' : 'حفظ التغييرات',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountPasswordDialog extends StatefulWidget {
  const _AccountPasswordDialog();

  @override
  State<_AccountPasswordDialog> createState() => _AccountPasswordDialogState();
}

class _AccountPasswordDialogState extends State<_AccountPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await auth.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    if (!mounted) return;

    if (success) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'تم تغيير كلمة المرور بنجاح',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'حدث خطأ. حاول مرة أخرى.',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AlertDialog(
      title: const Text(
        'تغيير كلمة المرور',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogPasswordField(
                  fieldKey: const ValueKey('account-current-password-field'),
                  controller: _currentController,
                  label: 'كلمة المرور الحالية',
                  obscure: _obscureCurrent,
                  onToggle: () {
                    setState(() {
                      _obscureCurrent = !_obscureCurrent;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'أدخل كلمة المرور الحالية';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space4),
                _DialogPasswordField(
                  fieldKey: const ValueKey('account-new-password-field'),
                  controller: _newController,
                  label: 'كلمة المرور الجديدة',
                  obscure: _obscureNew,
                  onToggle: () {
                    setState(() {
                      _obscureNew = !_obscureNew;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'أدخل كلمة المرور الجديدة';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.space4),
                _DialogPasswordField(
                  fieldKey: const ValueKey('account-confirm-password-field'),
                  controller: _confirmController,
                  label: 'تأكيد كلمة المرور',
                  obscure: _obscureConfirm,
                  onToggle: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'أكد كلمة المرور الجديدة';
                    }
                    if (value != _newController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ElevatedButton(
          key: const ValueKey('account-password-save-button'),
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: Text(
            isLoading ? 'جارٍ الحفظ...' : 'تغيير كلمة المرور',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogPasswordField extends StatelessWidget {
  const _DialogPasswordField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
