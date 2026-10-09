// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/day_summary.dart';
import '../util/format.dart';

/// Shows the "logging" (persistent) and "stopped" (dismissible) notifications.
///
/// On Android the logging notification belongs to a foreground service, so it
/// stays until logging is stopped. On iOS it is a plain notification for now.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const runningId = 1;
  static const stoppedId = 2;
  static const actionStart = 'start';
  static const actionStop = 'stop';

  static const _icon = 'ic_stat_logbook';
  static const _runningCategory = 'running';
  static const _stoppedCategory = 'stopped';

  static Future<NotificationService> init({
    DidReceiveNotificationResponseCallback? onResponse,
    required DidReceiveBackgroundNotificationResponseCallback onBackgroundResponse,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings(_icon),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              _runningCategory,
              actions: [DarwinNotificationAction.plain(actionStop, 'Stop logging')],
            ),
            DarwinNotificationCategory(
              _stoppedCategory,
              actions: [DarwinNotificationAction.plain(actionStart, 'Start logging')],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: onResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
    );
    return NotificationService(plugin);
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true) ??
        false;
  }

  /// Shows the persistent notification. Its chronometer counts the day total.
  ///
  /// With [startService] false the notification is only re-posted, for when
  /// the foreground service is already running.
  Future<void> showRunning({
    required DateTime since,
    required DaySummary today,
    required DateTime now,
    bool startService = true,
  }) async {
    await _plugin.cancel(id: stoppedId);
    const title = 'Logging time';
    final body = 'Running since ${formatTime(since)}';
    final base = now.subtract(today.total);
    final android = AndroidNotificationDetails(
      'running',
      'Logging',
      channelDescription: 'Shown while time is being logged',
      // Default importance keeps the notification expanded, so its button is
      // visible right away; sound and vibration are off.
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      showWhen: true,
      usesChronometer: true,
      when: base.millisecondsSinceEpoch,
      category: AndroidNotificationCategory.stopwatch,
      visibility: NotificationVisibility.public,
      // Android 14+ lets users swipe even foreground service notifications away;
      // the dismissal is reported so the notification can be shown again.
      dismissIsolate: NotificationDismissedIsolate.background,
      actions: const [
        AndroidNotificationAction(actionStop, 'Stop logging', cancelNotification: false),
      ],
    );
    final androidPlugin = _android;
    if (androidPlugin != null && startService) {
      await androidPlugin.startForegroundService(
        id: runningId,
        title: title,
        body: body,
        notificationDetails: android,
        startType: AndroidServiceStartType.startRedeliverIntent,
        foregroundServiceTypes: {AndroidServiceForegroundType.foregroundServiceTypeSpecialUse},
      );
    } else {
      await _plugin.show(
        id: runningId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: android,
          iOS: const DarwinNotificationDetails(categoryIdentifier: _runningCategory),
        ),
      );
    }
  }

  /// Removes the persistent notification and shows a dismissible summary.
  Future<void> showStopped(DaySummary today) async {
    await clearRunning();
    final correctedEnd = today.correctedEnd;
    final body =
        'Time total ${formatDuration(today.total)}'
        '${correctedEnd == null ? '' : ' · Corrected end ${formatTime(correctedEnd)}'}';
    await _plugin.show(
      id: stoppedId,
      title: 'Logging stopped',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'stopped',
          'Stopped',
          channelDescription: 'Shown after logging was stopped',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: false,
          visibility: NotificationVisibility.public,
          actions: [AndroidNotificationAction(actionStart, 'Start logging')],
        ),
        iOS: DarwinNotificationDetails(categoryIdentifier: _stoppedCategory),
      ),
    );
  }

  /// Removes the persistent notification without showing a summary.
  Future<void> clearRunning() async {
    await _android?.stopForegroundService();
    await _plugin.cancel(id: runningId);
  }

  Future<bool> isRunningNotificationShown() async {
    final android = _android;
    if (android == null) return true;
    final active = await android.getActiveNotifications();
    return active.any((n) => n.id == runningId);
  }
}
