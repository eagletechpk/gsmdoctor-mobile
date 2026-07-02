import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_controller.dart';
import '../data/settings_repository.dart';
import 'settings_data.dart';

final settingsRepoProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(dioProvider));
});

final settingsProvider = FutureProvider<SettingsData>((ref) async {
  return ref.watch(settingsRepoProvider).getSettings();
});
