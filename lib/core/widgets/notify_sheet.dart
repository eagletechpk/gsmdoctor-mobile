import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/notifications/data/notify_repository.dart';
import '../../features/notifications/domain/notify_controller.dart';

/// Shows the customer-notification bottom sheet.
/// [event] is the message_templates event key (e.g. 'job_ready', 'due_reminder').
/// At least [phone] must be non-empty. [email] is optional.
void showNotifySheet(
  BuildContext context, {
  required String phone,
  String email = '',
  required String name,
  required String event,
  int? jobId,
  int? dueId,
  int? crmId,
  String? reference,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotifySheet(
      phone: phone,
      email: email,
      name: name,
      event: event,
      jobId: jobId,
      dueId: dueId,
      crmId: crmId,
      reference: reference,
    ),
  );
}

class _NotifySheet extends ConsumerStatefulWidget {
  const _NotifySheet({
    required this.phone,
    required this.email,
    required this.name,
    required this.event,
    this.jobId,
    this.dueId,
    this.crmId,
    this.reference,
  });

  final String phone;
  final String email;
  final String name;
  final String event;
  final int? jobId;
  final int? dueId;
  final int? crmId;
  final String? reference;

  @override
  ConsumerState<_NotifySheet> createState() => _NotifySheetState();
}

class _NotifySheetState extends ConsumerState<_NotifySheet> {
  final _msgCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  String _selectedChannel = 'whatsapp';
  MessageTemplate? _selectedTemplate;
  bool _sending = false;

  NotifyTemplatesArgs get _args => (
        event: widget.event,
        jobId: widget.jobId,
        dueId: widget.dueId,
        crmId: widget.crmId,
      );

  @override
  void dispose() {
    _msgCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(MessageTemplate tpl) {
    setState(() {
      _selectedTemplate = tpl;
      _msgCtrl.text = tpl.body;
      if (tpl.subject != null && tpl.subject!.isNotEmpty) {
        _subjectCtrl.text = tpl.subject!;
      }
    });
  }

  void _switchChannel(String channel, List<MessageTemplate> templates) {
    setState(() => _selectedChannel = channel);
    final byType = templates.where((t) => t.type == channel).toList();
    if (byType.isNotEmpty) {
      _applyTemplate(byType.first);
    }
  }

  String _cleanPhone(String phone) => phone.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _send(String channel, NotifyTemplatesData data) async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Message cannot be empty.')));
      return;
    }

    String? urlStr;
    final cleanPhone = _cleanPhone(widget.phone);

    switch (channel) {
      case 'whatsapp':
        urlStr = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}';
      case 'telegram':
        urlStr = 'https://t.me/+$cleanPhone';
      case 'sms':
        urlStr = 'sms:$cleanPhone?body=${Uri.encodeComponent(msg)}';
      case 'email':
        if (widget.email.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No email address for this customer.')));
          return;
        }
        final subject = _subjectCtrl.text.trim().isEmpty
            ? 'Message from our shop'
            : _subjectCtrl.text.trim();
        urlStr =
            'mailto:${widget.email}?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(msg)}';
    }

    if (urlStr == null) return;

    setState(() => _sending = true);
    try {
      final uri = Uri.parse(urlStr);
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Log fire-and-forget
      unawaited(ref.read(notifyRepoProvider).logNotification(
            type: channel,
            message: msg,
            toPhone: widget.phone,
            toName: widget.name,
            reference: widget.reference,
            jobId: widget.jobId,
            subject: channel == 'email' ? _subjectCtrl.text.trim() : null,
          ));

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final templatesAsync = ref.watch(notifyTemplatesProvider(_args));

    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 40,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notify Customer',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(widget.name,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          templatesAsync.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator())),
            error: (e, _) => Text('Failed to load templates: $e',
                style: const TextStyle(color: Colors.red)),
            data: (data) {
              // Auto-fill on first load
              if (_msgCtrl.text.isEmpty) {
                final wa = data.byType('whatsapp');
                if (wa.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _applyTemplate(wa.first);
                  });
                }
              }
              return _buildBody(context, data);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotifyTemplatesData data) {
    final cs = Theme.of(context).colorScheme;

    // Channel buttons definition
    final channels = [
      _Channel(
          id: 'whatsapp',
          label: 'WhatsApp',
          icon: Icons.chat,
          color: const Color(0xFF25D366)),
      _Channel(
          id: 'telegram',
          label: 'Telegram',
          icon: Icons.send,
          color: const Color(0xFF0088CC)),
      _Channel(
          id: 'sms',
          label: 'SMS',
          icon: Icons.sms,
          color: const Color(0xFF607D8B)),
      _Channel(
          id: 'email',
          label: 'Email',
          icon: Icons.email_outlined,
          color: cs.primary,
          disabled: widget.email.isEmpty),
    ];

    // Template picker for current channel
    final channelTemplates = data.byType(_selectedChannel);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Channel selector
        Row(
          children: channels.map((ch) {
            final isSelected = _selectedChannel == ch.id;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: ch.disabled
                      ? null
                      : () => _switchChannel(ch.id, data.templates),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ch.color.withValues(alpha: ch.disabled ? 0.08 : 0.15)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? ch.color : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Icon(ch.icon,
                            size: 20,
                            color: ch.disabled
                                ? Colors.grey
                                : isSelected
                                    ? ch.color
                                    : cs.onSurfaceVariant),
                        const SizedBox(height: 3),
                        Text(ch.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: ch.disabled
                                  ? Colors.grey
                                  : isSelected
                                      ? ch.color
                                      : cs.onSurfaceVariant,
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

        // Template picker (if multiple templates for this channel)
        if (channelTemplates.length > 1) ...[
          DropdownButtonFormField<int>(
            value: _selectedTemplate?.id,
            decoration: const InputDecoration(
              labelText: 'Template',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            items: channelTemplates
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (id) {
              final tpl = channelTemplates.firstWhere((t) => t.id == id);
              _applyTemplate(tpl);
            },
          ),
          const SizedBox(height: 10),
        ],

        // Email subject (visible only for email channel)
        if (_selectedChannel == 'email') ...[
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
          maxLines: 5,
          minLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),

        // Send button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _sending
                ? null
                : () => _send(_selectedChannel, data),
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_channelIcon(_selectedChannel)),
            label: Text(_sending
                ? 'Opening...'
                : 'Send via ${_channelLabel(_selectedChannel)}'),
            style: FilledButton.styleFrom(
              backgroundColor: _channelColor(_selectedChannel),
            ),
          ),
        ),
      ],
    );
  }

  IconData _channelIcon(String ch) => switch (ch) {
        'whatsapp' => Icons.chat,
        'telegram' => Icons.send,
        'sms' => Icons.sms,
        _ => Icons.email_outlined,
      };

  String _channelLabel(String ch) => switch (ch) {
        'whatsapp' => 'WhatsApp',
        'telegram' => 'Telegram',
        'sms' => 'SMS',
        _ => 'Email',
      };

  Color _channelColor(String ch) => switch (ch) {
        'whatsapp' => const Color(0xFF25D366),
        'telegram' => const Color(0xFF0088CC),
        'sms' => const Color(0xFF607D8B),
        _ => Theme.of(context).colorScheme.primary,
      };
}

class _Channel {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool disabled;

  const _Channel({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.disabled = false,
  });
}
