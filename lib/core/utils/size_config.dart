// lib/core/utils/size_config.dart
import 'package:flutter/material.dart';

/// Legacy static sizing utility kept for backward compatibility.
/// Prefer using `ResponsiveContext` from `responsive.dart` in new code.
class SizeConfig {
  static late MediaQueryData mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;

  static late double safeBlockHorizontal;
  static late double safeBlockVertical;

  static bool isTablet = false;
  static bool isLargeScreen = false;

  static void init(BuildContext context) {
    mediaQueryData = MediaQuery.of(context);
    screenWidth = mediaQueryData.size.width;
    screenHeight = mediaQueryData.size.height;

    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;

    final safeHorizontal =
        mediaQueryData.padding.left + mediaQueryData.padding.right;
    final safeVertical =
        mediaQueryData.padding.top + mediaQueryData.padding.bottom;

    safeBlockHorizontal = (screenWidth - safeHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeVertical) / 100;

    isTablet = screenWidth >= 600;
    isLargeScreen = screenWidth >= 900;
  }
}

// Easy extension for responsive values
extension SizeExt on num {
  double get w => SizeConfig.screenWidth * (this / 100);
  double get h => SizeConfig.screenHeight * (this / 100);
}
