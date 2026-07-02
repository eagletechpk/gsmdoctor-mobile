import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/app_user.dart';

/// Thin wrapper over the three Api\V1\AuthController endpoints. Returns
/// plain (token, AppUser) data — session/token persistence and app-wide
/// auth state live in AuthController (the Riverpod notifier), not here.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<(String token, AppUser user)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'device_name': 'flutter-android',
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return (
        data['token'] as String,
        AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<AppUser> me() async {
    try {
      final response = await _dio.get('/auth/me');
      final data = response.data['data'] as Map<String, dynamic>;
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
