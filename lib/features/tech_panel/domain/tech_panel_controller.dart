import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/tech_panel_repository.dart';

final techPanelRepositoryProvider =
    Provider<TechPanelRepository>((ref) => TechPanelRepository(ref.watch(dioProvider)));

final techPanelProvider = FutureProvider.autoDispose<TechPanelData>((ref) {
  return ref.watch(techPanelRepositoryProvider).index();
});
