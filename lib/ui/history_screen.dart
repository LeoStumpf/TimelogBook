// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../domain/day_summary.dart';
import '../models/session.dart';
import '../util/format.dart';
import 'day_view.dart';
import 'edit_session_dialog.dart';
import 'logbook_model.dart';

/// All days with entries, newest first.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.model});

  final LogbookModel model;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) => FutureBuilder<List<Session>>(
          future: model.services.repo.all(),
          builder: (context, snapshot) {
            final sessions = snapshot.data;
            if (sessions == null) return const Center(child: CircularProgressIndicator());
            if (sessions.isEmpty) return const Center(child: Text('No entries yet.'));
            final byDay = <String, List<Session>>{};
            for (final s in sessions) {
              (byDay[s.day] ??= []).add(s);
            }
            final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
            final now = DateTime.now();
            return ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, i) {
                final day = days[i];
                final summary = DaySummary.of(byDay[day]!, now);
                final end = summary.correctedEnd;
                final count = byDay[day]!.length;
                return ListTile(
                  title: Text(formatDay(parseDayKey(day))),
                  subtitle: Text(
                    '${formatTime(summary.firstStart!)} – ${end == null ? '' : formatTime(end)}'
                    ' corrected · $count ${count == 1 ? 'entry' : 'entries'}',
                  ),
                  trailing: Text(
                    formatDuration(summary.total),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DayScreen(model: model, day: day),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The entries of one past day, editable.
class DayScreen extends StatelessWidget {
  const DayScreen({super.key, required this.model, required this.day});

  final LogbookModel model;
  final String day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(formatDay(parseDayKey(day)))),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Add entry',
        onPressed: () => editSession(context, model, day: day),
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) => FutureBuilder<List<Session>>(
          future: model.sessionsFor(day),
          builder: (context, snapshot) {
            final sessions = snapshot.data;
            if (sessions == null) return const Center(child: CircularProgressIndicator());
            final now = DateTime.now();
            final summary = DaySummary.of(sessions, now);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 88),
              children: [
                Text(
                  'Time total',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  formatDuration(summary.total),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 24),
                SummaryRow(summary: summary),
                const Divider(height: 32),
                SessionList(
                  sessions: sessions,
                  now: now,
                  onTap: (s) => editSession(context, model, session: s, day: day),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
