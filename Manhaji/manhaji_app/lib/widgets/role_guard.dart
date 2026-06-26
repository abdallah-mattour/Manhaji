import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/gate/unauthorized_screen.dart';

/// Wraps a route builder and enforces role-based access control.
///
/// Import chain (no cycles):
///   routes.dart → role_guard.dart → unauthorized_screen.dart
///                                 → auth_provider.dart
///
/// Three outcomes:
///   1. Not logged in  → blank frame, then redirected to /login (stack cleared).
///   2. Wrong role     → UnauthorizedScreen shown inline; "go home" navigates
///                       to the correct home for the current role.
///   3. Correct role   → child rendered normally.
class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  final List<String> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (_) => false);
        }
      });
      return const SizedBox.shrink();
    }

    if (!allowedRoles.contains(auth.userRole)) {
      return UnauthorizedScreen(
        onGoHome: () => Navigator.of(context).pushNamedAndRemoveUntil(
          _roleHomeRoute(auth.userRole),
          (_) => false,
        ),
      );
    }

    return child;
  }
}

/// Returns the correct home route for [role], mirroring AppRoutes.homeForRole
/// but using raw string literals to avoid importing routes.dart.
String _roleHomeRoute(String? role) {
  if (role == null) return '/login';
  final isStaff = role == 'TEACHER' || role == 'ADMIN';
  final isLearner = role == 'STUDENT' || role == 'PARENT';
  if (kIsWeb && isLearner) return '/platform-mismatch';
  if (!kIsWeb && isStaff) return '/platform-mismatch';
  return switch (role) {
    'TEACHER' => '/teacher',
    'ADMIN' => '/admin',
    'PARENT' => '/parent',
    _ => '/home',
  };
}
