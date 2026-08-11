import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/tenant.dart';

/// One destination inside a section of the app.
typedef Section = ({String label, String path, IconData icon});

/// A row of tabs on a desktop; on a phone, a control that names where you
/// are and opens the whole list.
///
/// Both the staff dashboard and the member portal have more sections than
/// a phone can show at once - nineteen and thirteen. As a horizontal
/// scroller each showed four of them and gave no sign the rest existed,
/// so the dashboard appeared to have four sections and the portal
/// appeared to be Overview, Profile, Groups and My Events.
///
/// Shared rather than copied. The admin side was fixed first and the
/// member side was left with the identical bug for a milestone; one
/// widget is how that stops happening a third time.
class SectionPicker extends StatelessWidget {
  final List<Section> sections;

  /// The current path, already stripped of its church prefix.
  final String current;

  /// The tint for the selected tab in the desktop row. The two banners
  /// this sits in have different backgrounds.
  final Color selectedColor;

  const SectionPicker({
    super.key,
    required this.sections,
    required this.current,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Measured against the space this actually has rather than the
        // window width: the banner is inset, and a tab row that fits a
        // "tablet" can still not fit here.
        final row = _Row(
          sections: sections,
          current: current,
          selectedColor: selectedColor,
        );
        return constraints.maxWidth < 700 ? _Sheet(sections: sections, current: current) : row;
      },
    );
  }
}

class _Row extends StatelessWidget {
  final List<Section> sections;
  final String current;
  final Color selectedColor;

  const _Row({required this.sections, required this.current, required this.selectedColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final section in sections)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => context.go(churchPathFor(context, section.path)),
                style: TextButton.styleFrom(
                  backgroundColor: section.path == current
                      ? selectedColor.withValues(alpha: 0.25)
                      : null,
                  foregroundColor: section.path == current ? selectedColor : Colors.white70,
                ),
                child: Text(
                  section.label,
                  style: TextStyle(
                    fontWeight: section.path == current ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  final List<Section> sections;
  final String current;

  const _Sheet({required this.sections, required this.current});

  @override
  Widget build(BuildContext context) {
    final here = sections.where((s) => s.path == current).firstOrNull ?? sections.first;

    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final section in sections)
                    ListTile(
                      leading: Icon(section.icon),
                      title: Text(section.label),
                      selected: section.path == current,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        context.go(churchPathFor(context, section.path));
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white38),
        ),
        icon: Icon(here.icon, size: 18),
        label: Text(here.label),
      ),
    );
  }
}

/// The church-scoped address of a bare path, from wherever we are.
///
/// The redirect would rewrite a bare `/account/groups` anyway, but going
/// straight to the full address avoids a needless extra navigation and
/// keeps the browser history one entry per tap.
String churchPathFor(BuildContext context, String subPath) {
  final here = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
  final churchId = churchIdFromLocation(here);
  return churchId == null ? subPath : churchPath(churchId, subPath);
}
