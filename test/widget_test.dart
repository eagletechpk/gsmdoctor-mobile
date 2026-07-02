// Phase 0 smoke test: app boots to the login screen when no token is stored.
//
// secureStorageProvider is overridden with an in-memory fake so the test
// never touches flutter_secure_storage's native platform channel (which
// isn't available under plain `flutter test`) — the standard Riverpod way
// to substitute a dependency in tests instead of mocking platform channels.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gsmnew_mobile/app.dart';
import 'package:gsmnew_mobile/core/storage/secure_storage.dart';
import 'package:gsmnew_mobile/features/auth/domain/auth_controller.dart';

class _FakeSecureStorage extends SecureStorage {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async => _token = token;

  @override
  Future<void> deleteToken() async => _token = null;
}

void main() {
  testWidgets('Unauthenticated app boots to the login screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [secureStorageProvider.overrideWithValue(_FakeSecureStorage())],
        child: const GsmDoctorApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
  });
}
