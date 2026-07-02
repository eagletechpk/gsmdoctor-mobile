import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

/// Attaches the Sanctum bearer token to every outgoing request, and notifies
/// [onUnauthorized] when the backend responds 401 (token missing/expired/
/// revoked) so the app-level auth provider can force a re-login from
/// anywhere, regardless of which screen triggered the failing call.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, {required this.onUnauthorized});

  final SecureStorage _storage;
  final Future<void> Function() onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await onUnauthorized();
    }
    handler.next(err);
  }
}
