import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_colors.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/gsm_order.dart';
import '../domain/gsm_order_controller.dart';

class GsmOrdersListScreen extends ConsumerStatefulWidget {
  const GsmOrdersListScreen({super.key});

  @override
  ConsumerState<GsmOrdersListScreen> createState() => _GsmOrdersListScreenState();
}

class _GsmOrdersListScreenState extends ConsumerState<GsmOrdersListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
        ref.read(gsmOrdersListProvider.notifier).loadMore();
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
    final state = ref.watch(gsmOrdersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GSM Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.read(gsmOrdersListProvider.notifier).load(),
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
                hintText: 'Search order #, IMEI, service...',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => ref.read(gsmOrdersListProvider.notifier).setSearch(v.trim()),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip('', 'All'),
                for (final s in gsmOrderStatusOptions) _filterChip(s, statusLabel(s)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final state = ref.watch(gsmOrdersListProvider);
    final selected = state.status == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => ref.read(gsmOrdersListProvider.notifier).setStatusFilter(value),
      ),
    );
  }

  Widget _buildBody(GsmOrdersListState state) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.orders.isEmpty) {
      return Center(child: Text('Failed to load: ${state.error}'));
    }
    if (state.orders.isEmpty) {
      return const Center(child: Text('No orders found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(gsmOrdersListProvider.notifier).load(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: state.orders.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _OrderCard(order: state.orders[index]);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final GsmOrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  StatusChip.status(order.status, orderStatusColor(order.status)),
                ],
              ),
              const SizedBox(height: 6),
              Text(order.serviceName ?? '-', style: const TextStyle(fontSize: 14)),
              if (order.imei != null && order.imei!.isNotEmpty) Text('IMEI: ${order.imei}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(formatMoney(order.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  if (order.customerName != null)
                    Text(order.customerName!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
