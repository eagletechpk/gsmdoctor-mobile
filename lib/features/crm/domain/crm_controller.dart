import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/crm_repository.dart';
import 'crm_customer.dart';

final crmRepositoryProvider = Provider<CrmRepository>((ref) => CrmRepository(ref.watch(dioProvider)));

class CrmListState {
  const CrmListState({
    this.customers = const [],
    this.search = '',
    this.page = 1,
    this.lastPage = 1,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  final List<CrmCustomerSummary> customers;
  final String search;
  final int page;
  final int lastPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => page < lastPage;

  CrmListState copyWith({
    List<CrmCustomerSummary>? customers,
    String? search,
    int? page,
    int? lastPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return CrmListState(
      customers: customers ?? this.customers,
      search: search ?? this.search,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

/// Backs the CRM list screen: search + paginated fetch, mirrors
/// CRMController::index()'s search query param.
class CrmListController extends Notifier<CrmListState> {
  @override
  CrmListState build() {
    Future.microtask(() => load());
    return const CrmListState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref.read(crmRepositoryProvider).list(search: state.search, page: 1);
      state = state.copyWith(
        customers: result.customers,
        page: result.page,
        lastPage: result.lastPage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await ref.read(crmRepositoryProvider).list(search: state.search, page: state.page + 1);
      state = state.copyWith(
        customers: [...state.customers, ...result.customers],
        page: result.page,
        lastPage: result.lastPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void setSearch(String search) {
    state = state.copyWith(search: search);
    load();
  }

  Future<CrmCustomerSummary> quickAdd({required String name, required String phone, String? city}) async {
    final customer = await ref.read(crmRepositoryProvider).quickAdd(name: name, phone: phone, city: city);
    await load();
    return customer;
  }
}

final crmListProvider = NotifierProvider<CrmListController, CrmListState>(CrmListController.new);

final crmDetailProvider = FutureProvider.family.autoDispose<CrmCustomerDetail, int>((ref, id) {
  ref.watch(authControllerProvider);
  return ref.watch(crmRepositoryProvider).show(id);
});
