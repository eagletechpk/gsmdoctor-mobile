import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/auth_controller.dart';
import 'features/push/domain/push_controller.dart';

class GsmDoctorApp extends ConsumerWidget {
  const GsmDoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Push registration only makes sense once we have a Bearer token to call
    // the API with, so it's driven off auth transitions rather than its own
    // lifecycle. Unregistering happens inside AuthController.logout() itself
    // instead (it needs to fire before the token is wiped, not after).
    ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && previous?.user?.id != next.user?.id) {
        ref.read(pushControllerProvider).registerForCurrentUser();
      }
    });

    return MaterialApp.router(
      title: 'GSM Doctor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
