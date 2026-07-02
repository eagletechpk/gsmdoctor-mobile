import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../domain/purchase.dart';
import '../domain/purchase_controller.dart';

class PurchaseCreateScreen extends ConsumerWidget {
  const PurchaseCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataAsync = ref.watch(purchaseFormDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Purchase Order')),
      body: formDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load: $err')),
        data: (formData) => _CreateBody(formData: formData),
      ),
    );
  }
}

class _CreateBody extends ConsumerStatefulWidget {
  const _CreateBody({required this.formData});

  final PurchaseFormData formData;

  @override
  ConsumerState<_CreateBody> createState() => _CreateBodyState();
}

class _CreateBodyState extends ConsumerState<_CreateBody> {
  final _paidController = TextEditingController(text: '0');
  final _cargoController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _paidController.dispose();
    _cargoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newPurchaseProvider);
    final notifier = ref.read(newPurchaseProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<int>(
          initialValue: state.supplierId,
          decoration: const InputDecoration(labelText: 'Supplier'),
          items: widget.formData.suppliers
              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.company != null && s.company!.isNotEmpty ? '${s.name} (${s.company})' : s.name)))
              .toList(),
          onChanged: (v) => notifier.setSupplier(v),
        ),
        const SizedBox(height: 16),
        const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
          onPressed: () => _showProductPicker(context),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < state.items.length; i++) _ItemTile(index: i, item: state.items[i]),
        const Divider(height: 24),
        TextField(
          controller: _cargoController,
          decoration: const InputDecoration(labelText: 'Cargo Charges'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => notifier.setCargoCharges(num.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: state.status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: purchaseOrderStatusOptions.map((s) => DropdownMenuItem(value: s, child: Text(statusLabel(s)))).toList(),
          onChanged: (v) => notifier.setStatus(v ?? 'received'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _paidController,
          decoration: const InputDecoration(labelText: 'Paid Amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => notifier.setPaidAmount(num.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: state.accountId,
          decoration: const InputDecoration(labelText: 'Pay From Account (optional)'),
          items: widget.formData.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
          onChanged: (v) => notifier.setAccount(v),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
          maxLines: 2,
          onChanged: (v) => notifier.setNotes(v),
        ),
        const SizedBox(height: 16),
        _summaryRow('Items Total', formatMoney(state.itemsTotal)),
        _summaryRow('Grand Total', formatMoney(state.grandTotal), bold: true),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.isSubmitting
                ? null
                : () async {
                    try {
                      final result = await notifier.submit();
                      if (context.mounted) {
                        context.pushReplacement('/purchases/${result.summary.id}');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
            child: Text(state.isSubmitting ? 'Creating...' : 'Create Purchase Order'),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _showProductPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.formData.products.length,
                    itemBuilder: (context, index) {
                      final p = widget.formData.products[index];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text('${p.sku ?? ''} · Stock: ${p.stockQty}'),
                        trailing: Text(formatMoney(p.costPrice)),
                        onTap: () {
                          ref.read(newPurchaseProvider.notifier).addProduct(p);
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.index, required this.item});

  final int index;
  final NewPurchaseItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Cost: ${formatMoney(item.costPrice)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => ref.read(newPurchaseProvider.notifier).updateQty(index, item.qty - 1),
          ),
          Text('${item.qty}'),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => ref.read(newPurchaseProvider.notifier).updateQty(index, item.qty + 1),
          ),
          SizedBox(width: 70, child: Text(formatMoney(item.total), textAlign: TextAlign.right)),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => ref.read(newPurchaseProvider.notifier).removeAt(index),
          ),
        ],
      ),
    );
  }
}
