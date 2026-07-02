import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_colors.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/auth_controller.dart';
import '../domain/gsm_order.dart';
import '../domain/gsm_order_controller.dart';

class GsmOrderDetailScreen extends ConsumerWidget {
  const GsmOrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(gsmOrderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.maybeWhen(data: (d) => Text(d.summary.orderNumber), orElse: () => const Text('Order')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(gsmOrderDetailProvider(orderId)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load: $err')),
        data: (detail) => _DetailBody(orderId: orderId, detail: detail),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.orderId, required this.detail});

  final int orderId;
  final GsmOrderDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = detail.summary;
    final isAdmin = ref.watch(authControllerProvider).user?.isAdmin ?? false;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(gsmOrderDetailProvider(orderId)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(o.serviceName ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      StatusChip.status(o.status, orderStatusColor(o.status)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _row('Customer', o.customerName ?? '-'),
                  if (detail.customerPhone != null) _row('Phone', detail.customerPhone!),
                  if (o.imei != null && o.imei!.isNotEmpty) _row('IMEI', o.imei!),
                  if (detail.sn != null && detail.sn!.isNotEmpty) _row('SN', detail.sn!),
                  if (detail.username != null && detail.username!.isNotEmpty) _row('Username', detail.username!),
                  if (detail.notes != null && detail.notes!.isNotEmpty) _row('Notes', detail.notes!),
                  const Divider(height: 24),
                  _row('Qty', '${o.quantity}'),
                  _row('Total Price', formatMoney(o.totalPrice), bold: true),
                  if (detail.result != null && detail.result!.isNotEmpty) _row('Result', detail.result!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (isAdmin) _buildActions(context, ref, o),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, GsmOrderSummary o) {
    final buttons = <Widget>[];

    if (o.status == 'pending') {
      buttons.add(_actionButton(context, ref, 'Accept', Icons.check_circle_outline, () async {
        await ref.read(gsmOrderRepositoryProvider).accept(o.id);
        ref.invalidate(gsmOrderDetailProvider(o.id));
      }));
    }
    if (o.status == 'pending' || o.status == 'processing') {
      buttons.add(_actionButton(context, ref, 'Complete', Icons.task_alt, () async => _showCompleteSheet(context, ref, o.id)));
      buttons.add(_actionButton(context, ref, 'Cancel (Refund)', Icons.cancel_outlined, () async {
        await ref.read(gsmOrderRepositoryProvider).cancel(o.id);
        ref.invalidate(gsmOrderDetailProvider(o.id));
      }));
      buttons.add(_actionButton(context, ref, 'Reject (No Refund)', Icons.block, () async {
        await ref.read(gsmOrderRepositoryProvider).reject(o.id);
        ref.invalidate(gsmOrderDetailProvider(o.id));
      }));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }

  Widget _actionButton(BuildContext context, WidgetRef ref, String label, IconData icon, Future<void> Function() onPressed) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () async {
        try {
          await onPressed();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
          }
        }
      },
    );
  }

  void _showCompleteSheet(BuildContext context, WidgetRef ref, int orderId) {
    final resultController = TextEditingController();

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
              const Text('Complete Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: resultController,
                decoration: const InputDecoration(labelText: 'Result / unlock code'),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    try {
                      await ref.read(gsmOrderRepositoryProvider).complete(orderId, result: resultController.text.trim());
                      ref.invalidate(gsmOrderDetailProvider(orderId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: const Text('Mark Completed'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
