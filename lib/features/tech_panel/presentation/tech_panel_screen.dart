import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../auth/domain/auth_controller.dart';
import '../domain/tech_chat_message.dart';
import '../domain/tech_notification.dart';
import '../domain/tech_panel_controller.dart';

class TechPanelScreen extends ConsumerStatefulWidget {
  const TechPanelScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<TechPanelScreen> createState() => _TechPanelScreenState();
}

class _TechPanelScreenState extends ConsumerState<TechPanelScreen>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(techPanelProvider);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(techPanelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tech Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_outlined), text: 'Alerts'),
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) {
              if (_tabController.index != 0) return const SizedBox.shrink();
              return dataAsync.maybeWhen(
                data: (d) => d.unreadCount > 0
                    ? TextButton(
                        onPressed: () async {
                          await ref.read(techPanelRepositoryProvider).markAllRead();
                          ref.invalidate(techPanelProvider);
                        },
                        child: const Text('Mark all read'),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(techPanelProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NotificationsTab(tabController: _tabController),
          const _ChatTab(),
        ],
      ),
    );
  }
}

// ── Notifications tab ──────────────────────────────────────────────────────────

class _NotificationsTab extends ConsumerWidget {
  const _NotificationsTab({required this.tabController});
  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(techPanelProvider);

    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Failed to load: $err')),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(techPanelProvider),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const _QuickActions(),
            const SizedBox(height: 16),
            if (data.notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No notifications.')),
              )
            else
              ...data.notifications.map(
                (n) => _NotificationCard(notification: n, tabController: tabController),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA(icon: Icons.add_circle_outline, label: 'Add Repair', color: Colors.indigo, route: '/repair-jobs/new'),
      _QA(icon: Icons.build_circle_outlined, label: 'Repair List', color: Colors.teal, route: '/repair-jobs'),
      _QA(icon: Icons.people_outline, label: 'CRM', color: Colors.purple, route: '/crm'),
      _QA(icon: Icons.account_balance_wallet_outlined, label: 'Dues', color: Colors.orange, route: '/dues'),
      _QA(icon: Icons.list_alt_outlined, label: 'Waitlist', color: Colors.cyan, route: '/service-waitlist'),
      _QA(icon: Icons.hardware_outlined, label: 'Add Parts', color: Colors.green, route: '/repair-jobs'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: actions.map((a) => _QuickActionTile(qa: a)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _QA {
  const _QA({required this.icon, required this.label, required this.color, required this.route});
  final IconData icon;
  final String label;
  final Color color;
  final String route;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.qa});
  final _QA qa;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(qa.route),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: qa.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: qa.color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(qa.icon, color: qa.color, size: 26),
            const SizedBox(height: 5),
            Text(
              qa.label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: qa.color),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification, required this.tabController});

  final TechNotification notification;
  final TabController tabController;

  bool get _isChat => notification.type == 'chat';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUrgent = notification.type == 'urgent';
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: !notification.isRead
          ? (isUrgent
              ? Colors.red.withValues(alpha: 0.08)
              : cs.primary.withValues(alpha: 0.06))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () async {
              if (!notification.isRead) {
                await ref.read(techPanelRepositoryProvider).markRead(notification.id);
                ref.invalidate(techPanelProvider);
              }
              if (!context.mounted) return;
              if (_isChat) {
                // Chat notifications → go to Chat tab to reply
                tabController.animateTo(1);
              } else if (notification.jobId != null) {
                context.push('/repair-jobs/${notification.jobId}');
              }
            },
            leading: Icon(
              isUrgent ? Icons.priority_high : (_isChat ? Icons.chat_bubble_outline : Icons.notifications_outlined),
              color: isUrgent ? Colors.red : (_isChat ? cs.primary : null),
            ),
            title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.message),
                const SizedBox(height: 4),
                Text(
                  '${notification.sentByName ?? 'Admin'} · ${formatDateTime(notification.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Reply shortcut for chat notifications ──────────────
                if (_isChat)
                  IconButton(
                    icon: Icon(Icons.reply, size: 18, color: cs.primary),
                    tooltip: 'Reply in Chat',
                    onPressed: () => tabController.animateTo(1),
                  ),
                // ── Dismiss (X) ────────────────────────────────────────
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Dismiss',
                  onPressed: () async {
                    await ref.read(techPanelRepositoryProvider).markRead(notification.id);
                    ref.invalidate(techPanelProvider);
                  },
                ),
                // ── More menu ──────────────────────────────────────────
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'read') {
                      await ref.read(techPanelRepositoryProvider).markRead(notification.id);
                    } else if (value == 'snooze') {
                      await ref.read(techPanelRepositoryProvider).snooze(notification.id, 30);
                    }
                    ref.invalidate(techPanelProvider);
                  },
                  itemBuilder: (context) => [
                    if (!notification.isRead) const PopupMenuItem(value: 'read', child: Text('Mark Read')),
                    const PopupMenuItem(value: 'snooze', child: Text('Snooze 30m')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat tab — staff list → DM thread ─────────────────────────────────────────

class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab();

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  List<Map<String, dynamic>> _technicians = [];
  bool _loading = true;
  String? _error;

  // When non-null, we're inside a DM thread with this technician.
  Map<String, dynamic>? _selectedTech;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ref.read(techPanelRepositoryProvider).fetchTechnicians();
      if (mounted) setState(() { _technicians = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── DM thread with a selected technician ──────────────────────────
    if (_selectedTech != null) {
      return _DmThread(
        techId: _selectedTech!['id'] as int,
        techName: _selectedTech!['name'] as String? ?? 'Staff',
        onBack: () => setState(() => _selectedTech = null),
      );
    }

    // ── Staff / technician list ───────────────────────────────────────
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load staff: $_error'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadTechnicians, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_technicians.isEmpty) {
      return const Center(child: Text('No active staff / technicians.'));
    }

    return RefreshIndicator(
      onRefresh: _loadTechnicians,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _technicians.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final tech = _technicians[index];
          final name = tech['name'] as String? ?? 'Unknown';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Tap to open chat'),
            trailing: const Icon(Icons.chat_bubble_outline, size: 18),
            onTap: () => setState(() => _selectedTech = tech),
          );
        },
      ),
    );
  }
}

// ── DM thread with a specific technician ──────────────────────────────────────

class _DmThread extends ConsumerStatefulWidget {
  const _DmThread({required this.techId, required this.techName, required this.onBack});
  final int techId;
  final String techName;
  final VoidCallback onBack;

  @override
  ConsumerState<_DmThread> createState() => _DmThreadState();
}

class _DmThreadState extends ConsumerState<_DmThread> {
  final List<TechChatMessage> _messages = [];
  int _lastId = 0;
  Timer? _pollTimer;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ref
          .read(techPanelRepositoryProvider)
          .fetchGeneralMessages(lastId: 0, technicianId: widget.techId);
      if (mounted) {
        setState(() {
          _messages..clear()..addAll(msgs);
          if (msgs.isNotEmpty) _lastId = msgs.last.id;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _poll() async {
    if (!mounted) return;
    try {
      final msgs = await ref
          .read(techPanelRepositoryProvider)
          .fetchGeneralMessages(lastId: _lastId, technicianId: widget.techId);
      if (mounted && msgs.isNotEmpty) {
        setState(() {
          _messages.addAll(msgs);
          _lastId = msgs.last.id;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await ref
          .read(techPanelRepositoryProvider)
          .sendGeneralMessage(text, technicianId: widget.techId);
      _msgCtrl.clear();
      if (mounted) {
        setState(() {
          _messages.add(msg);
          if (msg.id > _lastId) _lastId = msg.id;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authControllerProvider).user?.id;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ── Thread header (back + name) ─────────────────────────────
        Material(
          color: cs.surfaceContainerHighest,
          child: ListTile(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
            title: Text(widget.techName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: const Text('Staff Chat'),
          ),
        ),
        const Divider(height: 1),

        // ── Messages ────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Failed: $_error'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () { setState(() { _loading = true; _error = null; }); _loadMessages(); },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet.\nSend one to start the conversation.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return _ChatBubble(msg: msg, isMe: msg.senderId == currentUserId);
                          },
                        ),
        ),

        // ── Compose bar ─────────────────────────────────────────────
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: 'Message ${widget.techName}…',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.msg, required this.isMe});

  final TechChatMessage msg;
  final bool isMe;

  static final _timeFormat = DateFormat('h:mm a');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      msg.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (isMe ? scheme.onPrimary : scheme.onSurface).withValues(alpha: 0.6),
                      ),
                    ),
                  if (msg.isUrgent)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.priority_high, size: 13,
                            color: isMe ? scheme.onPrimary : Colors.red),
                        Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isMe ? scheme.onPrimary.withValues(alpha: 0.85) : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    msg.message,
                    style: TextStyle(color: isMe ? scheme.onPrimary : scheme.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _timeFormat.format(msg.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: 10,
                      color: (isMe ? scheme.onPrimary : scheme.onSurface).withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
