// SPDX-License-Identifier: AGPL-3.0-or-later

import '../data/session_repository.dart';
import '../domain/day_summary.dart';
import '../models/session.dart';
import 'notification_service.dart';

/// Start/stop logic shared by the app UI and the notification buttons.
class LoggingController {
  LoggingController(this.repo, this.notifications, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SessionRepository repo;
  final NotificationService notifications;
  final DateTime Function() _clock;

  Future<void> start() async {
    final now = _clock();
    final session = await repo.start(now);
    await _showRunning(session, now);
  }

  Future<void> stop() async {
    final now = _clock();
    final stopped = await repo.stop(now);
    if (stopped == null) return;
    await notifications.showStopped(DaySummary.of(await repo.forDay(stopped.day), now));
  }

  Future<void> toggle() async {
    if (await repo.running() == null) {
      await start();
    } else {
      await stop();
    }
  }

  /// Makes sure the persistent notification is shown while a session runs,
  /// e.g. after a reboot. Call while the app is in the foreground.
  Future<void> restoreNotification() async {
    final running = await repo.running();
    if (running == null || await notifications.isRunningNotificationShown()) return;
    await _showRunning(running, _clock());
  }

  /// Updates the notifications after entries were edited or deleted.
  Future<void> syncAfterEdit({required bool wasRunning}) async {
    final running = await repo.running();
    if (running != null) {
      await _showRunning(running, _clock(), startService: !wasRunning);
    } else if (wasRunning) {
      await notifications.clearRunning();
    }
  }

  /// Shows the persistent notification again after the user swiped it away.
  Future<void> repostNotification() async {
    final running = await repo.running();
    if (running == null) return;
    await _showRunning(running, _clock(), startService: false);
  }

  Future<void> _showRunning(Session session, DateTime now, {bool startService = true}) async {
    final today = DaySummary.of(await repo.forDay(session.day), now);
    await notifications.showRunning(
      since: session.start,
      today: today,
      now: now,
      startService: startService,
    );
  }
}
