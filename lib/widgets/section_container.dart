import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Centers content with a max width and consistent horizontal padding
/// so pages read well on both a phone and a wide desktop browser.
class SectionContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  const SectionContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.maxWidth = 1100,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 48,
            vertical: isMobile ? 40 : 72,
          ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
