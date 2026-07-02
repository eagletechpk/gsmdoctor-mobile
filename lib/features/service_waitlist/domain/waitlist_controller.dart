import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/waitlist_repository.dart';
import 'waitlist_entry.dart';

final waitlistRepoProvider = Provider((ref) => WaitlistRepository(ref.watch(dioProvider)));

final waitlistProvider = FutureProvider.autoDispose
    .family<WaitlistPage, ({int page, String search, String status})>((ref, params) {
  return ref.watch(waitlistRepoProvider).list(
        page: params.page,
        search: params.search,
        status: params.status,
      );
});
