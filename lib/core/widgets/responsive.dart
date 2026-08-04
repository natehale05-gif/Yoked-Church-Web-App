import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Side by side on a laptop, stacked on a phone.
///
/// Most of this app's layout problems are the same shape: two or three
/// form fields in a `Row`, which becomes ninety pixels each on a phone -
/// or overflows outright when one of them cannot shrink.
///
/// Children are passed **unwrapped**. This widget adds the `Expanded`
/// itself when it lays out horizontally, because an `Expanded` handed in
/// from outside would crash the moment the same children are put in a
/// `Column`.
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;

  /// Flex per child when laid out as a row. Defaults to 1 each. A shorter
  /// list is padded with 1s, so `flex: const [2]` widens only the first.
  final List<int> flex;

  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.flex = const [],
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  int _flexAt(int index) => index < flex.length ? flex[index] : 1;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    if (Breakpoints.isMobile(context)) {
      return Column(
        // Stretch so a field that was `Expanded` in the row still fills
        // the width rather than shrinking to its intrinsic size.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing * 0.75),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(flex: _flexAt(i), child: children[i]),
        ],
      ],
    );
  }
}

/// Detail on the left, a control on the right - the control underneath on
/// a phone.
///
/// [ResponsiveRow] is the wrong tool when one side is a button: it wraps
/// every child in an `Expanded`, so the button stretches to a share of the
/// row instead of sizing to its label. Here only the detail flexes.
///
/// Without this the button takes whatever width it wants and the text gets
/// the remainder, which on a 390px screen is how "Request to join" left
/// twenty-one pixels for a group's name. The control moves below the
/// breakpoint and sits at the right, matching `AdminListTile`.
class DetailWithAction extends StatelessWidget {
  final Widget child;
  final Widget action;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const DetailWithAction({
    super.key,
    required this.child,
    required this.action,
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          SizedBox(height: spacing * 0.75),
          Align(alignment: Alignment.centerRight, child: action),
        ],
      );
    }

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [Expanded(child: child), SizedBox(width: spacing), action],
    );
  }
}

/// A label-and-value pair that stops fighting for width on a phone.
///
/// A fixed label column reads well at desk width and leaves about a
/// hundred pixels for the answer on a phone. Below the breakpoint the
/// label moves above its value instead.
class LabelledValue extends StatelessWidget {
  final Widget label;
  final Widget value;
  final double labelWidth;

  const LabelledValue({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [label, const SizedBox(height: 2), value],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: labelWidth, child: label),
        const SizedBox(width: 12),
        Expanded(child: value),
      ],
    );
  }
}
