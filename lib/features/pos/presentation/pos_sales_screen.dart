import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/screens/pdf_preview_screen.dart';
import '../../../core/utils/formatters.dart';
import '../domain/pos_controller.dart';

final _dateFmt = DateFormat('dd MMM yy');

class PosSalesScreen extends ConsumerStatefulWidget {
  const PosSalesScreen({super.key});

  @override
  ConsumerState<PosSalesScreen> createState() => _PosSalesScreenState();
}

class _PosSalesScreenState extends ConsumerState<PosSalesScreen> {
  List<Map<String, dynamic>> _sales = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _from = _todayMonth();
  String _to   = _today();

  static String _todayMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(posRepositoryProvider);
      final sales = await repo.salesList(from: _from, to: _to, q: _searchCtrl.text.trim());
      if (mounted) setState(() { _sales = sales; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _openInvoice(int saleId, String invoiceNumber) async {
    final repo = ref.read(posRepositoryProvider);
    await PdfPreviewScreen.push(
      context,
      title: 'Invoice $invoiceNumber',
      fileName: 'invoice-$invoiceNumber.pdf',
      loadBytes: () async => Uint8List.fromList(await repo.invoicePdf(saleId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = _sales.fold<double>(0, (s, e) => s + ((e['total_amount'] as num?)?.toDouble() ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Sales History'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // ── Filters ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search invoice / customer…',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                _DateBtn(label: _dateFmt.format(DateTime.tryParse(_from) ?? DateTime.now()), onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(_from) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _from = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}');
                    _load();
                  }
                }),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('–')),
                _DateBtn(label: _dateFmt.format(DateTime.tryParse(_to) ?? DateTime.now()), onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(_to) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _to = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}');
                    _load();
                  }
                }),
              ],
            ),
          ),

          // ── Summary bar ───────────────────────────────────────────────
          if (!_loading && _sales.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_sales.length} sales', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('Total: ${formatMoney(total)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _sales.isEmpty
                        ? const Center(child: Text('No sales in this period.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                              itemCount: _sales.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 6),
                              itemBuilder: (context, index) {
                                final s = _sales[index];
                                final isDue = ((s['due_amount'] as num?) ?? 0) > 0;
                                return Card(
                                  child: ListTile(
                                    onTap: () => _openInvoice(s['id'] as int, s['invoice_number'] as String),
                                    leading: CircleAvatar(
                                      backgroundColor: isDue
                                          ? Colors.red.withValues(alpha: 0.12)
                                          : cs.primaryContainer,
                                      child: Icon(
                                        Icons.receipt_long_outlined,
                                        size: 18,
                                        color: isDue ? Colors.red : cs.primary,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(s['invoice_number'] as String,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 8),
                                        _StatusBadge(status: s['status'] as String? ?? ''),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s['customer_name'] as String? ?? 'Walk-in',
                                            style: const TextStyle(fontSize: 12)),
                                        Text(
                                          formatDateTime(DateTime.tryParse(s['created_at'] as String? ?? '') ?? DateTime.now()),
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(formatMoney(s['total_amount']),
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (isDue)
                                          Text('Due: ${formatMoney(s['due_amount'])}',
                                              style: const TextStyle(fontSize: 11, color: Colors.red)),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  const _DateBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => Colors.green,
      'refunded'  => Colors.orange,
      'partial'   => Colors.blue,
      _           => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
