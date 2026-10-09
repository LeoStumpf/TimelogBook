// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../domain/day_summary.dart';
import '../models/session.dart';
import '../util/format.dart';

/// "First start · Breaks · Corrected end" for one day.
class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.summary});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    String time(DateTime? t) => t == null ? '–' : formatTime(t);
    return Row(
      children: [
        _SummaryItem(label: 'First start', value: time(summary.firstStart)),
        _SummaryItem(
          label: 'Breaks',
          value: summary.firstStart == null ? '–' : formatDuration(summary.breaks),
        ),
        _SummaryItem(label: 'Corrected end', value: time(summary.correctedEnd), highlight: true),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: highlight ? FontWeight.bold : null,
              color: highlight ? theme.colorScheme.primary : null,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The entries of one day as list tiles (oldest first).
class SessionList extends StatelessWidget {
  const SessionList({super.key, required this.sessions, required this.now, this.onTap});

  final List<Session> sessions;
  final DateTime now;
  final void Function(Session)? onTap;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No entries yet.')),
      );
    }
    final theme = Theme.of(context);
    final tabular = const TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
    return Column(
      children: [
        for (final s in sessions)
          ListTile(
            leading: Icon(
              s.isRunning ? Icons.play_circle : Icons.check_circle_outline,
              color: s.isRunning ? theme.colorScheme.primary : null,
            ),
            title: Text(
              '${formatTime(s.start)} – ${s.isRunning ? 'running' : formatTime(s.end!)}'
              '${!s.isRunning && s.day != dayKey(s.end!) ? ' (+1 day)' : ''}',
              style: tabular,
            ),
            trailing: Text(
              formatDuration(s.durationAt(now)),
              style: theme.textTheme.titleMedium?.merge(tabular),
            ),
            onTap: onTap == null ? null : () => onTap!(s),
          ),
      ],
    );
  }
}
