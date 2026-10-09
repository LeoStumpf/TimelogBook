// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:intl/intl.dart';

/// `7:05` (or `7:05:09` with [seconds]). Negative durations are clamped to zero.
String formatDuration(Duration d, {bool seconds = false}) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  if (!seconds) return '$h:$m';
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

/// `07:05`
String formatTime(DateTime t) => DateFormat.Hm().format(t);

/// `Fri, 9 Oct 2026`
String formatDay(DateTime t) => DateFormat('EEE, d MMM y').format(t);
