import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_colors.dart';
import '../../../core/widgets/notify_sheet.dart';
import '../../../core/widgets/status_chip.dart';
import '../domain/crm_controller.dart';
import '../domain/crm_customer.dart';

class CrmDetailScreen extends ConsumerWidget {
  const CrmDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(crmDetailProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.maybeWhen(data: (d) => Text(d.summary.name), orElse: () => const Text('Customer')),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Statement',
            onPressed: () => context.push('/crm/$customerId/statement'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(crmDetailProvider(customerId)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load: $err')),
        data: (detail) => _DetailBody(customerId: customerId, detail: detail),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.customerId, required this.detail});

  final int customerId;
  final CrmCustomerDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = detail.summary;
    final hasDues = c.totalDues > 0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(crmDetailProvider(customerId)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Phone', c.phone),
                  if (detail.phone2 != null && detail.phone2!.isNotEmpty) _row('Phone 2', detail.phone2!),
                  if (detail.email != null && detail.email!.isNotEmpty) _row('Email', detail.email!),
                  if (c.city != null && c.city!.isNotEmpty) _row('City', c.city!),
                  if (detail.address != null && detail.address!.isNotEmpty) _row('Address', detail.address!),
                  const Divider(height: 24),
                  _row('Total Spent', formatMoney(c.totalSpent)),
                  _row('Outstanding Dues', formatMoney(c.totalDues),
                      bold: true, color: hasDues ? Colors.red : null),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.contact_phone_outlined),
              label: const Text('Contact Customer'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF25D366)),
              onPressed: () => showNotifySheet(
                context,
                phone: c.phone,
                email: detail.email ?? '',
                name: c.name,
                event: hasDues ? 'due_reminder' : 'job_ready',
                crmId: customerId,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (hasDues)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.payments),
                label: const Text('Collect Due'),
                onPressed: () => _showCollectDueSheet(context, ref),
              ),
            ),
          const SizedBox(height: 24),
          const Text('Repair Jobs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (detail.repairs.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('No repair jobs.'))
          else
            ...detail.repairs.map((r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    onTap: () => context.push('/repair-jobs/${r.id}'),
                    title: Text('${r.jobNumber} · ${r.deviceModel ?? '-'}'),
                    subtitle: Text(formatDateTime(r.createdAt)),
                    trailing: StatusChip.status(r.status, repairStatusColor(r.status)),
                  ),
                )),
          const SizedBox(height: 24),
          const Text('POS Sales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (detail.sales.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('No sales.'))
          else
            ...detail.sales.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text(s.invoiceNumber),
                    subtitle: Text(formatDateTime(s.createdAt)),
                    trailing: Text(formatMoney(s.totalAmount)),
                  ),
                )),
          if (detail.warranties.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Warranties', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...detail.warranties.map((w) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text(w.productName ?? '-'),
                    subtitle: Text('Expires: ${w.expiryDate ?? '-'}'),
                    trailing: StatusChip(label: w.status, color: w.status == 'active' ? Colors.green : Colors.grey),
                  ),
                )),
          ],
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
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
          ),
        ],
      ),
    );
  }

  void _showCollectDueSheet(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController(text: detail.summary.totalDues.toString());

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
              const Text('Collect Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim()) ?? 0;
                    if (amount <= 0) return;
                    Navigator.of(sheetContext).pop();
                    try {
                      await ref.read(crmRepositoryProvider).collectDue(customerId, amount);
                      ref.invalidate(crmDetailProvider(customerId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: const Text('Collect'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
