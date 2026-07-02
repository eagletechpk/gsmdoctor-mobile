import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/formatters.dart';
import '../domain/online_orders_controller.dart';
import '../domain/online_order.dart';

class OnlineOrderDetailScreen extends ConsumerWidget {
  const OnlineOrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(onlineOrderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: async.maybeWhen(
          data: (d) => Text(d.orderNumber),
          orElse: () => const Text('Order Detail'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(onlineOrderDetailProvider(orderId)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CustomerCard(order: order),
            const SizedBox(height: 12),
            _StatusCard(order: order, ref: ref, orderId: orderId),
            const SizedBox(height: 12),
            _ItemsCard(order: order, ref: ref, orderId: orderId),
            const SizedBox(height: 12),
            _TotalsCard(order: order),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});
  final OnlineOrderDetail order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8),
            Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (order.customerEmail != null) Text(order.customerEmail!),
            if (order.customerPhone != null) Text(order.customerPhone!),
            if (order.shippingAddress != null && order.shippingAddress!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Ship to: ${order.shippingAddress!}',
                  style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order, required this.ref, required this.orderId});
  final OnlineOrderDetail order;
  final WidgetRef ref;
  final int orderId;

  Future<void> _updatePayment(BuildContext context, String current) async {
    final options = ['pending', 'paid', 'refunded', 'failed'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Payment Status'),
        children: options
            .map((o) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, o),
                  child: Text(o[0].toUpperCase() + o.substring(1),
                      style: TextStyle(
                          fontWeight: o == current ? FontWeight.bold : null)),
                ))
            .toList(),
      ),
    );
    if (selected == null || selected == current) return;
    try {
      await ref.read(onlineOrdersRepoProvider).updatePayment(orderId, selected);
      ref.invalidate(onlineOrderDetailProvider(orderId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateFulfillment(BuildContext context, String current) async {
    final options = ['unfulfilled', 'processing', 'shipped', 'completed', 'cancelled'];
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Fulfillment Status'),
        children: options
            .map((o) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, o),
                  child: Text(o[0].toUpperCase() + o.substring(1),
                      style: TextStyle(
                          fontWeight: o == current ? FontWeight.bold : null)),
                ))
            .toList(),
      ),
    );
    if (selected == null || selected == current) return;
    try {
      await ref.read(onlineOrdersRepoProvider).updateFulfillment(orderId, selected);
      ref.invalidate(onlineOrderDetailProvider(orderId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.payment, size: 16),
                    label: Text('Pay: ${order.paymentStatus}', style: const TextStyle(fontSize: 12)),
                    onPressed: () => _updatePayment(context, order.paymentStatus),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.local_shipping, size: 16),
                    label: Text('Ship: ${order.fulfillmentStatus}',
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () => _updateFulfillment(context, order.fulfillmentStatus),
                  ),
                ),
              ],
            ),
            if (order.paymentMethod != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Payment method: ${order.paymentMethod!}',
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order, required this.ref, required this.orderId});
  final OnlineOrderDetail order;
  final WidgetRef ref;
  final int orderId;

  Future<void> _deliverService(
      BuildContext context, OnlineOrderItem item) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deliver Service Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (item.imei != null) Text('IMEI: ${item.imei}'),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                  labelText: 'Service Code / Reply', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Deliver')),
        ],
      ),
    );
    if (confirmed != true || ctrl.text.trim().isEmpty) return;
    try {
      await ref.read(onlineOrdersRepoProvider).deliverService(orderId, item.id, ctrl.text.trim());
      ref.invalidate(onlineOrderDetailProvider(orderId));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Service code delivered.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items (${order.items.length})',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8),
            for (final item in order.items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${item.itemType} · qty ${item.quantity} · ${formatMoney(item.price)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (item.imei != null) Text('IMEI: ${item.imei}', style: const TextStyle(fontSize: 12)),
                        if (item.replyCode != null && item.replyCode!.isNotEmpty)
                          Text('Code: ${item.replyCode}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (item.needsServiceCode)
                    TextButton(
                      onPressed: () => _deliverService(context, item),
                      child: const Text('Deliver', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              if (item != order.items.last) const Divider(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});
  final OnlineOrderDetail order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _Row('Subtotal', formatMoney(order.subtotal)),
            if (order.shippingCost > 0) _Row('Shipping', formatMoney(order.shippingCost)),
            if (order.taxAmount > 0) _Row('Tax', formatMoney(order.taxAmount)),
            const Divider(),
            _Row('Total', formatMoney(order.totalAmount), bold: true),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style =
        bold ? const TextStyle(fontWeight: FontWeight.bold) : const TextStyle();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
