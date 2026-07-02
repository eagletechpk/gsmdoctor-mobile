import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/repair_jobs/domain/repair_job.dart';
import '../../features/repair_jobs/domain/repair_jobs_controller.dart';
import '../screens/pdf_preview_screen.dart';
import '../utils/formatters.dart';

/// Shows a "Send Receipt to Customer" bottom sheet immediately after a repair
/// job is created. Mirrors the WhatsApp / Email buttons on the web receipt page,
/// plus a Print/Share PDF button. The sheet is awaitable so the caller can
/// navigate to the job detail screen once it's dismissed.
Future<void> showReceiptSendSheet(
  BuildContext context, {
  required RepairJobSummary job,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReceiptSendSheet(job: job),
  );
}

class _ReceiptSendSheet extends ConsumerStatefulWidget {
  const _ReceiptSendSheet({required this.job});
  final RepairJobSummary job;

  @override
  ConsumerState<_ReceiptSendSheet> createState() => _ReceiptSendSheetState();
}

class _ReceiptSendSheetState extends ConsumerState<_ReceiptSendSheet> {
  String _channel = 'whatsapp';
  late TextEditingController _msgCtrl;
  late TextEditingController _subjectCtrl;
  bool _sending = false;
  bool _sharing = false;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl = TextEditingController(text: _buildMessage('whatsapp'));
    _subjectCtrl = TextEditingController(text: _buildSubject());
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  String _buildMessage(String channel) {
    final name = widget.job.customerName ?? 'Customer';
    final jobNum = widget.job.jobNumber;
    final device = widget.job.deviceModel ?? '-';
    final estimate = formatMoney(widget.job.estimateCost);
    final balance = formatMoney(widget.job.balanceDue);
    final advance = formatMoney((widget.job.estimateCost ?? 0) - (widget.job.balanceDue ?? 0));

    if (channel == 'email') {
      return 'Hello $name,\n\nThank you for bringing in your device for repair. Here are your details:\n\n'
          'Job Number: $jobNum\n'
          'Device: $device\n'
          'Estimated Cost: $estimate\n'
          '${(widget.job.estimateCost ?? 0) > (widget.job.balanceDue ?? 0) ? 'Advance Paid: $advance\n' : ''}'
          'Balance Due: $balance\n\n'
          'We will notify you when your device is ready. Please retain this receipt.\n\n'
          'Best regards';
    }
    // WhatsApp / Telegram
    return 'Hello $name, here is your repair receipt.\n\n'
        'Job #: $jobNum\n'
        'Device: $device\n'
        'Estimate: $estimate\n'
        'Balance Due: $balance\n\n'
        'Thank you for choosing us!';
  }

  String _buildSubject() => 'Repair Receipt - ${widget.job.jobNumber}';

  void _switchChannel(String ch) {
    setState(() {
      _channel = ch;
      _msgCtrl.text = _buildMessage(ch);
    });
  }

  String _cleanPhone(String? phone) =>
      (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;
    final phone = _cleanPhone(widget.job.customerPhone);

    String urlStr;
    switch (_channel) {
      case 'whatsapp':
        urlStr = 'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}';
      case 'telegram':
        urlStr = 'https://t.me/+$phone';
      case 'email':
        final subject = Uri.encodeComponent(_subjectCtrl.text.trim());
        urlStr = 'mailto:?subject=$subject&body=${Uri.encodeComponent(msg)}';
      default:
        return;
    }

    setState(() => _sending = true);
    try {
      await launchUrl(Uri.parse(urlStr), mode: LaunchMode.externalApplication);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not open app: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _sharing = true);
    final jobId = widget.job.id;
    final jobNumber = widget.job.jobNumber;
    final repo = ref.read(repairJobRepositoryProvider);
    try {
      final bytes = Uint8List.fromList(await repo.receiptPdf(jobId));
      await Printing.sharePdf(bytes: bytes, filename: 'receipt-$jobNumber.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to share PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _printPdf() async {
    setState(() => _printing = true);
    final jobId = widget.job.id;
    final jobNumber = widget.job.jobNumber;
    final repo = ref.read(repairJobRepositoryProvider);
    // Capture context-dependent objects before the async gap (lint: use_build_context_synchronously).
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Dismiss sheet, then push PDF preview screen so the user has a back button.
    nav.pop();
    try {
      await nav.push<void>(MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          title: 'Receipt — $jobNumber',
          fileName: 'receipt-$jobNumber.pdf',
          loadBytes: () async => Uint8List.fromList(await repo.receiptPdf(jobId)),
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed to load receipt: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final channels = [
      _Ch(id: 'whatsapp', label: 'WhatsApp', icon: Icons.chat, color: const Color(0xFF25D366)),
      _Ch(id: 'telegram', label: 'Telegram', icon: Icons.send, color: const Color(0xFF0088CC)),
      _Ch(id: 'email', label: 'Email', icon: Icons.email_outlined, color: cs.primary),
    ];

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Send Receipt',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(
                        '${widget.job.customerName ?? 'Customer'} · ${widget.job.jobNumber}',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Channel selector
            Row(
              children: channels.map((ch) {
                final isSelected = _channel == ch.id;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => _switchChannel(ch.id),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ch.color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? ch.color : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Icon(ch.icon, size: 20,
                                color: isSelected ? ch.color : cs.onSurfaceVariant),
                            const SizedBox(height: 3),
                            Text(ch.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? ch.color : cs.onSurfaceVariant,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Email subject (email channel only)
            if (_channel == 'email') ...[
              TextField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Message editor
            TextField(
              controller: _msgCtrl,
              maxLines: 7,
              minLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),

            // Send button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_channelIcon(_channel)),
                label: Text(_sending
                    ? 'Opening...'
                    : 'Send via ${_channelLabel(_channel)}'),
                style: FilledButton.styleFrom(
                  backgroundColor: _channelColor(_channel, cs),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Share PDF as attachment (WhatsApp, Email, Telegram, etc.)
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _sharing ? null : _sharePdf,
                icon: _sharing
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.attach_file),
                label: const Text('Attach & Share PDF'),
              ),
            ),
            const SizedBox(height: 8),

            // View / Print PDF
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _printing ? null : _printPdf,
                icon: _printing
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.print_outlined),
                label: const Text('View / Print PDF'),
              ),
            ),
            const SizedBox(height: 4),

            // Skip
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Skip'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _channelIcon(String ch) => switch (ch) {
        'whatsapp' => Icons.chat,
        'telegram' => Icons.send,
        _ => Icons.email_outlined,
      };

  String _channelLabel(String ch) => switch (ch) {
        'whatsapp' => 'WhatsApp',
        'telegram' => 'Telegram',
        _ => 'Email',
      };

  Color _channelColor(String ch, ColorScheme cs) => switch (ch) {
        'whatsapp' => const Color(0xFF25D366),
        'telegram' => const Color(0xFF0088CC),
        _ => cs.primary,
      };
}

class _Ch {
  const _Ch({required this.id, required this.label, required this.icon, required this.color});
  final String id;
  final String label;
  final IconData icon;
  final Color color;
}
