// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../domain/day_summary.dart';
import '../models/session.dart';
import '../util/format.dart';
import 'app_theme.dart';
import 'day_dial.dart';
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
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _DayCard(
                day: days[i],
                sessions: byDay[days[i]]!,
                now: now,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DayScreen(model: model, day: days[i]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One day in the history, with its dial.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.sessions,
    required this.now,
    required this.onTap,
  });

  final String day;
  final List<Session> sessions;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = DaySummary.of(sessions, now);
    final end = summary.correctedEnd;
    final count = sessions.length;
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 48,
                child: DayDial(
                  sessions: sessions,
                  now: now,
                  hourLabels: false,
                  strokeRatio: 7 / 52,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDay(parseDayKey(day)),
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatTime(summary.firstStart!)} – ${end == null ? '' : formatTime(end)}'
                      ' corrected · $count ${count == 1 ? 'entry' : 'entries'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDuration(summary.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: tabularFigures,
                ),
              ),
            ],
          ),
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
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) => FutureBuilder<List<Session>>(
          future: model.sessionsFor(day),
          builder: (context, snapshot) {
            final sessions = snapshot.data;
            if (sessions == null) return const Center(child: CircularProgressIndicator());
            final now = DateTime.now();
            final summary = DaySummary.of(sessions, now);
            final theme = Theme.of(context);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Center(
                  child: SizedBox.square(
                    dimension: 216,
                    child: DayDial(
                      sessions: sessions,
                      now: now,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Time total',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formatDuration(summary.total),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SummaryRow(summary: summary),
                const SizedBox(height: 8),
                EntriesHeader(onAdd: () => editSession(context, model, day: day)),
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
