import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/vibrant_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.userName ?? '');
    _emailController = TextEditingController(text: auth.userEmail ?? '');
    _phoneController = TextEditingController(text: auth.userPhone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    if (email.isEmpty && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يجب توفير البريد الإلكتروني أو رقم الهاتف',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.primaryRed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      fullName: _nameController.text.trim(),
      email: email.isEmpty ? null : email,
      phone: phone.isEmpty ? null : phone,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تحديث الملف الشخصي بنجاح ✓',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      final error = auth.errorMessage ?? 'حدث خطأ. حاول مرة أخرى.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppTheme.primaryRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل الملف الشخصي'),
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _ProfileField(
                    controller: _nameController,
                    label: 'الاسم الكامل',
                    icon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'أدخل الاسم الكامل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    controller: _emailController,
                    label: 'البريد الإلكتروني',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    ltr: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'أدخل بريدًا إلكترونيًا صحيحًا';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    controller: _phoneController,
                    label: 'رقم الهاتف',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    ltr: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
                      if (!phoneRegex.hasMatch(v.trim())) {
                        return 'أدخل رقم هاتف صحيحًا (7-15 رقمًا)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  DuolingoButton(
                    onPressed: isLoading ? null : _submit,
                    color: AppTheme.primaryGreen,
                    text: isLoading ? 'جارٍ الحفظ...' : 'حفظ التغييرات',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool ltr;
  final String? Function(String?) validator;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.ltr = false,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: AppTheme.textGray,
        ),
        prefixIcon: Icon(icon, color: AppTheme.textGray, size: 20),
        filled: true,
        fillColor: AppTheme.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.surfaceMuted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.surfaceMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.primaryRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: const BorderSide(color: AppTheme.primaryRed, width: 2),
        ),
      ),
    );
  }
}
