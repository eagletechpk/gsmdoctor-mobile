import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/settings_controller.dart';
import '../domain/settings_data.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(settingsProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Currencies'),
          ],
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (data) => TabBarView(
          controller: _tabs,
          children: [
            _GeneralTab(data: data),
            _CurrenciesTab(currencies: data.currencies),
          ],
        ),
      ),
    );
  }
}

class _GeneralTab extends ConsumerStatefulWidget {
  const _GeneralTab({required this.data});
  final SettingsData data;

  @override
  ConsumerState<_GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends ConsumerState<_GeneralTab> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _ctrl;
  late final Map<String, bool> _toggles;
  bool _saving = false;

  static const _textFields = [
    ('site_name', 'Shop Name'),
    ('site_email', 'Email'),
    ('site_phone', 'Phone'),
    ('site_address', 'Address'),
    ('repair_prefix', 'Repair Job Prefix'),
    ('order_prefix', 'Order Prefix'),
    ('invoice_footer', 'Invoice Footer'),
  ];

  static const _toggleFields = [
    ('module_gsm', 'GSM Unlock Module'),
    ('module_repair', 'Repair Module'),
    ('module_pos', 'POS Module'),
    ('module_crm', 'CRM Module'),
    ('module_dues', 'Dues Module'),
    ('module_support', 'Support Module'),
    ('module_finance', 'Finance Module'),
    ('module_ecommerce', 'E-Commerce Module'),
    ('maintenance_mode', 'Maintenance Mode'),
    ('allow_registration', 'Allow Registration'),
    ('api_access', 'API Access'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = {
      for (final (key, _) in _textFields)
        key: TextEditingController(text: widget.data.get(key)),
    };
    _toggles = {
      for (final (key, _) in _toggleFields) key: widget.data.getBool(key),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final values = <String, String>{
        for (final (key, _) in _textFields) key: _ctrl[key]!.text.trim(),
        for (final (key, _) in _toggleFields) key: (_toggles[key]! ? '1' : '0'),
      };
      await ref.read(settingsRepoProvider).updateSettings(values);
      ref.invalidate(settingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Settings saved.')));
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
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Shop Info'),
          for (final (key, label) in _textFields)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextFormField(
                controller: _ctrl[key],
                decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
                maxLines: key == 'site_address' || key == 'invoice_footer' ? 2 : 1,
              ),
            ),
          const _SectionLabel('Modules'),
          ...(_toggleFields.map((entry) {
            final (key, label) = entry;
            return SwitchListTile(
              title: Text(label),
              value: _toggles[key]!,
              onChanged: (v) => setState(() => _toggles[key] = v),
              dense: true,
            );
          })),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}

class _CurrenciesTab extends ConsumerStatefulWidget {
  const _CurrenciesTab({required this.currencies});
  final List<CurrencyRow> currencies;

  @override
  ConsumerState<_CurrenciesTab> createState() => _CurrenciesTabState();
}

class _CurrenciesTabState extends ConsumerState<_CurrenciesTab> {
  Future<void> _showAddDialog() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final symbolCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code (e.g. EUR)'),
                textCapitalization: TextCapitalization.characters),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: symbolCtrl,
                decoration: const InputDecoration(labelText: 'Symbol (e.g. €)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ref.read(settingsRepoProvider).storeCurrency(
          code: codeCtrl.text.trim(),
          name: nameCtrl.text.trim(),
          symbol: symbolCtrl.text.trim());
      ref.invalidate(settingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggle(CurrencyRow c) async {
    try {
      await ref.read(settingsRepoProvider).toggleCurrency(c.id);
      ref.invalidate(settingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _setBase(CurrencyRow c) async {
    try {
      await ref.read(settingsRepoProvider).setBaseCurrency(c.id);
      ref.invalidate(settingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${c.code} set as base currency.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _delete(CurrencyRow c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${c.code}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(settingsRepoProvider).deleteCurrency(c.id);
      ref.invalidate(settingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: widget.currencies.length,
            itemBuilder: (ctx, i) {
              final c = widget.currencies[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(c.symbol, style: const TextStyle(fontSize: 16)),
                  ),
                  title: Text('${c.code} — ${c.name}'),
                  subtitle: Text(c.isBase
                      ? 'Base currency'
                      : 'Rate: ${c.rate?.toStringAsFixed(4) ?? '-'}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'toggle') _toggle(c);
                      if (v == 'base') _setBase(c);
                      if (v == 'delete') _delete(c);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(c.isActive ? 'Deactivate' : 'Activate'),
                      ),
                      if (!c.isBase)
                        const PopupMenuItem(value: 'base', child: Text('Set as Base')),
                      if (!c.isBase)
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                  tileColor: c.isActive ? null : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Currency'),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}
