// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_text_form_field.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  int _selectedGrade = 1;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      gradeLevel: _selectedGrade,
    );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إنشاء حساب جديد'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppDimensions.paddingL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  const Text(
                    'أهلاً بك!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'أنشئ حسابك لتبدأ رحلة التعلم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // الاسم الكامل
                  AppTextFormField(
                    controller: _nameController,
                    labelText: 'الاسم الكامل',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'أدخل اسمك الكامل'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // البريد الإلكتروني
                  AppTextFormField(
                    controller: _emailController,
                    labelText: 'البريد الإلكتروني',
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'أدخل البريد الإلكتروني';
                      if (!value.contains('@'))
                        return 'أدخل بريد إلكتروني صحيح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // رقم الهاتف
                  AppTextFormField(
                    controller: _phoneController,
                    labelText: 'رقم الهاتف',
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: AppColors.primary,
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'أدخل رقم الهاتف'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // كلمة المرور
                  AppTextFormField(
                    controller: _passwordController,
                    labelText: 'كلمة المرور',
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'أدخل كلمة المرور';
                      if (value.length < 6)
                        return 'كلمة المرور يجب أن تكون ٦ أحرف على الأقل';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // الصف الدراسي
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingL,
                      vertical: AppDimensions.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'الصف الدراسي:',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<int>(
                          value: _selectedGrade,
                          underline: const SizedBox(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          items: [1, 2, 3, 4].map((grade) {
                            return DropdownMenuItem(
                              value: grade,
                              child: Text('الصف $grade'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() => _selectedGrade = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error Message
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.errorMessage != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            auth.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 16),

                  // Register Button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(
                            double.infinity,
                            AppDimensions.buttonHeight,
                          ),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('إنشاء الحساب'),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لديك حساب بالفعل؟'),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text(
                          'سجّل دخولك',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
