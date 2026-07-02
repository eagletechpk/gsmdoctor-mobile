import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../domain/waitlist_controller.dart';
import '../domain/waitlist_entry.dart';

class ServiceWaitlistScreen extends ConsumerStatefulWidget {
  const ServiceWaitlistScreen({super.key});

  @override
  ConsumerState<ServiceWaitlistScreen> createState() => _ServiceWaitlistScreenState();
}

class _ServiceWaitlistScreenState extends ConsumerState<ServiceWaitlistScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _status = '';
  int _page = 1;

  ({int page, String search, String status}) get _params =>
      (page: _page, search: _search, status: _status);

  static const _statuses = ['', 'pending', 'contacted', 'fulfilled'];
  static const _statusLabels = ['All', 'Pending', 'Contacted', 'Fulfilled'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(waitlistProvider(_params));
    final isAdmin = ref.watch(authControllerProvider).user?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Waitlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(waitlistProvider(_params)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, phone or service…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() { _search = ''; _page = 1; });
                        })
                    : null,
              ),
              onSubmitted: (v) => setState(() { _search = v.trim(); _page = 1; }),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(_statuses.length, (i) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_statusLabels[i], style: const TextStyle(fontSize: 12)),
                      selected: _status == _statuses[i],
                      onSelected: (_) => setState(() { _status = _statuses[i]; _page = 1; }),
                    ),
                  )),
            ),
          ),
          const SizedBox(height: 4),
          async.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (p) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Row(
                children: [
                  _CountBadge('Pending', p.counts['pending'] ?? 0, Colors.orange),
                  const SizedBox(width: 8),
                  _CountBadge('Contacted', p.counts['contacted'] ?? 0, Colors.blue),
                  const SizedBox(width: 8),
                  _CountBadge('Fulfilled', p.counts['fulfilled'] ?? 0, Colors.green),
                ],
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e')),
              data: (page) => page.entries.isEmpty
                  ? const Center(child: Text('No waitlist entries found.'))
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async => ref.invalidate(waitlistProvider(_params)),
                            child: ListView.separated(
                              itemCount: page.entries.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) => _WaitlistTile(
                                entry: page.entries[i],
                                isAdmin: isAdmin,
                                onStatusChange: (s) => _changeStatus(page.entries[i].id, s),
                                onDelete: isAdmin ? () => _delete(page.entries[i].id) : null,
                              ),
                            ),
                          ),
                        ),
                        if (page.lastPage > 1)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _page > 1 ? () => setState(() => _page--) : null,
                                ),
                                Text('$_page / ${page.lastPage}'),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _page < page.lastPage ? () => setState(() => _page++) : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add to Waitlist'),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  Future<void> _changeStatus(int id, String status) async {
    try {
      await ref.read(waitlistRepoProvider).updateStatus(id, status);
      ref.invalidate(waitlistProvider(_params));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Entry'),
        content: const Text('Remove this waitlist entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(waitlistRepoProvider).delete(id);
      ref.invalidate(waitlistProvider(_params));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final serviceCtrl = TextEditingController();
    final imeiCtrl = TextEditingController();
    final osCtrl = TextEditingController();
    String neededType = 'service';
    bool availableForSale = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add to Waitlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Customer Name *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 4),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'service', label: Text('Service')),
                    ButtonSegment(value: 'custom', label: Text('Custom')),
                  ],
                  selected: {neededType},
                  onSelectionChanged: (s) => setState(() => neededType = s.first),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: serviceCtrl,
                  decoration: InputDecoration(
                    labelText: neededType == 'service' ? 'Needed Service *' : 'Details *',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: imeiCtrl,
                  decoration: const InputDecoration(labelText: 'IMEI / Serial No.'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: osCtrl,
                  decoration: const InputDecoration(labelText: 'OS / Version'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available for sale', style: TextStyle(fontSize: 13)),
                  value: availableForSale,
                  onChanged: (v) => setState(() => availableForSale = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final service = serviceCtrl.text.trim();
                if (name.isEmpty || phone.isEmpty || service.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(waitlistRepoProvider).store(
                        name: name,
                        phone: phone,
                        neededType: neededType,
                        neededService: service,
                        imeiSn: imeiCtrl.text.trim(),
                        osVersion: osCtrl.text.trim(),
                        availableForSale: availableForSale,
                      );
                  ref.invalidate(waitlistProvider(_params));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to waitlist.')),
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('$label: $count', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _WaitlistTile extends StatelessWidget {
  const _WaitlistTile({
    required this.entry,
    required this.isAdmin,
    required this.onStatusChange,
    this.onDelete,
  });

  final WaitlistEntry entry;
  final bool isAdmin;
  final ValueChanged<String> onStatusChange;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (entry.status) {
      'pending' => Colors.orange,
      'contacted' => Colors.blue,
      'fulfilled' => Colors.green,
      _ => Colors.grey,
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.12),
        radius: 20,
        child: Icon(
          entry.neededType == 'product' ? Icons.inventory_2_outlined : Icons.build_outlined,
          color: statusColor,
          size: 18,
        ),
      ),
      title: Text(entry.displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(
        '${entry.customerName ?? ''} · ${entry.customerPhone ?? ''}'
        '${entry.imeiSn != null ? ' · ${entry.imeiSn}' : ''}',
        style: const TextStyle(fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            tooltip: 'Set status',
            initialValue: entry.status,
            onSelected: onStatusChange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                entry.status.toUpperCase(),
                style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
            itemBuilder: (_) => [
              for (final s in ['pending', 'contacted', 'fulfilled'])
                PopupMenuItem(value: s, child: Text(s.toUpperCase())),
            ],
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.red.shade300,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
