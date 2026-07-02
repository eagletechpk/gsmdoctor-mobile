import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../domain/support_controller.dart';
import '../domain/support_ticket.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});
  final int ticketId;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _replyCtrl = TextEditingController();
  String _newStatus = '';

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ticketDetailProvider(widget.ticketId));
    final isAdmin = ref.watch(authControllerProvider).user?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Ticket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(ticketDetailProvider(widget.ticketId)),
          ),
          if (isAdmin)
            PopupMenuButton<String>(
              tooltip: 'Change status',
              icon: const Icon(Icons.more_vert),
              onSelected: (s) => _updateStatus(s),
              itemBuilder: (_) => [
                for (final s in ['open', 'in_progress', 'resolved', 'closed'])
                  PopupMenuItem(value: s, child: Text(s.replaceAll('_', ' ').toUpperCase())),
              ],
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (detail) => Column(
          children: [
            _TicketHeader(ticket: detail.ticket),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: detail.replies.length,
                itemBuilder: (_, i) => _ReplyBubble(reply: detail.replies[i]),
              ),
            ),
            if (detail.ticket.status != 'closed') _ReplyBar(
              isAdmin: isAdmin,
              statusValue: _newStatus,
              onStatusChanged: (s) => setState(() => _newStatus = s),
              onSend: () => _sendReply(detail.ticket.status),
              ctrl: _replyCtrl,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReply(String currentStatus) async {
    final msg = _replyCtrl.text.trim();
    if (msg.isEmpty) return;
    try {
      await ref.read(supportRepoProvider).reply(
            widget.ticketId,
            msg,
            status: _newStatus.isNotEmpty ? _newStatus : null,
          );
      _replyCtrl.clear();
      setState(() => _newStatus = '');
      ref.invalidate(ticketDetailProvider(widget.ticketId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await ref.read(supportRepoProvider).updateStatus(widget.ticketId, status);
      ref.invalidate(ticketDetailProvider(widget.ticketId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _TicketHeader extends StatelessWidget {
  const _TicketHeader({required this.ticket});
  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ticket.ticketNumber,
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
              const Spacer(),
              _badge(ticket.priority, _priorityColor(ticket.priority)),
              const SizedBox(width: 6),
              _badge(ticket.status.replaceAll('_', ' '), _statusColor(ticket.status)),
            ],
          ),
          const SizedBox(height: 6),
          Text(ticket.subject,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(ticket.message,
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('By ${ticket.userName ?? 'Unknown'}',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label.toUpperCase(),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
      );

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return Colors.red;
      case 'low': return Colors.green;
      default: return Colors.orange;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'open': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }
}

class _ReplyBubble extends StatelessWidget {
  const _ReplyBubble({required this.reply});
  final TicketReply reply;

  @override
  Widget build(BuildContext context) {
    // Admin replies on left, user replies on right — conventional support chat layout.
    final isAdmin = reply.isAdmin;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            CircleAvatar(radius: 14, backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.support_agent, size: 14, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isAdmin
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reply.userName != null)
                    Text(reply.userName!,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 2),
                  Text(reply.message, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(_formatTime(reply.createdAt),
                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline)),
                ],
              ),
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(width: 8),
            CircleAvatar(radius: 14, backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.secondary)),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.isAdmin,
    required this.statusValue,
    required this.onStatusChanged,
    required this.onSend,
    required this.ctrl,
  });

  final bool isAdmin;
  final String statusValue;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onSend;
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DropdownButtonFormField<String>(
                value: statusValue.isEmpty ? null : statusValue,
                decoration: const InputDecoration(
                  labelText: 'Set status with reply',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('No change')),
                  for (final s in ['open', 'in_progress', 'resolved', 'closed'])
                    DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ').toUpperCase())),
                ],
                onChanged: (v) => onStatusChanged(v ?? ''),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    hintText: 'Write a reply…',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onSend,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

