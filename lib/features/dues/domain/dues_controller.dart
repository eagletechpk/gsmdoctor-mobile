import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/dues_repository.dart';
import 'due.dart';

final duesRepositoryProvider = Provider<DuesRepository>((ref) => DuesRepository(ref.watch(dioProvider)));

class DuesListState {
  const DuesListState({
    this.customers = const [],
    this.overdue = const [],
    this.totalOutstanding = 0,
    this.page = 1,
    this.lastPage = 1,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  final List<DueCustomerRow> customers;
  final List<OverdueRow> overdue;
  final num totalOutstanding;
  final int page;
  final int lastPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => page < lastPage;

  DuesListState copyWith({
    List<DueCustomerRow>? customers,
    List<OverdueRow>? overdue,
    num? totalOutstanding,
    int? page,
    int? lastPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return DuesListState(
      customers: customers ?? this.customers,
      overdue: overdue ?? this.overdue,
      totalOutstanding: totalOutstanding ?? this.totalOutstanding,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class DuesListController extends Notifier<DuesListState> {
  @override
  DuesListState build() {
    Future.microtask(() => load());
    return const DuesListState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref.read(duesRepositoryProvider).list(page: 1);
      state = state.copyWith(
        customers: result.customers,
        overdue: result.overdue,
        totalOutstanding: result.totalOutstanding,
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
      final result = await ref.read(duesRepositoryProvider).list(page: state.page + 1);
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
}

final duesListProvider = NotifierProvider<DuesListController, DuesListState>(DuesListController.new);

final dueDetailProvider = FutureProvider.family.autoDispose<DueCustomerDetail, int>((ref, id) {
  ref.watch(authControllerProvider);
  return ref.watch(duesRepositoryProvider).show(id);
});
