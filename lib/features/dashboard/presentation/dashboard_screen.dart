import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/status_colors.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_controller.dart';
import '../../repair_jobs/domain/repair_job.dart';
import '../domain/dashboard_controller.dart';
import '../domain/dashboard_data.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (user?.isAdmin == true || user?.can('view_tech_panel') == true)
            IconButton(
              icon: const Icon(Icons.support_agent),
              tooltip: 'Tech Panel',
              onPressed: () => context.push('/tech-panel'),
            ),
          if (user?.isAdmin == true || user?.can('view_pos') == true)
            IconButton(
              icon: const Icon(Icons.point_of_sale),
              tooltip: 'POS',
              onPressed: () => context.push('/pos'),
            ),
          if (user?.isAdmin == true || user?.can('view_crm') == true)
            IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: 'Customers',
              onPressed: () => context.push('/crm'),
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: (user?.isAdmin == true || user?.can('view_tech_panel') == true)
          ? FloatingActionButton(
              tooltip: 'Staff Chat',
              onPressed: () => context.push('/tech-panel', extra: 1),
              child: const Icon(Icons.chat_bubble_outline),
            )
          : null,
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load dashboard: $err')),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Text('Welcome, ${user?.name ?? ''}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _RepairActionsRow(),
              const SizedBox(height: 16),
              _StatGrid(data: data),
              const SizedBox(height: 24),
              _QuickLinksRow(user: user),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Recent Repair Jobs',
                onViewAll: () => context.push('/repair-jobs'),
              ),
              const SizedBox(height: 8),
              if (data.periodJobs.isEmpty)
                const Padding(padding: EdgeInsets.all(8), child: Text('No recent repair jobs.'))
              else
                ...data.periodJobs.take(5).map((j) => _JobTile(job: j)),
              if (data.recentOrders.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Recent Orders'),
                const SizedBox(height: 8),
                ...data.recentOrders.take(5).map((o) => _OrderTile(order: o)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RepairActionsRow extends StatelessWidget {
  const _RepairActionsRow();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Row(
      children: [
        Expanded(
          child: _RepairActionCard(
            icon: Icons.build_circle,
            label: 'All Repair Jobs',
            sublabel: 'View & manage',
            iconColor: onPrimary,
            backgroundColor: primary,
            labelColor: onPrimary,
            onTap: () => context.push('/repair-jobs'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RepairActionCard(
            icon: Icons.add_circle_outline,
            label: 'New Repair Job',
            sublabel: 'Intake a device',
            iconColor: primary,
            backgroundColor: surface,
            labelColor: Theme.of(context).colorScheme.onSurface,
            onTap: () => context.push('/repair-jobs/new'),
          ),
        ),
      ],
    );
  }
}

class _RepairActionCard extends StatelessWidget {
  const _RepairActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.iconColor,
    required this.backgroundColor,
    required this.labelColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color iconColor;
  final Color backgroundColor;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14, color: labelColor)),
                    const SizedBox(height: 2),
                    Text(sublabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: labelColor.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLinksRow extends StatelessWidget {
  const _QuickLinksRow({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final isAdmin = user?.isAdmin == true;
    final links = <_QuickLink>[
      _QuickLink('Repair Jobs', Icons.build_outlined, '/repair-jobs'),
      if (isAdmin || user?.can('view_pos') == true) ...[
        _QuickLink('POS Terminal', Icons.point_of_sale, '/pos'),
        _QuickLink('POS Sales', Icons.receipt_outlined, '/pos/sales'),
      ],
      if (isAdmin || user?.can('view_products') == true)
        _QuickLink('Products', Icons.inventory_2_outlined, '/products'),
      if (isAdmin || user?.can('view_orders') == true)
        _QuickLink('GSM Orders', Icons.sim_card_outlined, '/orders'),
      if (isAdmin || user?.can('view_dues') == true)
        _QuickLink('Dues', Icons.account_balance_wallet_outlined, '/dues'),
      if (isAdmin || user?.can('view_products') == true)
        _QuickLink('Purchases', Icons.local_shipping_outlined, '/purchases'),
      if (isAdmin) _QuickLink('Accounts', Icons.account_balance_outlined, '/accounts'),
      if (isAdmin) _QuickLink('Expenses', Icons.receipt_long_outlined, '/expenses'),
      _QuickLink('Support', Icons.support_agent_outlined, '/support'),
      _QuickLink('Waitlist', Icons.queue_outlined, '/service-waitlist'),
      if (isAdmin) _QuickLink('Online Orders', Icons.shopping_cart_outlined, '/online-orders'),
      if (isAdmin) _QuickLink('Staff', Icons.badge_outlined, '/staff'),
      if (isAdmin) _QuickLink('Settings', Icons.settings_outlined, '/settings'),
    ];

    if (links.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: links.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final link = links[index];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(link.route),
            child: Container(
              width: 84,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(link.icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 6),
                  Text(link.label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center, maxLines: 2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickLink {
  const _QuickLink(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Spacer(),
        if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final cards = <_StatCardData>[
      if (data.stats.containsKey('total_revenue'))
        _StatCardData('Total Revenue', formatMoney(data.stat('total_revenue')), Icons.payments, Colors.green),
      if (data.stats.containsKey('today_revenue'))
        _StatCardData('Today Revenue', formatMoney(data.stat('today_revenue')), Icons.today, Colors.blue),
      if (data.stats.containsKey('pending_orders'))
        _StatCardData('Pending Orders', data.stat('pending_orders').toInt().toString(), Icons.pending_actions,
            Colors.orange),
      if (data.stats.containsKey('repair_total'))
        _StatCardData('Repair Jobs', data.stat('repair_total').toInt().toString(), Icons.build, Colors.purple),
      if (data.stats.containsKey('repair_ready_delivered'))
        _StatCardData('Ready/Delivered', data.stat('repair_ready_delivered').toInt().toString(),
            Icons.check_circle, Colors.teal),
      if (data.stats.containsKey('dues_total'))
        _StatCardData('Dues Outstanding', formatMoney(data.stat('dues_total')), Icons.account_balance_wallet,
            Colors.red),
      if (data.stats.containsKey('balance'))
        _StatCardData('My Balance', formatMoney(data.stat('balance')), Icons.account_balance_wallet, Colors.blue),
      if (data.stats.containsKey('total_orders'))
        _StatCardData('My Orders', data.stat('total_orders').toInt().toString(), Icons.shopping_bag, Colors.indigo),
    ];

    if (cards.isEmpty) {
      return const Text('No stats available for your role.');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) => _StatCard(data: cards[i]),
    );
  }
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(data.icon, color: data.color, size: 22),
            const SizedBox(height: 6),
            Text(
              data.value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
            Text(data.label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});

  final RepairJobSummary job;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/repair-jobs/${job.id}'),
        title: Text('${job.jobNumber} · ${job.deviceModel ?? '-'}'),
        subtitle: Text(job.customerName ?? 'Unknown'),
        trailing: StatusChip.status(job.status, repairStatusColor(job.status)),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(order.orderNumber),
        subtitle: Text('${order.serviceName} · ${order.customerName}'),
        trailing: Text(formatMoney(order.totalPrice)),
      ),
    );
  }
}
