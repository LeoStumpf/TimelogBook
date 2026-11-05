// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../domain/day_summary.dart';
import '../models/session.dart';
import '../util/format.dart';
import 'app_theme.dart';

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
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
              color: highlight ? theme.colorScheme.primary : null,
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Entries" with the button to add one.
class EntriesHeader extends StatelessWidget {
  const EntriesHeader({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Entries',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add entry', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// The entries of one day as a card (oldest first).
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
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, s) in sessions.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            _SessionRow(session: s, now: now, onTap: onTap == null ? null : () => onTap!(s)),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.now, this.onTap});

  final Session session;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontFeatures: tabularFigures,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.isRunning ? theme.colorScheme.tertiary : theme.colorScheme.primary,
              ),
              child: const SizedBox.square(dimension: 10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${formatTime(s.start)} – ${s.isRunning ? 'running' : formatTime(s.end!)}'
                '${!s.isRunning && s.day != dayKey(s.end!) ? ' (+1 day)' : ''}',
                style: style,
              ),
            ),
            Text(
              formatDuration(s.durationAt(now)),
              style: style?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
