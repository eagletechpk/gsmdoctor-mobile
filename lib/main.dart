import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/server_config.dart';
import 'core/push/firebase_background_handler.dart';
import 'core/push/local_notifications.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initLocalNotifications();

  // Read any previously-saved custom server URL before the provider graph
  // builds, so dioProvider is created with the right baseUrl from the very
  // first frame (see core/network/server_config.dart).
  final savedServerUrl = await SecureStorage().readBaseUrl();

  runApp(ProviderScope(
    overrides: [
      if (savedServerUrl != null && savedServerUrl.isNotEmpty)
        initialServerUrlOverrideProvider.overrideWithValue(savedServerUrl),
    ],
    child: const GsmDoctorApp(),
  ));
}
