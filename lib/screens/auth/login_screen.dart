import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_text_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPhoneLogin = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    bool success;

    if (_isPhoneLogin) {
      success = await auth.loginWithPhone(
        phone: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await auth.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'مرحباً بك في منهجي',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سجّل دخولك للمتابعة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Toggle phone/email
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPhoneLogin = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isPhoneLogin
                                  ? AppColors.primary
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'البريد الإلكتروني',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                color: !_isPhoneLogin
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPhoneLogin = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isPhoneLogin
                                  ? AppColors.primary
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'رقم الهاتف',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                color: _isPhoneLogin
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email/Phone field
                  // حقل الإيميل أو الهاتف
                  AppTextFormField(
                    controller: _emailController,
                    labelText: _isPhoneLogin
                        ? 'رقم الهاتف'
                        : 'البريد الإلكتروني',
                    keyboardType: _isPhoneLogin
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    textDirection: TextDirection.ltr, // ← هنا فقط
                    prefixIcon: Icon(
                      _isPhoneLogin ? Icons.phone : Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _isPhoneLogin
                            ? 'أدخل رقم الهاتف'
                            : 'أدخل البريد الإلكتروني';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  AppTextFormField(
                    controller: _passwordController,
                    labelText: 'كلمة المرور',
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'أدخل كلمة المرور';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              auth.errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Login button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return ElevatedButton(
                        onPressed: auth.isLoading ? null : _login,
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('تسجيل الدخول'),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Google sign in
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Google sign-in
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text(
                      'تسجيل الدخول بحساب Google',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ليس لديك حساب؟',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text(
                          'سجّل الآن',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
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
