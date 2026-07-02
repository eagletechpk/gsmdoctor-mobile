import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../domain/product.dart';
import '../domain/product_controller.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
        ref.read(productsListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsListProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.read(productsListProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search name, SKU, barcode...',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => ref.read(productsListProvider.notifier).setSearch(v.trim()),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip(null, 'All', state.categoryId == null && !state.lowStockOnly,
                    () => ref.read(productsListProvider.notifier).setCategory(null)),
                _filterChip(-1, 'Low Stock', state.lowStockOnly,
                    () => ref.read(productsListProvider.notifier).toggleLowStock(!state.lowStockOnly)),
                ...categoriesAsync.maybeWhen(
                  data: (cats) => cats.map((c) => _filterChip(
                        c.id,
                        c.name,
                        state.categoryId == c.id,
                        () => ref.read(productsListProvider.notifier).setCategory(c.id),
                      )),
                  orElse: () => const <Widget>[],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _filterChip(int? id, String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }

  Widget _buildBody(ProductsListState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.products.isEmpty) {
      return Center(child: Text('Failed to load: ${state.error}'));
    }
    if (state.products.isEmpty) {
      return const Center(child: Text('No products found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productsListProvider.notifier).load(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: state.products.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.products.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _ProductCard(product: state.products[index]);
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductSummary product;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/products/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(
                      [product.sku, product.categoryName].where((s) => s != null && s.isNotEmpty).join(' · '),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatMoney(product.sellPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${product.stockQty}',
                    style: TextStyle(fontSize: 12, color: product.isLowStock ? Colors.red : Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
