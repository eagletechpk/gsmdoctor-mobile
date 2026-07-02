import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Backend base URL. Build-time fallback, used only if the user has never
/// set a server URL from the login screen's settings icon (see
/// core/network/server_config.dart). Override per-build with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080
/// Default (10.0.2.2) is the Android Emulator's alias for the host
/// machine's localhost, matching this project's XAMPP install on :8080.
const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

Dio buildDioClient(
  SecureStorage storage, {
  required String serverUrl,
  required Future<void> Function() onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '$serverUrl/api/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(AuthInterceptor(storage, onUnauthorized: onUnauthorized));

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
}

/// Converts the backend's {success:false, message, errors} envelope (or any
/// other Dio failure) into a single typed [ApiException] that UI/provider
/// code can catch uniformly.
ApiException toApiException(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    return ApiException(
      data['message'] as String? ?? 'Something went wrong.',
      errors: (data['errors'] as Map?)?.cast<String, dynamic>(),
      statusCode: e.response?.statusCode,
    );
  }
  return ApiException(
    e.message ?? 'Network error. Please check your connection.',
    statusCode: e.response?.statusCode,
  );
}
