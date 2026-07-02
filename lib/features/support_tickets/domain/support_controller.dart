import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/support_repository.dart';
import 'support_ticket.dart';

final supportRepoProvider = Provider((ref) => SupportRepository(ref.watch(dioProvider)));

final supportListProvider = FutureProvider.autoDispose
    .family<({List<SupportTicket> tickets, int lastPage, int total}),
        ({int page, String status})>((ref, params) {
  return ref.watch(supportRepoProvider).list(page: params.page, status: params.status);
});

final ticketDetailProvider = FutureProvider.autoDispose.family<TicketDetail, int>((ref, id) {
  return ref.watch(supportRepoProvider).show(id);
});
