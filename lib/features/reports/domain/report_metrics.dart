import 'package:flutter/foundation.dart';

/// A number for a recent window, next to the same-length window before
/// it.
///
/// Two windows rather than a running total because a church's question is
/// never "how many altogether" - it is "are we going up or down". The
/// comparison is only ever like-for-like: both windows are the same
/// length, so a partial month can't masquerade as a decline.
@immutable
class Trend {
  final double current;
  final double previous;

  const Trend({required this.current, required this.previous});

  /// Whether there is anything honest to compare against. A church in
  /// its first quarter has no prior window, and inventing "+100%" from a
  /// zero baseline is a lie dressed as a metric.
  bool get hasBaseline => previous > 0;

  double? get changeRatio => hasBaseline ? (current - previous) / previous : null;

  /// "+12%" / "-8%" / null when there is no baseline.
  String? get changeLabel {
    final ratio = changeRatio;
    if (ratio == null) return null;
    final percent = (ratio * 100).round();
    if (percent == 0) return 'level';
    return percent > 0 ? '+$percent%' : '$percent%';
  }

  bool get isUp => (changeRatio ?? 0) > 0;
  bool get isDown => (changeRatio ?? 0) < 0;
}

/// Total [valueOf] over the last [window], and over the [window] before
/// that.
///
/// Half-open on both ends so a record on the boundary is counted exactly
/// once, in the newer window.
Trend trendOver<T>(
  Iterable<T> items, {
  required DateTime Function(T item) dateOf,
  double Function(T item)? valueOf,
  required DateTime now,
  Duration window = const Duration(days: 90),
}) {
  final currentFrom = now.subtract(window);
  final previousFrom = currentFrom.subtract(window);

  var current = 0.0;
  var previous = 0.0;
  for (final item in items) {
    final at = dateOf(item);
    final value = valueOf?.call(item) ?? 1;
    if (!at.isBefore(currentFrom) && !at.isAfter(now)) {
      current += value;
    } else if (!at.isBefore(previousFrom) && at.isBefore(currentFrom)) {
      previous += value;
    }
  }
  return Trend(current: current, previous: previous);
}

/// How much of the congregation is involved in something.
@immutable
class Participation {
  final int engaged;
  final int total;

  const Participation({required this.engaged, required this.total});

  /// Null rather than zero when there is nobody to divide by: an empty
  /// church is not a church with 0% participation.
  double? get ratio => total == 0 ? null : engaged / total;

  String get label => total == 0 ? '—' : '$engaged of $total';

  String? get percentLabel {
    final r = ratio;
    return r == null ? null : '${(r * 100).round()}%';
  }
}

/// One line on the reports page.
@immutable
class Metric {
  final String label;
  final String value;
  final String detail;
  final Trend? trend;

  const Metric({
    required this.label,
    required this.value,
    this.detail = '',
    this.trend,
  });
}
