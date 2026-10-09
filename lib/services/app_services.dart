// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/session_repository.dart';
import 'logging_controller.dart';
import 'notification_service.dart';

/// Port name the UI isolate listens on to hear about background changes.
const uiPortName = 'timelogbook.ui';

/// Everything the app and the notification handler need.
class AppServices {
  AppServices._(this.repo, this.notifications, this.logging);

  final SessionRepository repo;
  final NotificationService notifications;
  final LoggingController logging;

  static Future<AppServices> create({DidReceiveNotificationResponseCallback? onResponse}) async {
    final repo = await SessionRepository.open();
    final notifications = await NotificationService.init(
      onResponse: onResponse,
      onBackgroundResponse: notificationBackgroundHandler,
    );
    return AppServices._(repo, notifications, LoggingController(repo, notifications));
  }
}

/// Handles a notification response (button press or dismissal).
Future<void> handleNotificationResponse(LoggingController logging, NotificationResponse r) async {
  if (r.notificationResponseType == NotificationResponseType.notificationDismissed) {
    if (r.id == NotificationService.runningId) await logging.repostNotification();
    return;
  }
  switch (r.actionId) {
    case NotificationService.actionStart:
      await logging.start();
    case NotificationService.actionStop:
      await logging.stop();
  }
}

// The background isolate is kept alive between responses, so reuse its services.
Future<AppServices>? _backgroundServices;

/// Runs in a background isolate when a notification button is pressed,
/// whether or not the app is open.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await (_backgroundServices ??= AppServices.create());
  await handleNotificationResponse(services.logging, response);
  IsolateNameServer.lookupPortByName(uiPortName)?.send('changed');
}
