import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_controller.dart';
import '../data/online_orders_repository.dart';
import '../domain/online_order.dart';

final onlineOrdersRepoProvider = Provider<OnlineOrdersRepository>((ref) {
  return OnlineOrdersRepository(ref.watch(dioProvider));
});

final onlineOrdersProvider =
    FutureProvider.family<OnlineOrderPage, ({int page, String? search, String? paymentStatus, String? fulfillmentStatus})>(
        (ref, args) async {
  return ref.watch(onlineOrdersRepoProvider).list(
        page: args.page,
        search: args.search,
        paymentStatus: args.paymentStatus,
        fulfillmentStatus: args.fulfillmentStatus,
      );
});

final onlineOrderDetailProvider =
    FutureProvider.family<OnlineOrderDetail, int>((ref, id) async {
  return ref.watch(onlineOrdersRepoProvider).getOne(id);
});
