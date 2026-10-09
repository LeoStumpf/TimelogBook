// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:timelogbook/models/session.dart';
import 'package:timelogbook/services/csv_export.dart';

void main() {
  test('builds one line per entry', () {
    final csv = buildCsv([
      Session(start: DateTime(2026, 10, 9, 7, 20), end: DateTime(2026, 10, 9, 11, 30)),
      Session(start: DateTime(2026, 10, 9, 12, 0)),
    ]);
    expect(
      csv,
      'date,start,end,duration_minutes\n'
      '2026-10-09,07:20,11:30,250\n'
      '2026-10-09,12:00,,\n',
    );
  });
}
