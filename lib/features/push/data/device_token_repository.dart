import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';

/// Thin wrapper over Api\V1\DeviceTokenController (POST/DELETE
/// /device-tokens). Deliberately has zero dependency on firebase_messaging —
/// it just persists whatever FCM token string it's given. The actual
/// FirebaseMessaging.instance.getToken() call (and the native Gradle/
/// google-services.json wiring it needs) lands once that file is available;
/// this repository is the part of Phase 2 that doesn't have to wait for it.
class DeviceTokenRepository {
  DeviceTokenRepository(this._dio);

  final Dio _dio;

  Future<void> register(String fcmToken, {String platform = 'android', String? deviceName}) async {
    try {
      await _dio.post('/device-tokens', data: {
        'fcm_token': fcmToken,
        'platform': platform,
        'device_name': ?deviceName,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> unregister(String fcmToken) async {
    try {
      await _dio.delete('/device-tokens', data: {'fcm_token': fcmToken});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
