import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/notify_sheet.dart';
import '../domain/due.dart';
import '../domain/dues_controller.dart';

class DueDetailScreen extends ConsumerWidget {
  const DueDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(dueDetailProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.maybeWhen(data: (d) => Text(d.name), orElse: () => const Text('Dues')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dueDetailProvider(customerId)),
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
  final DueCustomerDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dueDetailProvider(customerId)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Phone', detail.phone),
                  _row('Outstanding Dues', formatMoney(detail.totalDues), bold: true, color: Colors.red),
                  if (detail.snoozedUntil != null) _row('Snoozed Until', detail.snoozedUntil!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Send Reminder'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
              onPressed: () => showNotifySheet(
                context,
                phone: detail.phone,
                name: detail.name,
                event: 'due_reminder',
                dueId: customerId,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.snooze),
              label: const Text('Snooze Due Date'),
              onPressed: () => _showSnoozeSheet(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (detail.ledger.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('No ledger entries.'))
          else
            ...detail.ledger.map((l) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    title: Text(statusLabel(l.type)),
                    subtitle: Text(
                      '${formatDateTime(l.createdAt)}'
                      '${l.dueDate != null ? ' · Due: ${l.dueDate}' : ''}'
                      '${l.note != null && l.note!.isNotEmpty ? ' · ${l.note}' : ''}',
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${l.amount > 0 ? '+' : ''}${formatMoney(l.amount)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: l.amount > 0 ? Colors.red : Colors.green),
                        ),
                        Text('Bal: ${formatMoney(l.balanceAfter)}', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
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
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color))),
        ],
      ),
    );
  }

  void _showSnoozeSheet(BuildContext context, WidgetRef ref) {
    final daysController = TextEditingController(text: '7');
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
              const Text('Snooze Due Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: daysController,
                decoration: const InputDecoration(labelText: 'Days'),
                keyboardType: TextInputType.number,
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
                    final days = int.tryParse(daysController.text.trim());
                    if (days == null || days <= 0) return;
                    Navigator.of(sheetContext).pop();
                    try {
                      await ref.read(duesRepositoryProvider).snooze(customerId, days: days, note: noteController.text.trim());
                      ref.invalidate(dueDetailProvider(customerId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: const Text('Snooze'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
