import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/server_config.dart';
import '../../../core/storage/secure_storage.dart';
import '../../push/domain/push_controller.dart';
import '../data/auth_repository.dart';
import 'app_user.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final serverUrl = ref.watch(serverUrlProvider);
  return buildDioClient(
    storage,
    serverUrl: serverUrl,
    // A 401 from any endpoint (token expired/revoked server-side) drops the
    // app back to a logged-out state, regardless of which screen triggered it.
    onUnauthorized: () => ref.read(authControllerProvider.notifier).handleUnauthorized(),
  );
});

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(dioProvider)));

class AuthState {
  const AuthState({this.isLoading = true, this.user, this.error});

  final bool isLoading;
  final AppUser? user;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({bool? isLoading, AppUser? user, String? error}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Single source of truth for "am I logged in, and as whom" — read by the
/// router's redirect logic and by any screen that needs the current user's
/// permissions (mirrors hasPermission() checks scattered through the web UI).
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Kick off the token-check as soon as the provider is first read; the
    // splash screen watches isLoading to know when this finishes.
    Future.microtask(bootstrap);
    return const AuthState(isLoading: true);
  }

  Future<void> bootstrap() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.readToken();
    if (token == null) {
      state = const AuthState(isLoading: false);
      return;
    }
    try {
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(isLoading: false, user: user);
    } catch (_) {
      await storage.deleteToken();
      state = const AuthState(isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final (token, user) =
          await ref.read(authRepositoryProvider).login(email: email, password: password);
      await ref.read(secureStorageProvider).writeToken(token);
      state = AuthState(isLoading: false, user: user);
    } catch (e) {
      state = AuthState(isLoading: false, user: null, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    // Unregister the push token while the Bearer token is still valid —
    // handleUnauthorized() below wipes it, after which this call would 401.
    try {
      await ref.read(pushControllerProvider).unregister();
    } catch (_) {
      // Best-effort cleanup — must never block logout itself.
    }
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // Already-invalid token, offline, etc. — local state is cleared below
      // regardless, since the user's intent ("log me out") should always succeed.
    }
    await handleUnauthorized();
  }

  Future<void> handleUnauthorized() async {
    await ref.read(secureStorageProvider).deleteToken();
    state = const AuthState(isLoading: false);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
