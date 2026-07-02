import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../domain/crm_controller.dart';
import '../domain/crm_customer.dart';

class CrmListScreen extends ConsumerStatefulWidget {
  const CrmListScreen({super.key});

  @override
  ConsumerState<CrmListScreen> createState() => _CrmListScreenState();
}

class _CrmListScreenState extends ConsumerState<CrmListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
        ref.read(crmListProvider.notifier).loadMore();
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
    final state = ref.watch(crmListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.read(crmListProvider.notifier).load(),
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
                hintText: 'Search name, phone, email...',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => ref.read(crmListProvider.notifier).setSearch(v.trim()),
            ),
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddSheet(context),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBody(CrmListState state) {
    if (state.isLoading && state.customers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.customers.isEmpty) {
      return Center(child: Text('Failed to load: ${state.error}'));
    }
    if (state.customers.isEmpty) {
      return const Center(child: Text('No customers found.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(crmListProvider.notifier).load(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: state.customers.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.customers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final customer = state.customers[index];
          return _CustomerCard(customer: customer);
        },
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final cityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City (optional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    if (name.isEmpty || phone.isEmpty) return;
                    Navigator.of(sheetContext).pop();
                    try {
                      await ref.read(crmListProvider.notifier).quickAdd(
                            name: name,
                            phone: phone,
                            city: cityController.text.trim(),
                          );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final CrmCustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    final hasDues = customer.totalDues > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/crm/${customer.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      [customer.phone, customer.city].where((s) => s != null && s.isNotEmpty).join(' · '),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(customer.totalDues),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasDues ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Text('Dues', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
