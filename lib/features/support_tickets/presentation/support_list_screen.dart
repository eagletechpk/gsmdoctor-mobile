import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/support_controller.dart';
import '../domain/support_ticket.dart';

class SupportListScreen extends ConsumerStatefulWidget {
  const SupportListScreen({super.key});

  @override
  ConsumerState<SupportListScreen> createState() => _SupportListScreenState();
}

class _SupportListScreenState extends ConsumerState<SupportListScreen> {
  String _status = '';
  int _page = 1;

  ({int page, String status}) get _params => (page: _page, status: _status);

  static const _statuses = ['', 'open', 'in_progress', 'resolved', 'closed'];
  static const _statusLabels = ['All', 'Open', 'In Progress', 'Resolved', 'Closed'];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(supportListProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(supportListProvider(_params)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: List.generate(_statuses.length, (i) {
                final s = _statuses[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(_statusLabels[i], style: const TextStyle(fontSize: 12)),
                    selected: _status == s,
                    onSelected: (_) => setState(() { _status = s; _page = 1; }),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (result) => result.tickets.isEmpty
            ? const Center(child: Text('No tickets found.'))
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => ref.invalidate(supportListProvider(_params)),
                      child: ListView.separated(
                        itemCount: result.tickets.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _TicketTile(ticket: result.tickets[i]),
                      ),
                    ),
                  ),
                  if (result.lastPage > 1)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _page > 1 ? () => setState(() => _page--) : null,
                          ),
                          Text('$_page / ${result.lastPage}'),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _page < result.lastPage ? () => setState(() => _page++) : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
        onPressed: () => _showCreateDialog(context),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String priority = 'medium';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Support Ticket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: messageCtrl,
                  decoration: const InputDecoration(labelText: 'Message *'),
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                const Text('Priority', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'low', label: Text('Low')),
                    ButtonSegment(value: 'medium', label: Text('Medium')),
                    ButtonSegment(value: 'high', label: Text('High')),
                  ],
                  selected: {priority},
                  onSelectionChanged: (s) => setState(() => priority = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final subject = subjectCtrl.text.trim();
                final message = messageCtrl.text.trim();
                if (subject.isEmpty || message.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(supportRepoProvider).store(
                        subject: subject,
                        message: message,
                        priority: priority,
                      );
                  ref.invalidate(supportListProvider(_params));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ticket submitted.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});
  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/support/${ticket.id}'),
      leading: _StatusIcon(status: ticket.status),
      title: Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(
        '${ticket.ticketNumber} · ${ticket.userName ?? ''} · ${ticket.priority.toUpperCase()}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StatusChip(status: ticket.status),
          const SizedBox(height: 4),
          Text(_formatDate(ticket.createdAt), style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (status) {
      case 'open':
        icon = Icons.fiber_new;
        color = Colors.blue;
        break;
      case 'in_progress':
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case 'resolved':
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case 'closed':
        icon = Icons.cancel_outlined;
        color = Colors.grey;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      radius: 20,
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'open':
        color = Colors.blue;
        break;
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      case 'closed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
