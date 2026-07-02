import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/purchase_repository.dart';
import 'purchase.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) => PurchaseRepository(ref.watch(dioProvider)));

final purchaseFormDataProvider = FutureProvider.autoDispose<PurchaseFormData>((ref) {
  return ref.watch(purchaseRepositoryProvider).formData();
});

class PurchasesListState {
  const PurchasesListState({
    this.purchaseOrders = const [],
    this.search = '',
    this.status = '',
    this.page = 1,
    this.lastPage = 1,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  final List<PurchaseOrderSummary> purchaseOrders;
  final String search;
  final String status;
  final int page;
  final int lastPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => page < lastPage;

  PurchasesListState copyWith({
    List<PurchaseOrderSummary>? purchaseOrders,
    String? search,
    String? status,
    int? page,
    int? lastPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return PurchasesListState(
      purchaseOrders: purchaseOrders ?? this.purchaseOrders,
      search: search ?? this.search,
      status: status ?? this.status,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class PurchasesListController extends Notifier<PurchasesListState> {
  @override
  PurchasesListState build() {
    Future.microtask(() => load());
    return const PurchasesListState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref.read(purchaseRepositoryProvider).list(search: state.search, status: state.status, page: 1);
      state = state.copyWith(purchaseOrders: result.purchaseOrders, page: result.page, lastPage: result.lastPage, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result =
          await ref.read(purchaseRepositoryProvider).list(search: state.search, status: state.status, page: state.page + 1);
      state = state.copyWith(
        purchaseOrders: [...state.purchaseOrders, ...result.purchaseOrders],
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

  void setStatusFilter(String status) {
    state = state.copyWith(status: status);
    load();
  }
}

final purchasesListProvider = NotifierProvider<PurchasesListController, PurchasesListState>(PurchasesListController.new);

final purchaseDetailProvider = FutureProvider.family.autoDispose<PurchaseOrderDetail, int>((ref, id) {
  ref.watch(authControllerProvider);
  return ref.watch(purchaseRepositoryProvider).show(id);
});

class NewPurchaseState {
  const NewPurchaseState({
    this.items = const [],
    this.supplierId,
    this.accountId,
    this.status = 'received',
    this.paidAmount = 0,
    this.cargoCharges = 0,
    this.notes = '',
    this.isSubmitting = false,
  });

  final List<NewPurchaseItem> items;
  final int? supplierId;
  final int? accountId;
  final String status;
  final num paidAmount;
  final num cargoCharges;
  final String notes;
  final bool isSubmitting;

  num get itemsTotal => items.fold<num>(0, (sum, i) => sum + i.total);

  num get grandTotal => itemsTotal + cargoCharges;

  NewPurchaseState copyWith({
    List<NewPurchaseItem>? items,
    int? supplierId,
    int? accountId,
    String? status,
    num? paidAmount,
    num? cargoCharges,
    String? notes,
    bool? isSubmitting,
  }) {
    return NewPurchaseState(
      items: items ?? this.items,
      supplierId: supplierId ?? this.supplierId,
      accountId: accountId ?? this.accountId,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      cargoCharges: cargoCharges ?? this.cargoCharges,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Local builder state for the "New Purchase Order" screen — items live only
/// in memory until submit, mirroring PosCartController's pattern.
class NewPurchaseController extends Notifier<NewPurchaseState> {
  @override
  NewPurchaseState build() => const NewPurchaseState();

  void addProduct(PurchaseProductOption product) {
    final items = [...state.items];
    final idx = items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      items[idx].qty += 1;
    } else {
      items.add(NewPurchaseItem(product: product));
    }
    state = state.copyWith(items: items);
  }

  void updateQty(int index, int qty) {
    if (qty < 1) {
      removeAt(index);
      return;
    }
    final items = [...state.items];
    items[index].qty = qty;
    state = state.copyWith(items: items);
  }

  void updateCost(int index, num cost) {
    final items = [...state.items];
    items[index].costPrice = cost;
    state = state.copyWith(items: items);
  }

  void removeAt(int index) {
    final items = [...state.items]..removeAt(index);
    state = state.copyWith(items: items);
  }

  void setSupplier(int? id) => state = state.copyWith(supplierId: id);
  void setAccount(int? id) => state = state.copyWith(accountId: id);
  void setStatus(String status) => state = state.copyWith(status: status);
  void setPaidAmount(num amount) => state = state.copyWith(paidAmount: amount);
  void setCargoCharges(num amount) => state = state.copyWith(cargoCharges: amount);
  void setNotes(String notes) => state = state.copyWith(notes: notes);

  void clear() => state = const NewPurchaseState();

  Future<PurchaseOrderDetail> submit() async {
    if (state.supplierId == null || state.items.isEmpty) {
      throw Exception('Select a supplier and add at least one item.');
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final result = await ref.read(purchaseRepositoryProvider).create(
            supplierId: state.supplierId!,
            status: state.status,
            items: state.items,
            paidAmount: state.paidAmount,
            accountId: state.accountId,
            cargoCharges: state.cargoCharges,
            notes: state.notes,
          );
      clear();
      ref.invalidate(purchasesListProvider);
      return result;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}

final newPurchaseProvider = NotifierProvider<NewPurchaseController, NewPurchaseState>(NewPurchaseController.new);
