import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/vibrant_background.dart';

/// Lets a signed-in user change their own password. Three obscured LTR fields
/// with visibility toggles; validators mirror the backend rule (6–72 chars,
/// confirmation matches, new ≠ current). A wrong current password surfaces the
/// backend's Arabic message via the shared [AuthProvider.errorMessage] banner.
/// The JWT session is kept — the backend doesn't revoke tokens on change.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    // The error banner is shared with the login/register flows — clear any
    // stale message before the user starts typing here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

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

    final ok = await auth.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );

    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'تم تغيير كلمة المرور بنجاح ✅',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
        ),
      );
      navigator.pop();
    }
    // On failure the Consumer banner shows auth.errorMessage (Arabic).
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تغيير كلمة المرور'),
          backgroundColor: AppTheme.backgroundLight,
          foregroundColor: AppTheme.textDark,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Icon(Icons.lock_reset_rounded,
                        size: 64, color: AppTheme.primaryGreen),
                    const SizedBox(height: 12),
                    const Text(
                      'اختر كلمة مرور جديدة قوية لحسابك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _passwordField(
                      controller: _currentController,
                      label: 'كلمة المرور الحالية',
                      obscure: _obscureCurrent,
                      onToggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'أدخل كلمة المرور الحالية'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _passwordField(
                      controller: _newController,
                      label: 'كلمة المرور الجديدة',
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'أدخل كلمة المرور الجديدة';
                        }
                        if (v.length < 6) {
                          return 'كلمة المرور يجب أن تكون ٦ أحرف على الأقل';
                        }
                        if (v.length > 72) {
                          return 'كلمة المرور طويلة جداً';
                        }
                        if (v == _currentController.text) {
                          return 'اختر كلمة مرور مختلفة عن الحالية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _passwordField(
                      controller: _confirmController,
                      label: 'تأكيد كلمة المرور الجديدة',
                      obscure: _obscureConfirm,
                      onToggle: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                      validator: (v) => (v != _newController.text)
                          ? 'كلمتا المرور غير متطابقتين'
                          : null,
                    ),
                    const SizedBox(height: 24),

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
                                  color: AppTheme.error.withValues(alpha: 0.4),
                                  width: 1.5),
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

                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return DuolingoButton(
                          onPressed: auth.isLoading ? null : _submit,
                          color: AppTheme.primaryGreen,
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'حفظ كلمة المرور',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.textGray),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
