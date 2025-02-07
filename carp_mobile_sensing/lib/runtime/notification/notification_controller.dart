/*
 * Copyright 2022 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of runtime;

/// A controller of user notifications based on [UserTask]s.
/// Works closely with the [AppTaskController].
abstract class NotificationController {
  /// The upper limit of scheduled notification on iOS.
  static const PENDING_NOTIFICATION_LIMIT = 64;

  /// The id of the notification channel.
  static const CHANNEL_ID = 'carp_mobile_sensing_notification_user_tasks';

  /// The name of the notification channel as shown in the Settings
  /// on Android phones.
  static const CHANNEL_NAME = 'User Tasks';

  /// The description of the notification channel as shown in the Settings
  /// on Android phones.
  static const CHANNEL_DESCRIPTION =
      'Notifications about tasks that the user has to do.';

  /// Initialize and set up the notification controller.
  /// Also tries to get permissions to send notifications.
  Future<void> initialize();

  /// Send an immediate notification for a [task].
  Future<void> sendNotification(UserTask task);

  /// Schedule a notification for a [task] at the [task.triggerTime].
  Future<void> scheduleNotification(UserTask task);

  /// The number of pending notifications.
  Future<int> get pendingNotificationRequestsCount;

  /// Cancel (i.e., remove) the notification for the [task].
  Future<void> cancelNotification(UserTask task);
}
