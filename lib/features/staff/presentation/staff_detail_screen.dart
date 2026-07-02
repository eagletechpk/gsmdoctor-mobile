import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/staff_controller.dart';
import '../domain/staff_member.dart';

class StaffDetailScreen extends ConsumerStatefulWidget {
  const StaffDetailScreen({super.key, required this.staffId, this.isNew = false});
  final int staffId;
  final bool isNew;

  @override
  ConsumerState<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends ConsumerState<StaffDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: widget.isNew ? 1 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isNew) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Staff Member')),
        body: _EditForm(
          staffId: null,
          member: null,
          onSaved: () => context.pop(true),
        ),
      );
    }

    final detailAsync = ref.watch(staffDetailProvider(widget.staffId));

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.maybeWhen(
          data: (d) => Text(d.member.name),
          orElse: () => const Text('Staff Member'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(staffDetailProvider(widget.staffId)),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Permissions'),
          ],
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) => TabBarView(
          controller: _tabs,
          children: [
            _EditForm(
              staffId: widget.staffId,
              member: detail.member,
              onSaved: () {
                ref.invalidate(staffDetailProvider(widget.staffId));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Saved.')));
              },
            ),
            _PermissionsTab(
              staffId: widget.staffId,
              effectivePerms: detail.permissions,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.staffId, required this.member, required this.onSaved});
  final int? staffId;
  final StaffMember? member;
  final VoidCallback onSaved;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late String _role;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.member?.name ?? '');
    _email = TextEditingController(text: widget.member?.email ?? '');
    _phone = TextEditingController(text: widget.member?.phone ?? '');
    _password = TextEditingController();
    _role = widget.member?.role ?? 'staff';
    _status = widget.member?.status ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(staffRepoProvider);
      if (widget.staffId == null) {
        await repo.create(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          role: _role,
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        );
      } else {
        await repo.update(
          widget.staffId!,
          name: _name.text.trim(),
          email: _email.text.trim(),
          role: _role,
          status: _status,
          phone: _phone.text.trim(),
          password: _password.text.isEmpty ? null : _password.text,
        );
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Valid email required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            decoration: InputDecoration(
              labelText: widget.staffId == null
                  ? 'Password'
                  : 'New Password (leave blank to keep)',
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (v) {
              if (widget.staffId == null && (v == null || v.length < 6)) {
                return 'Minimum 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'staff', child: Text('Staff')),
              DropdownMenuItem(value: 'technician', child: Text('Technician')),
            ],
            onChanged: (v) => setState(() => _role = v!),
          ),
          if (widget.staffId != null) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.staffId == null ? 'Create Staff Member' : 'Save Changes'),
          ),
          if (widget.staffId != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _confirmDelete(context),
              child: const Text('Delete / Deactivate'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Staff Member?'),
        content: const Text(
            'If they have historical records, they will be deactivated instead of deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(staffRepoProvider).delete(widget.staffId!);
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}

class _PermissionsTab extends ConsumerStatefulWidget {
  const _PermissionsTab({required this.staffId, required this.effectivePerms});
  final int staffId;
  final Map<String, bool> effectivePerms;

  @override
  ConsumerState<_PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends ConsumerState<_PermissionsTab> {
  late Map<String, bool> _perms;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _perms = Map.from(widget.effectivePerms);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(staffRepoProvider).updatePermissions(widget.staffId, _perms);
      ref.invalidate(staffDetailProvider(widget.staffId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Permissions saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGroups = ref.watch(staffListProvider).maybeWhen(
          data: (d) => d.permissionGroups,
          orElse: () => <PermissionGroup>[],
        );

    return Column(
      children: [
        Expanded(
          child: allGroups.isEmpty
              ? const Center(child: Text('Load the staff list first to see permissions.'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final group in allGroups) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          group.group[0].toUpperCase() + group.group.substring(1),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 13),
                        ),
                      ),
                      for (final p in group.perms)
                        CheckboxListTile(
                          title: Text(p.label, style: const TextStyle(fontSize: 14)),
                          value: _perms[p.key] ?? false,
                          onChanged: (v) => setState(() => _perms[p.key] = v!),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                    ],
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Permissions'),
            ),
          ),
        ),
      ],
    );
  }
}
