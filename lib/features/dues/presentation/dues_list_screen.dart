import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../domain/due.dart';
import '../domain/dues_controller.dart';

class DuesListScreen extends ConsumerStatefulWidget {
  const DuesListScreen({super.key});

  @override
  ConsumerState<DuesListScreen> createState() => _DuesListScreenState();
}

class _DuesListScreenState extends ConsumerState<DuesListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
        ref.read(duesListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(duesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.read(duesListProvider.notifier).load(),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(DuesListState state) {
    if (state.isLoading && state.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.customers.isEmpty) {
      return Center(child: Text('Failed to load: ${state.error}'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(duesListProvider.notifier).load(),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Outstanding', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatMoney(state.totalOutstanding), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ),
          if (state.overdue.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Overdue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...state.overdue.map((o) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    onTap: () => context.push('/dues/${o.id}'),
                    title: Text(o.name),
                    subtitle: Text('${o.phone} · Due since ${o.oldestDue}'),
                    trailing: Text(formatMoney(o.totalDues), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                )),
          ],
          const SizedBox(height: 20),
          const Text('All Customers With Dues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (state.customers.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('No outstanding dues.'))
          else
            ...[
              for (final c in state.customers) _CustomerTile(customer: c),
              if (state.hasMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final DueCustomerRow customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/dues/${customer.id}'),
        title: Text(customer.name),
        subtitle: Text('${customer.phone}${customer.nextDue != null ? ' · Next due: ${customer.nextDue}' : ''}'),
        trailing: Text(formatMoney(customer.totalDues), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
