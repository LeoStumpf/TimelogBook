// SPDX-License-Identifier: AGPL-3.0-or-later

/// One logged time span. [end] is null while the session is running.
class Session {
  const Session({this.id, required this.start, this.end});

  final int? id;
  final DateTime start;
  final DateTime? end;

  bool get isRunning => end == null;

  /// The local day (`yyyy-MM-dd`) the session belongs to: the day it started.
  String get day => dayKey(start);

  Duration durationAt(DateTime now) => (end ?? now).difference(start);

  Session copyWith({int? id, DateTime? start, DateTime? end, bool clearEnd = false}) => Session(
    id: id ?? this.id,
    start: start ?? this.start,
    end: clearEnd ? null : (end ?? this.end),
  );

  @override
  bool operator ==(Object other) =>
      other is Session && other.id == id && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(id, start, end);

  @override
  String toString() => 'Session($id, $start – $end)';
}

String dayKey(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${_two(t.month)}-${_two(t.day)}';

DateTime parseDayKey(String day) {
  final parts = day.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

String _two(int n) => n.toString().padLeft(2, '0');
