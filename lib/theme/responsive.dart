import 'package:flutter/widgets.dart';

/// Simple, dependency-free responsive helpers so the site looks great on
/// phones, tablets, and desktops.
class Breakpoints {
  const Breakpoints._();

  static const double mobile = 640;
  static const double tablet = 1024;

  /// Maximum content width so text never stretches uncomfortably wide.
  static const double maxContentWidth = 1180;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < Breakpoints.mobile;
  bool get isTablet =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.tablet;
  bool get isDesktop => screenWidth >= Breakpoints.tablet;

  /// Horizontal page padding that grows with the viewport.
  double get pagePadding {
    if (isMobile) return 20;
    if (isTablet) return 40;
    return 64;
  }

  /// Choose a value based on the current breakpoint.
  T responsive<T>({required T mobile, T? tablet, required T desktop}) {
    if (isMobile) return mobile;
    if (isTablet) return tablet ?? desktop;
    return desktop;
  }
}
