import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_colors.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/purchase.dart';
import '../domain/purchase_controller.dart';

class PurchaseDetailScreen extends ConsumerWidget {
  const PurchaseDetailScreen({super.key, required this.poId});

  final int poId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(purchaseDetailProvider(poId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.maybeWhen(data: (d) => Text(d.summary.poNumber), orElse: () => const Text('Purchase Order')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(purchaseDetailProvider(poId)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load: $err')),
        data: (detail) => _DetailBody(poId: poId, detail: detail),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.poId, required this.detail});

  final int poId;
  final PurchaseOrderDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final po = detail.summary;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(purchaseDetailProvider(poId)),
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
                      Expanded(child: Text(po.supplierName ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      StatusChip.status(po.status, poStatusColor(po.status)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (detail.createdByName != null) _row('Created By', detail.createdByName!),
                  if (detail.notes != null && detail.notes!.isNotEmpty) _row('Notes', detail.notes!),
                  const Divider(height: 24),
                  _row('Total', formatMoney(po.totalAmount), bold: true),
                  _row('Paid', formatMoney(po.paidAmount)),
                  _row('Due', formatMoney(po.dueAmount), color: po.dueAmount > 0 ? Colors.red : null),
                  if (detail.cargoCharges > 0) _row('Cargo Charges', formatMoney(detail.cargoCharges)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (po.status != 'received')
                OutlinedButton.icon(
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Mark Received'),
                  onPressed: () => _updateStatus(context, ref, 'received'),
                ),
              if (po.status != 'cancelled' && po.status != 'received')
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                  onPressed: () => _updateStatus(context, ref, 'cancelled'),
                ),
              if (po.dueAmount > 0)
                FilledButton.icon(
                  icon: const Icon(Icons.payments),
                  label: const Text('Add Payment'),
                  onPressed: () => _showPaymentSheet(context, ref),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...detail.items.map((i) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(i.productName ?? 'Product #${i.productId}'),
                  subtitle: Text('Qty: ${i.qty} × ${formatMoney(i.costPrice)}'),
                  trailing: Text(formatMoney(i.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color))),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref.read(purchaseRepositoryProvider).updateStatus(poId, status: status);
      ref.invalidate(purchaseDetailProvider(poId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _showPaymentSheet(BuildContext context, WidgetRef ref) async {
    PurchaseFormData formData;
    try {
      formData = await ref.read(purchaseFormDataProvider.future);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load form data: $e')));
      }
      return;
    }
    if (!context.mounted) return;
    final amountController = TextEditingController(text: detail.summary.dueAmount.toString());
    int? accountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                  const Text('Add Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: accountId,
                    decoration: const InputDecoration(labelText: 'Account'),
                    items: formData.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                    onChanged: (v) => setSheetState(() => accountId = v),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final amount = num.tryParse(amountController.text.trim());
                        if (amount == null || amount <= 0 || accountId == null) return;
                        Navigator.of(sheetContext).pop();
                        try {
                          await ref.read(purchaseRepositoryProvider).addPayment(poId, amount: amount, accountId: accountId!);
                          ref.invalidate(purchaseDetailProvider(poId));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      },
                      child: const Text('Record Payment'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
