// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timelogbook/data/session_repository.dart';
import 'package:timelogbook/models/session.dart';

DateTime t(int h, int m, [int day = 9]) => DateTime(2026, 10, day, h, m);

void main() {
  late SessionRepository repo;

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    repo = await SessionRepository.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
  });
  tearDown(() => repo.close());

  test('start and stop', () async {
    final started = await repo.start(t(8, 0));
    expect(await repo.running(), started);
    // Starting again keeps the running session.
    expect(await repo.start(t(8, 5)), started);

    final stopped = await repo.stop(t(9, 0));
    expect(stopped!.end, t(9, 0));
    expect(await repo.running(), isNull);
    expect(await repo.stop(t(9, 5)), isNull);
    expect(await repo.forDay('2026-10-09'), [stopped]);
  });

  test('rejects overlapping and inverted entries', () async {
    await repo.insert(Session(start: t(8, 0), end: t(10, 0)));
    expect(
      () => repo.insert(Session(start: t(9, 0), end: t(11, 0))),
      throwsA(isA<SessionValidationException>()),
    );
    expect(
      () => repo.insert(Session(start: t(12, 0), end: t(11, 0))),
      throwsA(isA<SessionValidationException>()),
    );
    // Touching entries are fine.
    await repo.insert(Session(start: t(10, 0), end: t(11, 0)));
  });

  test('only one running entry, and nothing may start after it', () async {
    await repo.start(t(8, 0));
    expect(() => repo.insert(Session(start: t(9, 0))), throwsA(isA<SessionValidationException>()));
    expect(
      () => repo.insert(Session(start: t(9, 0), end: t(9, 30))),
      throwsA(isA<SessionValidationException>()),
    );
    // Entries before the running one are fine.
    await repo.insert(Session(start: t(7, 0), end: t(7, 30)));
  });

  test('update, delete and restore keep the id', () async {
    final s = await repo.insert(Session(start: t(8, 0), end: t(9, 0)));
    await repo.update(s.copyWith(end: t(9, 30)));
    expect((await repo.forDay(s.day)).single.end, t(9, 30));

    await repo.delete(s.id!);
    expect(await repo.forDay(s.day), isEmpty);
    await repo.insert(s);
    expect((await repo.forDay(s.day)).single.id, s.id);
  });

  test('all() filters by day', () async {
    await repo.insert(Session(start: t(8, 0, 1), end: t(9, 0, 1)));
    await repo.insert(Session(start: t(8, 0, 9), end: t(9, 0, 9)));
    expect(await repo.all(), hasLength(2));
    expect((await repo.all(fromDay: '2026-10-05')).single.day, '2026-10-09');
  });
}
