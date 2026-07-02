import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../domain/product.dart';
import '../domain/product_controller.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.maybeWhen(data: (d) => Text(d.summary.name), orElse: () => const Text('Product')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(productDetailProvider(productId)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load: $err')),
        data: (detail) => _DetailBody(productId: productId, detail: detail),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.productId, required this.detail});

  final int productId;
  final ProductDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = detail.summary;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(productDetailProvider(productId)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('SKU', p.sku ?? '-'),
                  if (p.barcode != null && p.barcode!.isNotEmpty) _row('Barcode', p.barcode!),
                  _row('Category', p.categoryName ?? '-'),
                  if (p.brandName != null) _row('Brand', p.brandName!),
                  if (detail.description != null && detail.description!.isNotEmpty) _row('Description', detail.description!),
                  const Divider(height: 24),
                  _row('Sell Price', formatMoney(p.sellPrice)),
                  _row('Cost Price', formatMoney(p.costPrice)),
                  _row('Stock Qty', '${p.stockQty}', bold: true, color: p.isLowStock ? Colors.red : null),
                  _row('Min Stock Alert', '${p.minStock}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.tune),
              label: const Text('Adjust Stock'),
              onPressed: () => _showAdjustStockSheet(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Stock Movements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (detail.movements.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('No stock movements yet.'))
          else
            ...detail.movements.map((m) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      m.qty >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: m.qty >= 0 ? Colors.green : Colors.red,
                    ),
                    title: Text('${statusLabel(m.type)} · ${m.qty >= 0 ? '+' : ''}${m.qty}'),
                    subtitle: Text(
                      '${m.beforeQty} → ${m.afterQty}'
                      '${m.reference != null ? ' · ${m.reference}' : ''}'
                      '${m.note != null && m.note!.isNotEmpty ? ' · ${m.note}' : ''}',
                    ),
                    trailing: Text(formatDateTime(m.createdAt), style: const TextStyle(fontSize: 11)),
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
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockSheet(BuildContext context, WidgetRef ref) {
    final qtyController = TextEditingController();
    final noteController = TextEditingController();

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
              const Text('Adjust Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              const Text(
                'Use a positive number to add stock, negative to remove.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Qty change (e.g. 5 or -2)'),
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final qty = int.tryParse(qtyController.text.trim());
                    if (qty == null || qty == 0) return;
                    Navigator.of(sheetContext).pop();
                    try {
                      await ref.read(productRepositoryProvider).adjustStock(
                            productId,
                            qty: qty,
                            note: noteController.text.trim(),
                          );
                      ref.invalidate(productDetailProvider(productId));
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
