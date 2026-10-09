// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/session_repository.dart';
import '../models/session.dart';
import '../util/format.dart';

const csvHeader = 'date,start,end,duration_minutes';

/// One line per entry. Running entries have an empty end and duration.
String buildCsv(Iterable<Session> sessions) {
  final lines = [csvHeader];
  for (final s in sessions) {
    final end = s.end;
    lines.add(
      [
        s.day,
        formatTime(s.start),
        end == null ? '' : formatTime(end),
        end == null ? '' : end.difference(s.start).inMinutes.toString(),
      ].join(','),
    );
  }
  return '${lines.join('\n')}\n';
}

/// Writes the entries from [fromDay] on (or all) to a CSV file and opens the share sheet.
Future<void> shareCsv(SessionRepository repo, {String? fromDay}) async {
  final sessions = await repo.all(fromDay: fromDay);
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, 'timelogbook_${dayKey(DateTime.now())}.csv'));
  await file.writeAsString(buildCsv(sessions));
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Timelog Book export',
    ),
  );
}
