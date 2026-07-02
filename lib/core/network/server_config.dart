import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_client.dart';

/// Overridden in main.dart with the value read from secure storage (if any)
/// before runApp(), so ServerUrlController.build() can seed its initial
/// state synchronously without itself needing to be async.
final initialServerUrlOverrideProvider = Provider<String?>((ref) => null);

class ServerUrlController extends Notifier<String> {
  @override
  String build() => ref.watch(initialServerUrlOverrideProvider) ?? defaultApiBaseUrl;

  void set(String url) => state = url;
}

/// Current effective backend URL (scheme + host + port, no trailing slash,
/// no /api/v1 suffix). Seeded from secure storage at app startup (see
/// main.dart) if the user previously set a custom server via the login
/// screen's settings icon; otherwise falls back to [defaultApiBaseUrl].
///
/// Lets one APK be pointed at any Laravel install (e.g. after the project is
/// uploaded to a different host/IP) without a rebuild — just edit the URL
/// from the login screen.
final serverUrlProvider = NotifierProvider<ServerUrlController, String>(ServerUrlController.new);

/// Strips a trailing slash and obviously-wrong whitespace from user input
/// before it's stored/used as a Dio base URL.
String normalizeServerUrl(String input) {
  var url = input.trim();
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}
