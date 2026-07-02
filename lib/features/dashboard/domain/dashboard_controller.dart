import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/dashboard_repository.dart';
import 'dashboard_data.dart';

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((ref) => DashboardRepository(ref.watch(dioProvider)));

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetch();
});
