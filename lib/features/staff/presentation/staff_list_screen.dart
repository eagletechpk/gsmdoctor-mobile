import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/staff_controller.dart';
import '../domain/staff_member.dart';

class StaffListScreen extends ConsumerWidget {
  const StaffListScreen({super.key});

  Color _roleColor(String role, BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return switch (role) {
      'admin' => cs.error,
      'technician' => cs.tertiary,
      _ => cs.secondary,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(staffListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
        onPressed: () async {
          final result = await context.push<bool>('/staff/new');
          if (result == true) ref.invalidate(staffListProvider);
        },
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final byRole = <String, List<StaffMember>>{};
          for (final m in data.staff) {
            byRole.putIfAbsent(m.role, () => []).add(m);
          }
          final roleOrder = ['admin', 'staff', 'technician'];

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            children: [
              for (final role in roleOrder)
                if (byRole.containsKey(role)) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      role[0].toUpperCase() + role.substring(1) + 's',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _roleColor(role, context),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  for (final m in byRole[role]!)
                    _StaffTile(member: m, onTap: () async {
                      final result = await context.push<bool>('/staff/${m.id}');
                      if (result == true) ref.invalidate(staffListProvider);
                    }),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.member, required this.onTap});
  final StaffMember member;
  final VoidCallback onTap;

  Color _statusColor(String s) => switch (s) {
        'active' => Colors.green,
        'inactive' => Colors.grey,
        _ => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(member.name[0].toUpperCase()),
        ),
        title: Text(member.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.email, style: const TextStyle(fontSize: 12)),
            if (member.speciality != null && member.speciality!.isNotEmpty)
              Text(member.speciality!, style: const TextStyle(fontSize: 11)),
          ],
        ),
        isThreeLine: member.speciality != null && member.speciality!.isNotEmpty,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(member.status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor(member.status), width: 0.8),
              ),
              child: Text(member.statusLabel,
                  style: TextStyle(fontSize: 11, color: _statusColor(member.status))),
            ),
            const SizedBox(height: 4),
            Text('${member.jobsCount} jobs', style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
