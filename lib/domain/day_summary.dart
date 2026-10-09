// SPDX-License-Identifier: AGPL-3.0-or-later

import '../models/session.dart';

/// Totals for the sessions of one day.
class DaySummary {
  const DaySummary({required this.total, required this.breaks, this.firstStart, this.lastEnd});

  factory DaySummary.of(Iterable<Session> sessions, DateTime now) {
    final sorted = sessions.toList()..sort((a, b) => a.start.compareTo(b.start));
    if (sorted.isEmpty) {
      return const DaySummary(total: Duration.zero, breaks: Duration.zero);
    }
    var total = Duration.zero;
    var breaks = Duration.zero;
    DateTime? previousEnd;
    for (final s in sorted) {
      total += s.durationAt(now);
      if (previousEnd != null && s.start.isAfter(previousEnd)) {
        breaks += s.start.difference(previousEnd);
      }
      final end = s.end ?? now;
      if (previousEnd == null || end.isAfter(previousEnd)) previousEnd = end;
    }
    return DaySummary(
      total: total,
      breaks: breaks,
      firstStart: sorted.first.start,
      lastEnd: previousEnd,
    );
  }

  /// Sum of all session durations.
  final Duration total;

  /// Sum of the gaps between sessions.
  final Duration breaks;

  final DateTime? firstStart;

  /// End of the latest session (now, if one is running).
  final DateTime? lastEnd;

  /// The end time without breaks: first start + total.
  DateTime? get correctedEnd => firstStart?.add(total);
}
