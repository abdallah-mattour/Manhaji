import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/mascot.dart';

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
      final role = auth.userRole;
      Navigator.of(context)
          .pushReplacementNamed(AppRoutes.homeForRole(role));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hakeem owl in a soft olive disc — same brand anchor as
                  // splash. Smaller than splash so the form has room.
                  Center(
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const AnimatedMascot(
                        mood: MascotMood.happy,
                        size: 110,
                      ),
                    ),
                  ),
                  const AppGap.v5(),
                  const Text(
                    'مرحباً بك في منهجي',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const AppGap.v2(),
                  const Text(
                    'سجّل دخولك للمتابعة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const AppGap.v8(),

                  // Email/phone toggle — clearer states using warm tokens.
                  _LoginMethodToggle(
                    isPhone: _isPhoneLogin,
                    onChanged: (v) => setState(() => _isPhoneLogin = v),
                  ),
                  const AppGap.v6(),

                  // Email/phone field
                  TextFormField(
                    controller: _emailController,
                    textDirection: TextDirection.ltr,
                    keyboardType: _isPhoneLogin
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          _isPhoneLogin ? 'رقم الهاتف' : 'البريد الإلكتروني',
                      prefixIcon: Icon(
                        _isPhoneLogin
                            ? Icons.phone_rounded
                            : Icons.email_outlined,
                        color: AppTheme.primaryGreen,
                      ),
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
                  const AppGap.v4(),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppTheme.textGray,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'أدخل كلمة المرور';
                      }
                      return null;
                    },
                  ),
                  const AppGap.v5(),

                  // Friendly error in errorContainer tone instead of raw red.
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.errorMessage == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.errorContainer,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusL),
                            border: Border.all(
                              color:
                                  AppTheme.error.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppTheme.error, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  auth.errorMessage!,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AppTheme.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Login button — pulls primary olive from theme.
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
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('تسجيل الدخول'),
                      );
                    },
                  ),
                  const AppGap.v5(),

                  // Register link — clear separation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ليس لديك حساب؟',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGray,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text(
                          'سجّل الآن',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppTheme.primaryGreen,
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

/// Two-segment toggle for email vs phone login. Selected segment is
/// olive-filled with white text; unselected is warm sand with dark text.
/// Generous 14px font + bold so the labels are unmistakable.
class _LoginMethodToggle extends StatelessWidget {
  final bool isPhone;
  final ValueChanged<bool> onChanged;

  const _LoginMethodToggle({
    required this.isPhone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment('البريد الإلكتروني', !isPhone, () => onChanged(false)),
          ),
          Expanded(
            child: _segment('رقم الهاتف', isPhone, () => onChanged(true)),
          ),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        curve: AppTheme.motionCurve,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: selected ? AppTheme.elevationLow : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: selected ? Colors.white : AppTheme.textGray,
          ),
        ),
      ),
    );
  }
}
