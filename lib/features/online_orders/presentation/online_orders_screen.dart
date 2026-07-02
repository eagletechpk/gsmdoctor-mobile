import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/formatters.dart';
import '../domain/online_orders_controller.dart';

class OnlineOrdersScreen extends ConsumerStatefulWidget {
  const OnlineOrdersScreen({super.key});

  @override
  ConsumerState<OnlineOrdersScreen> createState() => _OnlineOrdersScreenState();
}

class _OnlineOrdersScreenState extends ConsumerState<OnlineOrdersScreen> {
  final _searchCtrl = TextEditingController();
  String? _paymentFilter;
  String? _fulfillFilter;
  int _page = 1;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ({int page, String? search, String? paymentStatus, String? fulfillmentStatus})
      get _args => (
            page: _page,
            search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
            paymentStatus: _paymentFilter,
            fulfillmentStatus: _fulfillFilter,
          );

  void _refresh() {
    ref.invalidate(onlineOrdersProvider(_args));
  }

  Color _payColor(String s) => switch (s) {
        'paid' => Colors.green,
        'refunded' => Colors.blue,
        'failed' => Colors.red,
        _ => Colors.orange,
      };

  Color _fulfillColor(String s) => switch (s) {
        'completed' => Colors.green,
        'shipped' => Colors.teal,
        'processing' => Colors.blue,
        'cancelled' => Colors.red,
        _ => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(onlineOrdersProvider(_args));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchCtrl.clear();
                            _page = 1;
                          });
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (_) => setState(() => _page = 1),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Payment',
                  value: _paymentFilter,
                  options: const ['pending', 'paid', 'refunded', 'failed'],
                  onChanged: (v) => setState(() {
                    _paymentFilter = v;
                    _page = 1;
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Fulfillment',
                  value: _fulfillFilter,
                  options: const [
                    'unfulfilled',
                    'processing',
                    'shipped',
                    'completed',
                    'cancelled'
                  ],
                  onChanged: (v) => setState(() {
                    _fulfillFilter = v;
                    _page = 1;
                  }),
                ),
              ],
            ),
          ),
          async.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              if (data.counts.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  children: [
                    _CountBadge('Pending Pay', data.counts['pending'] ?? 0, Colors.orange),
                    const SizedBox(width: 8),
                    _CountBadge('Paid', data.counts['paid'] ?? 0, Colors.green),
                    const SizedBox(width: 8),
                    _CountBadge('Unfulfilled', data.counts['unfulfilled'] ?? 0, Colors.red),
                    const SizedBox(width: 8),
                    _CountBadge('Processing', data.counts['processing'] ?? 0, Colors.blue),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) {
                if (data.orders.isEmpty) {
                  return const Center(child: Text('No orders found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: data.orders.length,
                  itemBuilder: (ctx, i) {
                    final o = data.orders[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => context.push('/online-orders/${o.id}'),
                        title: Text(o.orderNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.customerName),
                            if (o.customerPhone != null) Text(o.customerPhone!),
                            Text(formatMoney(o.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _StatusBadge(o.paymentStatus, _payColor(o.paymentStatus)),
                            const SizedBox(height: 4),
                            _StatusBadge(
                                o.fulfillmentStatus, _fulfillColor(o.fulfillmentStatus)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label,
      required this.value,
      required this.options,
      required this.onChanged});
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String?>(
      hint: Text(label, style: const TextStyle(fontSize: 13)),
      value: value,
      isDense: true,
      underline: const SizedBox(),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text('All $label')),
        ...options.map((o) => DropdownMenuItem<String?>(
              value: o,
              child: Text(o[0].toUpperCase() + o.substring(1)),
            )),
      ],
      onChanged: onChanged,
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $count',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
