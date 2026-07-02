import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _channelId = 'gsm_doctor_default';
const _channelName = 'GSM Doctor Notifications';

final _plugin = FlutterLocalNotificationsPlugin();

/// Sets up the Android notification channel referenced by both this plugin
/// (foreground display) and AndroidManifest.xml's
/// `default_notification_channel_id` meta-data (background/terminated
/// display, handled natively by the FCM SDK).
Future<void> initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _plugin.initialize(settings: const InitializationSettings(android: androidSettings));

  const channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: 'Technician job alerts and chat messages.',
    importance: Importance.high,
  );
  await _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

/// FCM only auto-displays a system notification when the app is
/// backgrounded/terminated; in the foreground it hands the message to
/// onMessage instead, so we display it ourselves to match that behavior.
Future<void> showLocalNotification({required String title, required String body}) async {
  const androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    importance: Importance.high,
    priority: Priority.high,
  );
  await _plugin.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: androidDetails),
  );
}
