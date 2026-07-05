import 'package:flutter/foundation.dart';

enum RolePlatformTarget { mobile, web, unsupported }

class RolePlatformPolicy {
  static const String studentRole = 'STUDENT';
  static const String parentRole = 'PARENT';
  static const String teacherRole = 'TEACHER';
  static const String adminRole = 'ADMIN';

  static const Set<String> _mobileRoles = {studentRole, parentRole};
  static const Set<String> _webRoles = {teacherRole, adminRole};

  static bool get isMobileAppRuntime {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  /// Desktop builds are treated as a web/admin testing runtime.
  static bool get isWebAppRuntime {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => true,
      _ => false,
    };
  }

  static String? normalizeRole(String? role) {
    final normalized = role?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  static bool isRoleAllowedOnCurrentPlatform(String? role) {
    final normalized = normalizeRole(role);
    if (_mobileRoles.contains(normalized)) return isMobileAppRuntime;
    if (_webRoles.contains(normalized)) return isWebAppRuntime;
    return false;
  }

  static RolePlatformTarget targetForRole(String? role) {
    final normalized = normalizeRole(role);
    if (_mobileRoles.contains(normalized)) return RolePlatformTarget.mobile;
    if (_webRoles.contains(normalized)) return RolePlatformTarget.web;
    return RolePlatformTarget.unsupported;
  }

  static String unsupportedMessageForRole(String? role) {
    return switch (targetForRole(role)) {
      RolePlatformTarget.mobile => 'هذا الحساب مخصص لاستخدام تطبيق الهاتف.',
      RolePlatformTarget.web => 'هذا الحساب مخصص لاستخدام نسخة الويب.',
      RolePlatformTarget.unsupported => 'هذا الحساب غير مدعوم على هذه النسخة.',
    };
  }
}

bool get isMobileAppRuntime => RolePlatformPolicy.isMobileAppRuntime;
bool get isWebAppRuntime => RolePlatformPolicy.isWebAppRuntime;

bool isRoleAllowedOnCurrentPlatform(String? role) {
  return RolePlatformPolicy.isRoleAllowedOnCurrentPlatform(role);
}
