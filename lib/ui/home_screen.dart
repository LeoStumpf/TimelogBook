// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/day_summary.dart';
import '../models/session.dart';
import '../services/csv_export.dart';
import '../util/format.dart';
import 'day_view.dart';
import 'edit_session_dialog.dart';
import 'history_screen.dart';
import 'logbook_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.model});

  final LogbookModel model;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _ticker;

  LogbookModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    model.addListener(_onModelChanged);
    _onModelChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    model.removeListener(_onModelChanged);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      model.reload();
      model.services.logging.restoreNotification();
      _updateTicker();
    } else if (state == AppLifecycleState.paused) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _onModelChanged() {
    _updateTicker();
    setState(() {});
  }

  /// Ticks every second while logging, so the total counts up live.
  void _updateTicker() {
    if (model.isRunning) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _export() async {
    final now = DateTime.now();
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Export as CSV')),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('This month'),
              onTap: () => Navigator.pop(context, dayKey(DateTime(now.year, now.month))),
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Everything'),
              onTap: () => Navigator.pop(context, ''),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    await shareCsv(model.services.repo, fromDay: choice.isEmpty ? null : choice);
  }

  void _about() => showAboutDialog(
    context: context,
    applicationName: 'Timelog Book',
    applicationLegalese:
        'Free software under the GNU AGPL v3 or later.\n'
        'No ads, no tracking. Your data stays on your device.',
  );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final summary = DaySummary.of(model.sessions, now);
    final theme = Theme.of(context);
    final running = model.isRunning;
    final isToday = model.day == dayKey(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timelog Book'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HistoryScreen(model: model)),
            ),
          ),
          PopupMenuButton<void Function()>(
            onSelected: (action) => action(),
            itemBuilder: (_) => [
              PopupMenuItem(value: _export, child: const Text('Export CSV')),
              PopupMenuItem(value: _about, child: const Text('About')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Add entry',
        onPressed: () => editSession(context, model, day: model.day),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 88),
        children: [
          Text(
            isToday ? 'Time total' : 'Time total · ${formatDay(parseDayKey(model.day))}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          Text(
            formatDuration(summary.total, seconds: running),
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: SizedBox.square(
              dimension: 200,
              child: FilledButton(
                onPressed: model.toggle,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: running ? theme.colorScheme.error : theme.colorScheme.primary,
                  foregroundColor: running
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimary,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(running ? Icons.stop : Icons.play_arrow, size: 64),
                    Text(
                      running ? 'Stop logging' : 'Start logging',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: running ? theme.colorScheme.onError : theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SummaryRow(summary: summary),
          const Divider(height: 32),
          SessionList(
            sessions: model.sessions,
            now: now,
            onTap: (s) => editSession(context, model, session: s, day: model.day),
          ),
        ],
      ),
    );
  }
}
