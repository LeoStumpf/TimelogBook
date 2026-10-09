// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../data/session_repository.dart';
import '../models/session.dart';
import '../util/format.dart';
import 'logbook_model.dart';

/// Opens the editor for [session], or for a new entry on [day].
/// Shows an undo snackbar when an entry is deleted.
Future<void> editSession(
  BuildContext context,
  LogbookModel model, {
  Session? session,
  required String day,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final deleted = await showDialog<Session>(
    context: context,
    builder: (_) => _EditSessionDialog(model: model, session: session, day: day),
  );
  if (deleted == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: const Text('Entry deleted'),
      action: SnackBarAction(label: 'Undo', onPressed: () => model.restore(deleted)),
    ),
  );
}

class _EditSessionDialog extends StatefulWidget {
  const _EditSessionDialog({required this.model, required this.session, required this.day});

  final LogbookModel model;
  final Session? session;
  final String day;

  @override
  State<_EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<_EditSessionDialog> {
  // Full timestamps, so an unchanged entry keeps its seconds.
  late DateTime _start;
  DateTime? _end;
  String? _error;

  bool get _isNew => widget.session == null;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    if (s != null) {
      _start = s.start;
      _end = s.end;
    } else {
      final day = parseDayKey(widget.day);
      final now = DateTime.now();
      final end = DateUtils.isSameDay(day, now)
          ? _onDay(now, now.hour, now.minute)
          : _onDay(day, 12, 0);
      _end = end;
      _start = end.subtract(const Duration(hours: 1));
    }
  }

  static DateTime _onDay(DateTime day, int hour, int minute, [int second = 0]) =>
      DateTime(day.year, day.month, day.day, hour, minute, second);

  /// Puts the time of [end] on the start day, or on the next day if it would
  /// not be after the start.
  DateTime _fixEnd(DateTime end) {
    final sameDay = _onDay(_start, end.hour, end.minute, end.second);
    if (sameDay.isAfter(_start)) return sameDay;
    final next = DateTime(_start.year, _start.month, _start.day + 1);
    return _onDay(next, end.hour, end.minute, end.second);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(_start),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _start = _onDay(picked, _start.hour, _start.minute, _start.second);
      if (_end != null) _end = _fixEnd(_end!);
    });
  }

  Future<TimeOfDay?> _pickTime(DateTime initial) => showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );

  Future<void> _save() async {
    final s = (widget.session ?? Session(start: _start)).copyWith(
      start: _start,
      end: _end,
      clearEnd: _end == null,
    );
    try {
      await widget.model.save(s);
      if (mounted) Navigator.pop(context);
    } on SessionValidationException catch (e) {
      setState(() => _error = e.message);
    }
  }

  Future<void> _delete() async {
    final s = widget.session!;
    await widget.model.delete(s);
    if (mounted) Navigator.pop(context, s);
  }

  @override
  Widget build(BuildContext context) {
    final end = _end;
    return AlertDialog(
      title: Text(_isNew ? 'Add entry' : 'Edit entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: Text(formatDay(_start)),
            onTap: _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.play_arrow),
            title: const Text('Start'),
            trailing: Text(formatTime(_start), style: Theme.of(context).textTheme.titleMedium),
            onTap: () async {
              final t = await _pickTime(_start);
              if (t == null) return;
              setState(() {
                _start = _onDay(_start, t.hour, t.minute);
                if (_end != null) _end = _fixEnd(_end!);
              });
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.stop),
            title: const Text('End'),
            trailing: Text(
              end == null
                  ? 'running'
                  : '${formatTime(end)}${DateUtils.isSameDay(end, _start) ? '' : ' (+1 day)'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () async {
              final t = await _pickTime(_end ?? DateTime.now());
              if (t != null) setState(() => _end = _fixEnd(_onDay(_start, t.hour, t.minute)));
            },
          ),
          if (end != null)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Duration ${formatDuration(end.difference(_start))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      actions: [
        if (!_isNew)
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
