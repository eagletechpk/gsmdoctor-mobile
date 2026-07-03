import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _channelId = 'gsm_doctor_default';
const _channelName = 'GSM Doctor Notifications';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _plugin.initialize(
    settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

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

Future<void> showLocalNotification({required String title, required String body}) async {
  const androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    importance: Importance.high,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  await _plugin.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
  );
}
