import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/gsm_order_repository.dart';
import 'gsm_order.dart';

final gsmOrderRepositoryProvider = Provider<GsmOrderRepository>((ref) => GsmOrderRepository(ref.watch(dioProvider)));

class GsmOrdersListState {
  const GsmOrdersListState({
    this.orders = const [],
    this.status = '',
    this.search = '',
    this.page = 1,
    this.lastPage = 1,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  final List<GsmOrderSummary> orders;
  final String status;
  final String search;
  final int page;
  final int lastPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => page < lastPage;

  GsmOrdersListState copyWith({
    List<GsmOrderSummary>? orders,
    String? status,
    String? search,
    int? page,
    int? lastPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return GsmOrdersListState(
      orders: orders ?? this.orders,
      status: status ?? this.status,
      search: search ?? this.search,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class GsmOrdersListController extends Notifier<GsmOrdersListState> {
  @override
  GsmOrdersListState build() {
    Future.microtask(() => load());
    return const GsmOrdersListState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref.read(gsmOrderRepositoryProvider).list(status: state.status, search: state.search, page: 1);
      state = state.copyWith(orders: result.orders, page: result.page, lastPage: result.lastPage, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result =
          await ref.read(gsmOrderRepositoryProvider).list(status: state.status, search: state.search, page: state.page + 1);
      state = state.copyWith(
        orders: [...state.orders, ...result.orders],
        page: result.page,
        lastPage: result.lastPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void setStatusFilter(String status) {
    state = state.copyWith(status: status);
    load();
  }

  void setSearch(String search) {
    state = state.copyWith(search: search);
    load();
  }
}

final gsmOrdersListProvider = NotifierProvider<GsmOrdersListController, GsmOrdersListState>(GsmOrdersListController.new);

final gsmOrderDetailProvider = FutureProvider.family.autoDispose<GsmOrderDetail, int>((ref, id) {
  ref.watch(authControllerProvider);
  return ref.watch(gsmOrderRepositoryProvider).show(id);
});
