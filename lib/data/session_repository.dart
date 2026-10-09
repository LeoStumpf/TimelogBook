// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/session.dart';

class SessionValidationException implements Exception {
  SessionValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Checks [s] against all other stored sessions. Returns an error message or null.
String? validateSession(Session s, Iterable<Session> others) {
  final end = s.end;
  if (end != null && !end.isAfter(s.start)) return 'End must be after start.';
  final far = DateTime(9999);
  for (final o in others) {
    if (o.id != null && o.id == s.id) continue;
    if (s.isRunning && o.isRunning) return 'Another entry is already running.';
    final overlaps = s.start.isBefore(o.end ?? far) && o.start.isBefore(end ?? far);
    if (overlaps) return 'Overlaps with another entry.';
  }
  return null;
}

/// Stores sessions in SQLite. Times are stored as epoch milliseconds.
class SessionRepository {
  SessionRepository._(this._db);

  final Database _db;

  static const _table = 'sessions';

  static Future<SessionRepository> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), 'timelogbook.db');
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: true,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE $_table (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              start_ms INTEGER NOT NULL,
              end_ms INTEGER,
              day TEXT NOT NULL
            )''');
          await db.execute('CREATE INDEX idx_sessions_day ON $_table(day)');
        },
      ),
    );
    return SessionRepository._(db);
  }

  Future<void> close() => _db.close();

  Future<Session?> running() async {
    final rows = await _db.query(_table, where: 'end_ms IS NULL', limit: 1);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// Starts a new session at [now], or returns the one already running.
  Future<Session> start(DateTime now) async {
    final current = await running();
    if (current != null) return current;
    return insert(Session(start: now));
  }

  /// Stops the running session at [now]. Returns it, or null if none was running.
  Future<Session?> stop(DateTime now) async {
    final current = await running();
    if (current == null) return null;
    // Guard against clock changes making the end lie before the start.
    final end = now.isAfter(current.start) ? now : current.start.add(const Duration(seconds: 1));
    final stopped = current.copyWith(end: end);
    await _db.update(_table, _toRow(stopped), where: 'id = ?', whereArgs: [current.id]);
    return stopped;
  }

  /// Inserts [s] (keeping its id if set, e.g. to undo a delete).
  Future<Session> insert(Session s) async {
    await _validate(s);
    final row = _toRow(s);
    if (s.id != null) row['id'] = s.id;
    final id = await _db.insert(_table, row);
    return s.copyWith(id: id);
  }

  Future<void> update(Session s) async {
    await _validate(s);
    await _db.update(_table, _toRow(s), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<void> delete(int id) => _db.delete(_table, where: 'id = ?', whereArgs: [id]);

  Future<List<Session>> forDay(String day) async {
    final rows = await _db.query(_table, where: 'day = ?', whereArgs: [day], orderBy: 'start_ms');
    return rows.map(_fromRow).toList();
  }

  /// All sessions, oldest first. Optionally limited to days in [fromDay]..[toDay].
  Future<List<Session>> all({String? fromDay, String? toDay}) async {
    final where = <String>[];
    final args = <Object>[];
    if (fromDay != null) {
      where.add('day >= ?');
      args.add(fromDay);
    }
    if (toDay != null) {
      where.add('day <= ?');
      args.add(toDay);
    }
    final rows = await _db.query(
      _table,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'start_ms',
    );
    return rows.map(_fromRow).toList();
  }

  Future<void> _validate(Session s) async {
    // Only running sessions and sessions overlapping [s] can conflict with it.
    final from = s.start.millisecondsSinceEpoch;
    final to = (s.end ?? DateTime(9999)).millisecondsSinceEpoch;
    final rows = await _db.query(
      _table,
      where: '(end_ms IS NULL OR end_ms > ?) AND start_ms < ?',
      whereArgs: [from, to],
    );
    final error = validateSession(s, rows.map(_fromRow));
    if (error != null) throw SessionValidationException(error);
  }

  static Session _fromRow(Map<String, Object?> row) => Session(
    id: row['id'] as int,
    start: DateTime.fromMillisecondsSinceEpoch(row['start_ms'] as int),
    end: row['end_ms'] == null ? null : DateTime.fromMillisecondsSinceEpoch(row['end_ms'] as int),
  );

  static Map<String, Object?> _toRow(Session s) => {
    'start_ms': s.start.millisecondsSinceEpoch,
    'end_ms': s.end?.millisecondsSinceEpoch,
    'day': s.day,
  };
}
