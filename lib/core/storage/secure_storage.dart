import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keystore/Keychain-backed token storage. Never use shared_preferences for
/// the Sanctum bearer token.
class SecureStorage {
  SecureStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _baseUrlKey = 'api_base_url';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  /// User-configurable server URL override (set from the login screen when
  /// the backend is hosted somewhere other than the --dart-define default —
  /// e.g. after deploying the Laravel app to a new domain/IP). Persists
  /// across restarts so the app keeps pointing at the right server.
  Future<String?> readBaseUrl() => _storage.read(key: _baseUrlKey);

  Future<void> writeBaseUrl(String url) =>
      _storage.write(key: _baseUrlKey, value: url);

  Future<void> deleteBaseUrl() => _storage.delete(key: _baseUrlKey);
}
