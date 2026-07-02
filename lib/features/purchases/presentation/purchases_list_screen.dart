import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_colors.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/purchase.dart';
import '../domain/purchase_controller.dart';

class PurchasesListScreen extends ConsumerStatefulWidget {
  const PurchasesListScreen({super.key});

  @override
  ConsumerState<PurchasesListScreen> createState() => _PurchasesListScreenState();
}

class _PurchasesListScreenState extends ConsumerState<PurchasesListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
        ref.read(purchasesListProvider.notifier).loadMore();
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
    final state = ref.watch(purchasesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.read(purchasesListProvider.notifier).load(),
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
                hintText: 'Search PO #, supplier...',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => ref.read(purchasesListProvider.notifier).setSearch(v.trim()),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip('', 'All'),
                for (final s in purchaseOrderStatusOptions) _filterChip(s, statusLabel(s)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(state)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/purchases/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final state = ref.watch(purchasesListProvider);
    final selected = state.status == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => ref.read(purchasesListProvider.notifier).setStatusFilter(value),
      ),
    );
  }

  Widget _buildBody(PurchasesListState state) {
    if (state.isLoading && state.purchaseOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.purchaseOrders.isEmpty) {
      return Center(child: Text('Failed to load: ${state.error}'));
    }
    if (state.purchaseOrders.isEmpty) {
      return const Center(child: Text('No purchase orders found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(purchasesListProvider.notifier).load(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: state.purchaseOrders.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.purchaseOrders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _PoCard(po: state.purchaseOrders[index]);
        },
      ),
    );
  }
}

class _PoCard extends StatelessWidget {
  const _PoCard({required this.po});

  final PurchaseOrderSummary po;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/purchases/${po.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  StatusChip.status(po.status, poStatusColor(po.status)),
                ],
              ),
              const SizedBox(height: 6),
              Text(po.supplierName ?? '-', style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(formatMoney(po.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (po.dueAmount > 0)
                    Text('Due: ${formatMoney(po.dueAmount)}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
