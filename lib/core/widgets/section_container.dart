import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../config/settings_providers.dart';

/// Centers content with a max width and consistent horizontal padding so
/// pages read well on both a phone and a wide desktop browser.
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
    // Material rather than a plain ColoredBox: ListTile/InkWell paint their
    // ink onto the nearest Material ancestor, so a bare colored box here
    // would silently swallow every tap ripple inside the section.
    return Material(
      color: backgroundColor ?? Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: padding ??
            EdgeInsets.symmetric(horizontal: isMobile ? 20 : 48, vertical: isMobile ? 40 : 72),
        child: Center(
          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
        ),
      ),
    );
  }
}

/// The colored page banner used at the top of every interior page.
/// Reads its color from live church settings rather than a constant.
class PageBanner extends ConsumerWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final Widget? below;
  final Color? color;
  final String? eyebrow;

  const PageBanner({
    super.key,
    required this.title,
    this.subtitle = '',
    this.action,
    this.below,
    this.color,
    this.eyebrow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = Breakpoints.isMobile(context);
    final background = color ?? ref.watch(settingsProvider).colors.primary;

    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 60, vertical: isMobile ? 40 : 64),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!.toUpperCase(),
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .displayMedium
                ?.copyWith(color: Colors.white, fontSize: isMobile ? 32 : 40),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
          if (below != null) ...[const SizedBox(height: 24), below!],
        ],
      ),
    );
  }
}
