import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/screens/pdf_preview_screen.dart';
import '../../../core/utils/formatters.dart';
import '../../crm/domain/crm_controller.dart';
import '../../crm/domain/crm_customer.dart';
import '../domain/pos_controller.dart';
import '../domain/pos_models.dart';

class PosTerminalScreen extends ConsumerStatefulWidget {
  const PosTerminalScreen({super.key});

  @override
  ConsumerState<PosTerminalScreen> createState() => _PosTerminalScreenState();
}

class _PosTerminalScreenState extends ConsumerState<PosTerminalScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int? _categoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terminalAsync = ref.watch(posTerminalProvider);
    final cart = ref.watch(posCartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Terminal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause_circle_outline),
            tooltip: 'Held Sales',
            onPressed: () => _showHeldSalesSheet(context, terminalAsync.value?.heldSales ?? const []),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Quick Add Product',
            onPressed: () => _showQuickAddProductSheet(context),
          ),
        ],
      ),
      body: terminalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load: $err')),
        data: (terminal) => _buildBody(terminal),
      ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : SafeArea(
              child: Material(
                elevation: 8,
                child: InkWell(
                  onTap: () => _showCartSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10),
                        Text('${cart.items.length} item(s)', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(formatMoney(cart.total),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_up),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(PosTerminalData terminal) {
    final filtered = terminal.products.where((p) {
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          (p.sku?.toLowerCase().contains(q) ?? false) ||
          (p.barcode?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search product, SKU, barcode...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _categoryChip(null, 'All'),
              for (final c in terminal.categories) _categoryChip(c.id, c.name),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No products found.'))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _ProductCard(product: filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _categoryChip(int? id, String label) {
    final selected = _categoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _categoryId = id),
      ),
    );
  }

  void _showHeldSalesSheet(BuildContext context, List<PosHeldSale> heldSales) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Held Sales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                if (heldSales.isEmpty)
                  const Padding(padding: EdgeInsets.all(8), child: Text('No held sales.'))
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.5),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: heldSales.length,
                      itemBuilder: (context, index) {
                        final held = heldSales[index];
                        return ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: Text('${held.items.length} item(s)${held.note != null && held.note!.isNotEmpty ? ' · ${held.note}' : ''}'),
                          subtitle: Text(formatDateTime(held.createdAt)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ref.read(posRepositoryProvider).deleteHeld(held.id);
                              ref.invalidate(posTerminalProvider);
                              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                            },
                          ),
                          onTap: () async {
                            final terminal = ref.read(posTerminalProvider).value;
                            if (terminal != null) {
                              ref.read(posCartProvider.notifier).resumeHeld(held, terminal.products);
                            }
                            await ref.read(posRepositoryProvider).deleteHeld(held.id);
                            ref.invalidate(posTerminalProvider);
                            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
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

  void _showQuickAddProductSheet(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final skuController = TextEditingController();
    final stockController = TextEditingController(text: '10');

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
              const Text('Quick Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), autofocus: true),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Sell Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(controller: skuController, decoration: const InputDecoration(labelText: 'SKU (optional)')),
              const SizedBox(height: 8),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Initial Stock'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final price = num.tryParse(priceController.text.trim());
                    if (name.isEmpty || price == null) return;
                    Navigator.of(sheetContext).pop();
                    try {
                      await ref.read(posRepositoryProvider).quickAddProduct(
                            name: name,
                            sellPrice: price,
                            sku: skuController.text.trim(),
                            stockQty: int.tryParse(stockController.text.trim()) ?? 10,
                          );
                      ref.invalidate(posTerminalProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: const Text('Add Product'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _CartSheet(),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final PosProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outOfStock = product.stockQty <= 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: outOfStock ? null : () => ref.read(posCartProvider.notifier).addProduct(product),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Text(product.sku ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(formatMoney(product.sellPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    outOfStock ? 'Out of stock' : 'Qty ${product.stockQty}',
                    style: TextStyle(fontSize: 11, color: outOfStock ? Colors.red : Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartSheet extends ConsumerStatefulWidget {
  const _CartSheet();

  @override
  ConsumerState<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<_CartSheet> {
  final _paidController = TextEditingController();

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posCartProvider);
    final paid = num.tryParse(_paidController.text.trim()) ?? 0;
    final due = (cart.grandTotal - paid).clamp(0, double.infinity);
    final change = (paid - cart.grandTotal).clamp(0, double.infinity);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (sheetContext, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              for (var i = 0; i < cart.items.length; i++) _CartLineTile(index: i, line: cart.items[i]),
              const Divider(height: 24),
              ListTile(
                dense: true,
                title: const Text('Customer'),
                subtitle: Text(cart.customerName.isEmpty ? 'Walk-in customer' : '${cart.customerName} · ${cart.customerPhone}'),
                trailing: TextButton(
                  onPressed: () => _showCustomerPicker(context),
                  child: Text(cart.customerName.isEmpty ? 'Select' : 'Change'),
                ),
              ),
              if (cart.previousDuesPaid > 0)
                ListTile(
                  dense: true,
                  title: const Text('Previous Dues Included'),
                  trailing: Text(formatMoney(cart.previousDuesPaid)),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: cart.discountType,
                      decoration: const InputDecoration(labelText: 'Discount Type'),
                      items: const [
                        DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                        DropdownMenuItem(value: 'percent', child: Text('Percent')),
                      ],
                      onChanged: (v) => ref.read(posCartProvider.notifier).setDiscount(v ?? 'fixed', cart.discountValue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: cart.discountValue == 0 ? '' : cart.discountValue.toString(),
                      decoration: const InputDecoration(labelText: 'Discount'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) =>
                          ref.read(posCartProvider.notifier).setDiscount(cart.discountType, num.tryParse(v) ?? 0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: cart.paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'mobile', child: Text('Mobile Payment')),
                ],
                onChanged: (v) => ref.read(posCartProvider.notifier).setPaymentMethod(v ?? 'cash'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _paidController,
                decoration: const InputDecoration(labelText: 'Paid Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _summaryRow('Subtotal', formatMoney(cart.subtotal)),
              _summaryRow('Discount', formatMoney(cart.discountAmount)),
              _summaryRow('Total', formatMoney(cart.grandTotal), bold: true),
              if (due > 0) _summaryRow('Due', formatMoney(due), color: Colors.red),
              if (change > 0) _summaryRow('Change', formatMoney(change), color: Colors.green),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.pause),
                      label: const Text('Hold'),
                      onPressed: cart.items.isEmpty
                          ? null
                          : () async {
                              await ref.read(posCartProvider.notifier).hold();
                              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text(cart.isSubmitting ? 'Processing...' : 'Checkout'),
                      onPressed: cart.items.isEmpty || cart.isSubmitting
                          ? null
                          : () async {
                              final repo    = ref.read(posRepositoryProvider);
                              final nav     = Navigator.of(sheetContext);
                              final rootNav = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                final result = await ref.read(posCartProvider.notifier).checkout(paid);
                                if (nav.canPop()) nav.pop();
                                if (!rootNav.mounted) return;
                                // Open PDF invoice preview
                                await PdfPreviewScreen.push(
                                  rootNav.context,
                                  title: 'Invoice ${result.invoiceNumber}',
                                  fileName: 'invoice-${result.invoiceNumber}.pdf',
                                  loadBytes: () async =>
                                      Uint8List.fromList(await repo.invoicePdf(result.saleId)),
                                );
                              } catch (e) {
                                messenger.showSnackBar(SnackBar(content: Text('$e')));
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  void _showCustomerPicker(BuildContext context) {
    final controller = TextEditingController();
    List<CrmCustomerSummary> results = [];

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
                  const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Search by name or phone', prefixIcon: Icon(Icons.search)),
                    autofocus: true,
                    onChanged: (v) async {
                      if (v.trim().isEmpty) {
                        setSheetState(() => results = []);
                        return;
                      }
                      final res = await ref.read(crmRepositoryProvider).search(v.trim());
                      setSheetState(() => results = res);
                    },
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.4),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final c = results[index];
                        return ListTile(
                          title: Text(c.name),
                          subtitle: Text(c.phone),
                          onTap: () {
                            ref.read(posCartProvider.notifier).setCustomer(
                                  id: c.id,
                                  name: c.name,
                                  phone: c.phone,
                                  previousDuesPaid: 0,
                                );
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Walk-in (no customer)'),
                    onPressed: () {
                      ref.read(posCartProvider.notifier).clearCustomer();
                      Navigator.of(sheetContext).pop();
                    },
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

class _CartLineTile extends ConsumerStatefulWidget {
  const _CartLineTile({required this.index, required this.line});

  final int index;
  final CartLine line;

  @override
  ConsumerState<_CartLineTile> createState() => _CartLineTileState();
}

class _CartLineTileState extends ConsumerState<_CartLineTile> {
  late final TextEditingController _discCtrl;
  late final TextEditingController _imeiCtrl;
  late final TextEditingController _warrantyCtrl;

  @override
  void initState() {
    super.initState();
    _discCtrl    = TextEditingController(text: widget.line.discount > 0 ? widget.line.discount.toString() : '');
    _imeiCtrl    = TextEditingController(text: widget.line.imeiSn ?? '');
    _warrantyCtrl = TextEditingController(text: widget.line.warrantyDays > 0 ? widget.line.warrantyDays.toString() : '');
  }

  @override
  void dispose() {
    _discCtrl.dispose();
    _imeiCtrl.dispose();
    _warrantyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(posCartProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final line = widget.line;
    final i = widget.index;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + qty + total + remove ───────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(formatMoney(line.price), style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => notifier.updateQty(i, line.qty - 1),
              ),
              Text('${line.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => notifier.updateQty(i, line.qty + 1),
              ),
              SizedBox(
                width: 64,
                child: Text(formatMoney(line.total),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => notifier.removeAt(i),
              ),
            ],
          ),

          // ── Option toggles ────────────────────────────────────────────
          Wrap(
            spacing: 6,
            children: [
              _OptionToggle(
                label: line.discount > 0 ? 'Disc: -${formatMoney(line.discount)}' : '+Discount',
                active: line.discountOpen,
                activeColor: Colors.orange,
                onTap: () => notifier.toggleItemField(i, 'discount'),
              ),
              _OptionToggle(
                label: (line.imeiSn?.isNotEmpty == true) ? 'IMEI: ${line.imeiSn}' : '+IMEI/SN',
                active: line.imeiOpen,
                activeColor: Colors.blue,
                onTap: () => notifier.toggleItemField(i, 'imei'),
              ),
              _OptionToggle(
                label: line.warrantyDays > 0 ? 'Warranty: ${line.warrantyDays}d' : '+Warranty',
                active: line.warrantyOpen,
                activeColor: Colors.green,
                onTap: () => notifier.toggleItemField(i, 'warranty'),
              ),
            ],
          ),

          // ── Discount input ────────────────────────────────────────────
          if (line.discountOpen)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextField(
                controller: _discCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item Discount',
                  prefixIcon: Icon(Icons.discount_outlined, size: 18),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => notifier.updateItemDiscount(i, num.tryParse(v) ?? 0),
              ),
            ),

          // ── IMEI / SN input ───────────────────────────────────────────
          if (line.imeiOpen)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextField(
                controller: _imeiCtrl,
                decoration: const InputDecoration(
                  labelText: 'IMEI / Serial Number',
                  prefixIcon: Icon(Icons.fingerprint, size: 18),
                  isDense: true,
                ),
                onChanged: (v) => notifier.updateItemImeiSn(i, v),
              ),
            ),

          // ── Warranty input ────────────────────────────────────────────
          if (line.warrantyOpen)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextField(
                controller: _warrantyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Warranty Days',
                  prefixIcon: Icon(Icons.verified_outlined, size: 18),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => notifier.updateItemWarrantyDays(i, int.tryParse(v) ?? 0),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionToggle extends StatelessWidget {
  const _OptionToggle({required this.label, required this.active, required this.activeColor, required this.onTap});

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(color: active ? activeColor : Colors.grey.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, color: active ? activeColor : Colors.grey, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
