import 'dart:async';
import 'dart:math' show min;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/screens/pdf_preview_screen.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_colors.dart';
import '../../../core/widgets/notify_sheet.dart';
import '../../../core/widgets/receipt_send_sheet.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/auth_controller.dart';
import '../domain/repair_job.dart';
import '../domain/repair_jobs_controller.dart';

class RepairJobDetailScreen extends ConsumerWidget {
  const RepairJobDetailScreen({super.key, required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(repairJobDetailProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.maybeWhen(
          data: (d) => Text(d.summary.jobNumber),
          orElse: () => const Text('Repair Job'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(repairJobDetailProvider(jobId)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load: $err')),
        data: (detail) => _DetailBody(jobId: jobId, detail: detail),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.jobId, required this.detail});

  final int jobId;
  final RepairJobDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final job = detail.summary;
    final phone = job.customerPhone ?? '';

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(repairJobDetailProvider(jobId)),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Job info card ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.deviceModel ?? '-',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      StatusChip.status(job.status, repairStatusColor(job.status)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _row('Customer', job.customerName ?? 'Unknown'),
                  if (phone.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text('Phone', style: TextStyle(color: Colors.grey)),
                          ),
                          Expanded(child: Text(phone)),
                          // Quick contact icons
                          _ContactIcon(
                            icon: Icons.phone,
                            color: Colors.green,
                            tooltip: 'Call',
                            url: 'tel:$phone',
                          ),
                          const SizedBox(width: 4),
                          _ContactIcon(
                            icon: Icons.chat,
                            color: const Color(0xFF25D366),
                            tooltip: 'WhatsApp',
                            url: 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9+]'), '')}',
                          ),
                          const SizedBox(width: 4),
                          _ContactIcon(
                            icon: Icons.sms_outlined,
                            color: Colors.blueGrey,
                            tooltip: 'SMS',
                            url: 'sms:$phone',
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (job.imei != null && job.imei!.isNotEmpty) _row('IMEI', job.imei!),
                  if (detail.reportedIssue != null && detail.reportedIssue!.isNotEmpty)
                    _row('Reported Issue', detail.reportedIssue!),
                  const Divider(height: 24),
                  _row('Estimate', formatMoney(job.estimateCost)),
                  if ((detail.advancePaid ?? 0) > 0)
                    _row('Advance Paid', formatMoney(detail.advancePaid)),
                  _row('Balance Due', formatMoney(job.balanceDue), bold: true),
                  if (job.technicianName != null) _row('Technician', job.technicianName!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Action row: status + note ──────────────────────────────────
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Update Status'),
                  onPressed: () => _showStatusSheet(context, ref, job),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.note_add_outlined),
                  label: const Text('Add Note'),
                  onPressed: () => _showAddNoteSheet(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Notify customer ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Notify Customer'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF25D366)),
              onPressed: () => showNotifySheet(
                context,
                phone: phone,
                email: detail.customerEmail ?? '',
                name: job.customerName ?? '',
                event: job.status == 'received' ? 'job_received' : 'job_ready',
                jobId: jobId,
                reference: job.jobNumber,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Send receipt ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.receipt_outlined),
              label: const Text('Send Receipt'),
              onPressed: () => showReceiptSendSheet(context, job: job),
            ),
          ),
          const SizedBox(height: 8),

          // ── Add part ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.build_outlined),
              label: const Text('Add Part'),
              onPressed: () => _showAddPartSheet(context, ref),
            ),
          ),
          const SizedBox(height: 12),

          // ── PDF documents ──────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Receipt'),
                onPressed: () => _openPdf(context, ref, 'receipt', job.jobNumber),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.sell_outlined),
                label: const Text('Label'),
                onPressed: () => _openPdf(context, ref, 'label', job.jobNumber),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.description_outlined),
                label: const Text('Invoice'),
                onPressed: () => _openPdf(context, ref, 'invoice', job.jobNumber),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Status history ─────────────────────────────────────────────
          const Text('Status History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...detail.history.reversed.map((h) => _HistoryTile(event: h)),

          // ── Parts ──────────────────────────────────────────────────────
          if (detail.parts.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Parts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...detail.parts.map(
              (p) => ListTile(
                dense: true,
                title: Text(p.name),
                subtitle: Text('Qty: ${p.qty}'),
                trailing: Text(formatMoney(p.sellPrice)),
              ),
            ),
          ],

          // ── Progress notes ─────────────────────────────────────────────
          const SizedBox(height: 24),
          const Text('Progress Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...detail.notes.map(
            (n) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                title: Text(n.note),
                subtitle: Text('${n.userName ?? 'System'} · ${formatDateTime(n.createdAt)}'),
              ),
            ),
          ),
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
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(value,
                style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }

  // ── Status update sheet ──────────────────────────────────────────────────
  void _showStatusSheet(BuildContext context, WidgetRef ref, RepairJobSummary job) {
    final noteController = TextEditingController();
    String selected = job.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
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
                  const Text('Update Status',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in repairStatusOptions)
                        ChoiceChip(
                          label: Text(statusLabel(s)),
                          selected: selected == s,
                          onSelected: (_) => setState(() => selected = s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        try {
                          await ref.read(repairJobRepositoryProvider).updateStatus(
                                job.id,
                                selected,
                                note: noteController.text.trim(),
                              );
                          ref.invalidate(repairJobDetailProvider(job.id));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('$e')));
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
      },
    );
  }

  // ── Add note sheet ───────────────────────────────────────────────────────
  void _showAddNoteSheet(BuildContext context, WidgetRef ref) {
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
              const Text('Add Progress Note',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final text = noteController.text.trim();
                    if (text.isEmpty) return;
                    Navigator.of(sheetContext).pop();
                    try {
                      await ref.read(repairJobRepositoryProvider).addNote(jobId, text);
                      ref.invalidate(repairJobDetailProvider(jobId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('$e')));
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

  // ── Add part sheet (with live product search) ────────────────────────────
  void _showAddPartSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '0');
    final searchCtrl = TextEditingController();
    final dio = ref.read(dioProvider);
    Timer? searchTimer;
    List<Map<String, dynamic>> products = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void searchProducts(String q) {
              searchTimer?.cancel();
              if (q.isEmpty) {
                setModalState(() => products = []);
                return;
              }
              searchTimer = Timer(const Duration(milliseconds: 350), () async {
                try {
                  final res = await dio.get('/pos/products/search', queryParameters: {'q': q});
                  final list = (res.data['data']['products'] as List)
                      .cast<Map<String, dynamic>>();
                  if (ctx.mounted) setModalState(() => products = list);
                } catch (_) {}
              });
            }

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
                  const Text('Add Part',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  // Product search
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Search Product (optional)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                searchCtrl.clear();
                                setModalState(() => products = []);
                              },
                            )
                          : null,
                      isDense: true,
                    ),
                    onChanged: (v) {
                      setModalState(() {}); // refresh suffix icon
                      searchProducts(v);
                    },
                  ),

                  // Product suggestions
                  if (products.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(maxHeight: min(products.length * 56.0, 168)),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: products.map((p) {
                          final stock = p['stock_qty'] as num? ?? 0;
                          return ListTile(
                            dense: true,
                            title: Text(p['name'] as String? ?? ''),
                            subtitle: Text('Stock: $stock'),
                            trailing: Text(
                              formatMoney(p['sell_price'] as num?),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onTap: () {
                              nameCtrl.text = p['name'] as String? ?? '';
                              priceCtrl.text =
                                  (p['sell_price'] as num? ?? 0).toString();
                              searchCtrl.clear();
                              setModalState(() => products = []);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Part Name', border: OutlineInputBorder()),
                    autofocus: products.isEmpty,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Qty', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Sell Price', border: OutlineInputBorder()),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                        final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                        Navigator.of(sheetContext).pop();
                        try {
                          await ref.read(repairJobRepositoryProvider).addPart(
                                jobId,
                                name: name,
                                qty: qty,
                                sellPrice: price,
                              );
                          ref.invalidate(repairJobDetailProvider(jobId));
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      },
                      child: const Text('Add Part'),
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

  // ── PDF preview (with back button via PdfPreviewScreen) ──────────────────
  Future<void> _openPdf(
      BuildContext context, WidgetRef ref, String type, String jobNumber) async {
    final repo = ref.read(repairJobRepositoryProvider);
    try {
      await PdfPreviewScreen.push(
        context,
        title: '${statusLabel(type)} — $jobNumber',
        fileName: '$type-$jobNumber.pdf',
        loadBytes: () async {
          final bytes = switch (type) {
            'label' => await repo.labelPdf(jobId),
            'invoice' => await repo.invoicePdf(jobId),
            _ => await repo.receiptPdf(jobId),
          };
          return Uint8List.fromList(bytes);
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load $type: $e')));
      }
    }
  }
}

// ── Quick contact icon ───────────────────────────────────────────────────────

class _ContactIcon extends StatelessWidget {
  const _ContactIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.url,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ── Status history tile ──────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.event});

  final RepairStatusEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 10),
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: repairStatusColor(event.status)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusLabel(event.status),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (event.note != null && event.note!.isNotEmpty) Text(event.note!),
                Text(
                  '${event.byName ?? 'System'} · ${formatDateTime(event.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
