import 'package:flutter/material.dart';

import '../theme/responsive.dart';

/// Constrains content to a comfortable reading width and applies responsive
/// horizontal padding. Wrap page sections in this for consistent margins.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
          child: child,
        ),
      ),
    );
  }
}

/// A full-width section with vertical rhythm and an optional background color.
class Section extends StatelessWidget {
  final Widget child;
  final Color? background;
  final double? maxWidth;

  const Section({
    super.key,
    required this.child,
    this.background,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final vertical = context.responsive<double>(
      mobile: 56,
      tablet: 80,
      desktop: 104,
    );
    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: ContentWidth(
        maxWidth: maxWidth ?? Breakpoints.maxContentWidth,
        child: child,
      ),
    );
  }
}
