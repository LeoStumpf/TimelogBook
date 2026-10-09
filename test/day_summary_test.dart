// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:timelogbook/domain/day_summary.dart';
import 'package:timelogbook/models/session.dart';

DateTime t(int h, int m, [int day = 9]) => DateTime(2026, 10, day, h, m);

void main() {
  test('empty day', () {
    final s = DaySummary.of([], t(12, 0));
    expect(s.total, Duration.zero);
    expect(s.breaks, Duration.zero);
    expect(s.correctedEnd, isNull);
  });

  test('07:20–15:20 with a one hour break ends corrected at 14:20', () {
    final s = DaySummary.of([
      Session(start: t(11, 30), end: t(15, 20)),
      Session(start: t(7, 20), end: t(10, 30)),
    ], t(16, 0));
    expect(s.firstStart, t(7, 20));
    expect(s.lastEnd, t(15, 20));
    expect(s.breaks, const Duration(hours: 1));
    expect(s.total, const Duration(hours: 7));
    expect(s.correctedEnd, t(14, 20));
  });

  test('running session counts up to now', () {
    final s = DaySummary.of([
      Session(start: t(8, 0), end: t(9, 0)),
      Session(start: t(9, 30)),
    ], t(10, 0));
    expect(s.total, const Duration(hours: 1, minutes: 30));
    expect(s.breaks, const Duration(minutes: 30));
    expect(s.lastEnd, t(10, 0));
    expect(s.correctedEnd, t(9, 30));
  });

  test('session over midnight belongs to its start day', () {
    final session = Session(start: t(22, 0), end: t(1, 0, 10));
    expect(session.day, '2026-10-09');
    expect(DaySummary.of([session], t(2, 0, 10)).total, const Duration(hours: 3));
  });
}
