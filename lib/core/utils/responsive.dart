import 'package:flutter/material.dart';

class AppBreakpoints {
  const AppBreakpoints._();

  static const double mobileMaxWidth = 599;
  static const double tabletMaxWidth = 1023;
}

enum DeviceType { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  bool get isMobile => screenWidth <= AppBreakpoints.mobileMaxWidth;
  bool get isTablet =>
      screenWidth > AppBreakpoints.mobileMaxWidth &&
      screenWidth <= AppBreakpoints.tabletMaxWidth;
  bool get isDesktop => screenWidth > AppBreakpoints.tabletMaxWidth;

  DeviceType get deviceType {
    if (isDesktop) return DeviceType.desktop;
    if (isTablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}
