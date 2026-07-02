import 'package:firebase_messaging/firebase_messaging.dart';

/// Must be a top-level (or static) function — FirebaseMessaging.
/// onBackgroundMessage spawns it in its own isolate when a push arrives
/// while the app is backgrounded/terminated. No-op for now: Phase 2 v1 only
/// sends notification-payload pushes, which the OS already surfaces via the
/// system tray without any app code running. Data-only messages (e.g. for
/// silent sync) would need real handling added here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
