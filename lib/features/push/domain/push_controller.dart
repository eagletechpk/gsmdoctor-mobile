import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/push/local_notifications.dart';
import '../../../core/router/app_router.dart';
import '../../auth/domain/auth_controller.dart';
import '../data/device_token_repository.dart';

final deviceTokenRepositoryProvider =
    Provider<DeviceTokenRepository>((ref) => DeviceTokenRepository(ref.watch(dioProvider)));

/// Registers/unregisters this device's FCM token against
/// Api\V1\DeviceTokenController and wires foreground/background/terminated
/// message handling. Driven by auth state changes (see app.dart) rather
/// than the auth domain depending on Firebase directly — registering a
/// token only makes sense once we have a Bearer token to call the API with.
class PushController {
  PushController(this._ref);

  final Ref _ref;
  bool _listening = false;

  Future<void> registerForCurrentUser() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) {
      await _safeRegister(token);
    }

    if (_listening) return;
    _listening = true;

    messaging.onTokenRefresh.listen(_safeRegister);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _onNotificationTap(initialMessage);
    }
  }

  Future<void> unregister() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await _ref.read(deviceTokenRepositoryProvider).unregister(token);
    } catch (_) {
      // Logout must always succeed locally even if this best-effort
      // cleanup call fails (offline, token already pruned server-side, etc).
    }
  }

  Future<void> _safeRegister(String token) async {
    try {
      await _ref.read(deviceTokenRepositoryProvider).register(token, deviceName: 'flutter-android');
    } catch (_) {
      // Best-effort — a failed registration must not block app usage.
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    showLocalNotification(title: notification.title ?? 'GSM Doctor', body: notification.body ?? '');
  }

  void _onNotificationTap(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final jobId = message.data['job_id'];
    if (jobId != null && jobId.toString().isNotEmpty) {
      GoRouter.of(context).push('/repair-jobs/$jobId');
    } else {
      GoRouter.of(context).go('/tech-panel');
    }
  }
}

final pushControllerProvider = Provider<PushController>((ref) => PushController(ref));
