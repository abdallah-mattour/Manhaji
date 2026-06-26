import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Shown when an authenticated user tries to access a route that is not
/// permitted for their role.
///
/// Accepts [onGoHome] so it has no dependency on routes.dart or role_guard.dart,
/// keeping the import graph acyclic.
class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key, required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 64,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'لا تملك صلاحية الوصول',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'هذه الصفحة غير متاحة لحسابك الحالي.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        height: 1.5,
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onGoHome,
                        icon: const Icon(Icons.home_rounded),
                        label: const Text(
                          'العودة للرئيسية',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
}
