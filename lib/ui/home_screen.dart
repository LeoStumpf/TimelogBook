// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';

import '../app_info.dart';
import '../domain/day_summary.dart';
import '../models/session.dart';
import '../services/csv_export.dart';
import '../util/format.dart';
import 'app_theme.dart';
import 'day_dial.dart';
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
    applicationVersion: kAppVersion,
    applicationLegalese:
        'Free software under the GNU AGPL v3 or later.\n'
        'No ads, no tracking. Your data stays on your device.\n'
        'Source code: $kSourceUrl',
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
        titleSpacing: 20,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            isToday ? 'Time total' : 'Time total · ${formatDay(parseDayKey(model.day))}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatDuration(summary.total, seconds: running),
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 60,
                height: 68 / 60,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5,
                fontFeatures: tabularFigures,
              ),
            ),
          ),
          const SizedBox(height: 8),
          StartStopDial(
            sessions: model.sessions,
            now: now,
            running: running,
            onPressed: model.toggle,
          ),
          const SizedBox(height: 16),
          SummaryRow(summary: summary),
          const SizedBox(height: 8),
          EntriesHeader(onAdd: () => editSession(context, model, day: model.day)),
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
