import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/product_repository.dart';
import 'product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) => ProductRepository(ref.watch(dioProvider)));

final productCategoriesProvider = FutureProvider.autoDispose<List<ProductCategoryOption>>((ref) {
  return ref.watch(productRepositoryProvider).categories();
});

class ProductsListState {
  const ProductsListState({
    this.products = const [],
    this.search = '',
    this.categoryId,
    this.lowStockOnly = false,
    this.page = 1,
    this.lastPage = 1,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  final List<ProductSummary> products;
  final String search;
  final int? categoryId;
  final bool lowStockOnly;
  final int page;
  final int lastPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => page < lastPage;

  ProductsListState copyWith({
    List<ProductSummary>? products,
    String? search,
    int? categoryId,
    bool clearCategory = false,
    bool? lowStockOnly,
    int? page,
    int? lastPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return ProductsListState(
      products: products ?? this.products,
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class ProductsListController extends Notifier<ProductsListState> {
  @override
  ProductsListState build() {
    Future.microtask(() => load());
    return const ProductsListState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref.read(productRepositoryProvider).list(
            search: state.search,
            categoryId: state.categoryId,
            lowStockOnly: state.lowStockOnly,
            page: 1,
          );
      state = state.copyWith(products: result.products, page: result.page, lastPage: result.lastPage, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await ref.read(productRepositoryProvider).list(
            search: state.search,
            categoryId: state.categoryId,
            lowStockOnly: state.lowStockOnly,
            page: state.page + 1,
          );
      state = state.copyWith(
        products: [...state.products, ...result.products],
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

  void setCategory(int? categoryId) {
    state = state.copyWith(categoryId: categoryId, clearCategory: categoryId == null);
    load();
  }

  void toggleLowStock(bool value) {
    state = state.copyWith(lowStockOnly: value);
    load();
  }
}

final productsListProvider = NotifierProvider<ProductsListController, ProductsListState>(ProductsListController.new);

final productDetailProvider = FutureProvider.family.autoDispose<ProductDetail, int>((ref, id) {
  ref.watch(authControllerProvider);
  return ref.watch(productRepositoryProvider).show(id);
});
