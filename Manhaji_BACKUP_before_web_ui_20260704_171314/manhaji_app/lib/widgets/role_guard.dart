import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/gate/unauthorized_screen.dart';
import '../utils/role_platform_policy.dart';

/// Wraps a route builder and enforces role-based access control.
///
/// Import chain (no cycles):
///   routes.dart → role_guard.dart → role_platform_policy.dart
///                                 → unauthorized_screen.dart
///                                 → auth_provider.dart
///
/// Four outcomes:
///   1. Not logged in  → blank frame, then redirected to /login (stack cleared).
///   2. Wrong platform → blank frame, then redirected to /platform-mismatch.
///   3. Wrong role     → UnauthorizedScreen shown inline; "go home" navigates
///                       to the correct home for the current role.
///   4. Correct role   → child rendered normally.
class RoleGuard extends StatelessWidget {
  const RoleGuard({super.key, required this.allowedRoles, required this.child});

  final List<String> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final normalizedRole = RolePlatformPolicy.normalizeRole(auth.userRole);

    if (!auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
        }
      });
      return const SizedBox.shrink();
    }

    if (!RolePlatformPolicy.isRoleAllowedOnCurrentPlatform(normalizedRole)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final navigator = Navigator.of(context);
          navigator.pushNamedAndRemoveUntil('/platform-mismatch', (_) => false);
        }
      });
      return const SizedBox.shrink();
    }

    if (!allowedRoles.contains(normalizedRole)) {
      return UnauthorizedScreen(
        onGoHome: () {
          final navigator = Navigator.of(context);
          navigator.pushNamedAndRemoveUntil(
            _roleHomeRoute(normalizedRole),
            (_) => false,
          );
        },
      );
    }

    return child;
  }
}

/// Returns the correct home route for [role], mirroring AppRoutes.homeForRole
/// but using raw string literals to avoid importing routes.dart.
String _roleHomeRoute(String? role) {
  final normalizedRole = RolePlatformPolicy.normalizeRole(role);
  if (normalizedRole == null) return '/login';
  if (!RolePlatformPolicy.isRoleAllowedOnCurrentPlatform(normalizedRole)) {
    return '/platform-mismatch';
  }
  return switch (normalizedRole) {
    'TEACHER' => '/teacher',
    'ADMIN' => '/admin',
    'PARENT' => '/parent',
    _ => '/home',
  };
}
