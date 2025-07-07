import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'csv_service.dart';

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // INITIALIZE
  Future<void> initNotification() async {
    if (_isInitialized) return;

    const initSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await notificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  // NOTIFICATION DETAILS
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id', // Must match what you plan to use in show()
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    await notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails(), //
    );
  }

  Future<void> checkTomorrowEventsAndNotify() async {
    final events = await CSVService.loadEvents();
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    final matchingEvents = events.where((event) {
      try {
        final datePart = event.dateTime.split(' ').first;
        final eventDate = DateTime.parse(datePart);
        return eventDate.year == tomorrow.year &&
            eventDate.month == tomorrow.month &&
            eventDate.day == tomorrow.day;
      } catch (_) {
        return false;
      }
    }).toList();

    if (matchingEvents.isNotEmpty) {
      final noti = NotiService();
      await noti.initNotification();

      final count = matchingEvents.length;
      final title = "Tomorrow's Events";
      final body = count == 1
          ? "You have 1 event scheduled for tomorrow."
          : "You have $count events scheduled for tomorrow.";

      await noti.showNotification(title: title, body: body);
    }
  }
}
