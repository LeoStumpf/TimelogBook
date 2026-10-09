// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/session.dart';
import '../services/app_services.dart';

/// UI state: the current day and whether logging is running.
class LogbookModel extends ChangeNotifier {
  LogbookModel(this.services) {
    // Notification buttons change the data in another isolate; listen for that.
    IsolateNameServer.removePortNameMapping(uiPortName);
    IsolateNameServer.registerPortWithName(_port.sendPort, uiPortName);
    _port.listen((_) => reload());
  }

  final AppServices services;
  final _port = ReceivePort();

  /// The day shown on the home screen: today, or the day the running entry started.
  String day = dayKey(DateTime.now());
  List<Session> sessions = const [];
  Session? running;
  bool _busy = false;

  bool get isRunning => running != null;

  Future<void> reload() async {
    final repo = services.repo;
    running = await repo.running();
    day = running?.day ?? dayKey(DateTime.now());
    sessions = await repo.forDay(day);
    notifyListeners();
  }

  Future<void> toggle() async {
    if (_busy) return;
    _busy = true;
    try {
      await services.logging.toggle();
    } finally {
      _busy = false;
    }
    await reload();
  }

  /// Inserts or updates [s]. Throws [SessionValidationException] on invalid input.
  Future<void> save(Session s) async {
    final wasRunning = running != null;
    if (s.id == null) {
      await services.repo.insert(s);
    } else {
      await services.repo.update(s);
    }
    await _afterEdit(wasRunning);
  }

  Future<void> delete(Session s) async {
    final wasRunning = running != null;
    await services.repo.delete(s.id!);
    await _afterEdit(wasRunning);
  }

  /// Puts back a deleted entry.
  Future<void> restore(Session s) async {
    final wasRunning = running != null;
    await services.repo.insert(s);
    await _afterEdit(wasRunning);
  }

  Future<List<Session>> sessionsFor(String day) => services.repo.forDay(day);

  Future<void> _afterEdit(bool wasRunning) async {
    await services.logging.syncAfterEdit(wasRunning: wasRunning);
    await reload();
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping(uiPortName);
    _port.close();
    super.dispose();
  }
}
