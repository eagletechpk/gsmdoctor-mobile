import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/receipt_send_sheet.dart';
import '../../auth/domain/auth_controller.dart';
import '../domain/repair_job.dart';
import '../domain/repair_jobs_controller.dart';

class RepairJobCreateScreen extends ConsumerWidget {
  const RepairJobCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formDataAsync = ref.watch(repairFormDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Repair Job')),
      body: formDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load: $err')),
        data: (formData) => _CreateBody(formData: formData),
      ),
    );
  }
}

class _CreateBody extends ConsumerStatefulWidget {
  const _CreateBody({required this.formData});
  final RepairFormData formData;

  @override
  ConsumerState<_CreateBody> createState() => _CreateBodyState();
}

class _CreateBodyState extends ConsumerState<_CreateBody> {
  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _deviceController   = TextEditingController();
  final _imeiController     = TextEditingController();
  final _colorController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _issueController    = TextEditingController();
  final _estimateController = TextEditingController();
  final _advanceController  = TextEditingController();
  final _warrantyController = TextEditingController();
  final _notesController    = TextEditingController();

  // Customer live-search
  Timer? _customerSearchTimer;
  List<Map<String, dynamic>> _customerSuggestions = [];
  bool _showCustomerSuggestions = false;
  final _nameFocusNode  = FocusNode();
  final _phoneFocusNode = FocusNode();

  // Model live-search
  Timer? _modelSearchTimer;
  List<Map<String, dynamic>> _modelSuggestions = [];
  bool _showModelSuggestions = false;
  final _modelFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _deviceController.dispose();
    _imeiController.dispose();
    _colorController.dispose();
    _passwordController.dispose();
    _issueController.dispose();
    _estimateController.dispose();
    _advanceController.dispose();
    _warrantyController.dispose();
    _notesController.dispose();
    _customerSearchTimer?.cancel();
    _modelSearchTimer?.cancel();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _modelFocusNode.dispose();
    super.dispose();
  }

  // ── Customer search ────────────────────────────────────────────────────────

  void _searchCustomers(String q) {
    _customerSearchTimer?.cancel();
    if (q.trim().length < 2) {
      setState(() => _customerSuggestions = []);
      return;
    }
    _customerSearchTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final res = await ref.read(dioProvider).get('/crm/search', queryParameters: {'q': q});
        final list = (res.data['data']['customers'] as List).cast<Map<String, dynamic>>();
        if (mounted) setState(() => _customerSuggestions = list);
      } catch (_) {}
    });
  }

  void _selectCustomer(Map<String, dynamic> c) {
    final name  = c['name']  as String? ?? '';
    final phone = c['phone'] as String? ?? '';
    final id    = c['id']    as int?;
    _nameController.text  = name;
    _phoneController.text = phone;
    ref.read(newRepairJobProvider.notifier).setCustomer(name: name, phone: phone, id: id);
    setState(() { _customerSuggestions = []; _showCustomerSuggestions = false; });
  }

  // ── Model search ───────────────────────────────────────────────────────────

  void _searchModels(String q) {
    _modelSearchTimer?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _modelSuggestions = []);
      return;
    }
    final brandId = ref.read(newRepairJobProvider).brandId;
    _modelSearchTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final params = <String, dynamic>{'q': q};
        if (brandId != null) params['brand_id'] = brandId;
        final res = await ref.read(dioProvider).get('/repair-jobs/models/search', queryParameters: params);
        final list = (res.data['data']['models'] as List).cast<Map<String, dynamic>>();
        if (mounted) setState(() => _modelSuggestions = list);
      } catch (_) {}
    });
  }

  void _selectModel(Map<String, dynamic> m) {
    final name = m['name'] as String? ?? '';
    _deviceController.text = name;
    ref.read(newRepairJobProvider.notifier).setDeviceModel(name);
    setState(() { _modelSuggestions = []; _showModelSuggestions = false; });
    _modelFocusNode.unfocus();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(newRepairJobProvider);
    final notifier = ref.read(newRepairJobProvider.notifier);
    final cs       = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Customer ────────────────────────────────────────────────────────
        const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),

        TextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          decoration: const InputDecoration(
            labelText: 'Customer Name',
            hintText: 'Type to search existing customers',
            prefixIcon: Icon(Icons.person_search_outlined, size: 20),
          ),
          onChanged: (v) {
            notifier.setCustomer(name: v, phone: _phoneController.text);
            setState(() => _showCustomerSuggestions = true);
            _searchCustomers(v);
          },
          onTap: () => setState(() => _showCustomerSuggestions = true),
        ),
        if (_showCustomerSuggestions && _customerSuggestions.isNotEmpty)
          _suggestionBox(
            _customerSuggestions.map((c) => ListTile(
              dense: true,
              leading: const Icon(Icons.person_outline, size: 18),
              title: Text(c['name'] as String? ?? ''),
              subtitle: Text(c['phone'] as String? ?? ''),
              onTap: () => _selectCustomer(c),
            )).toList(),
          ),

        const SizedBox(height: 8),

        TextField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          decoration: const InputDecoration(
            labelText: 'Phone',
            hintText: 'Type to search by phone',
            prefixIcon: Icon(Icons.phone_outlined, size: 20),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (v) {
            notifier.setCustomer(name: _nameController.text, phone: v);
            setState(() => _showCustomerSuggestions = true);
            _searchCustomers(v);
          },
          onTap: () => setState(() => _showCustomerSuggestions = true),
        ),

        const Divider(height: 28),

        // ── Device ──────────────────────────────────────────────────────────
        const Text('Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),

        DropdownButtonFormField<int>(
          initialValue: state.brandId,
          decoration: const InputDecoration(labelText: 'Brand (optional)'),
          items: widget.formData.brands
              .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
              .toList(),
          onChanged: (v) {
            notifier.setBrand(v);
            // Re-run model search with new brand filter if field has text
            if (_deviceController.text.trim().isNotEmpty) {
              _searchModels(_deviceController.text);
            }
            // Auto-assign technician — mirrors web create_v5.blade.php logic
            if (v != null) {
              final isApple = widget.formData.appleBrandIds.contains(v);
              final techId = isApple
                  ? widget.formData.techAssignApple
                  : widget.formData.techAssignAndroid;
              if (techId != null) notifier.setTechnician(techId);
            }
          },
        ),
        const SizedBox(height: 8),

        // Device model with live-search dropdown
        TextField(
          controller: _deviceController,
          focusNode: _modelFocusNode,
          decoration: const InputDecoration(
            labelText: 'Device Model',
            hintText: 'Type to search models…',
            prefixIcon: Icon(Icons.phone_android_outlined, size: 20),
          ),
          onChanged: (v) {
            notifier.setDeviceModel(v);
            setState(() => _showModelSuggestions = true);
            _searchModels(v);
          },
          onTap: () {
            setState(() => _showModelSuggestions = true);
            if (_deviceController.text.trim().isNotEmpty) {
              _searchModels(_deviceController.text);
            }
          },
        ),
        if (_showModelSuggestions && _modelSuggestions.isNotEmpty)
          _suggestionBox(
            _modelSuggestions.map((m) => ListTile(
              dense: true,
              leading: const Icon(Icons.phone_outlined, size: 18),
              title: Text(m['name'] as String? ?? ''),
              onTap: () => _selectModel(m),
            )).toList(),
          ),

        const SizedBox(height: 8),
        TextField(
          controller: _colorController,
          decoration: const InputDecoration(labelText: 'Color'),
          onChanged: notifier.setColor,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _imeiController,
          decoration: const InputDecoration(labelText: 'IMEI / Serial'),
          onChanged: notifier.setImei,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Device Password / Pattern (optional)'),
          onChanged: notifier.setDevicePassword,
        ),
        const SizedBox(height: 12),

        // Phone condition — button group instead of dropdown
        const Text('Condition', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.formData.deviceConditions.map((c) {
            final selected = state.deviceCondition == c.label;
            return ChoiceChip(
              label: Text('${c.icon ?? ''} ${c.label}'.trim()),
              selected: selected,
              onSelected: (_) => notifier.setDeviceCondition(c.label),
              selectedColor: cs.primaryContainer,
              labelStyle: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? cs.onPrimaryContainer : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),
        const Text('Checklist', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.formData.checklistItems
              .map((c) => FilterChip(
                    label: Text('${c.icon ?? ''} ${c.label}'.trim()),
                    selected: state.checklist.contains(c.label),
                    onSelected: (_) => notifier.toggleChecklistItem(c.label),
                  ))
              .toList(),
        ),

        const Divider(height: 28),

        // ── Issue & Job ──────────────────────────────────────────────────────
        const Text('Issue & Job Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _issueController,
          decoration: const InputDecoration(labelText: 'Reported Issue'),
          maxLines: 3,
          onChanged: notifier.setReportedIssue,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: state.technicianId,
          decoration: const InputDecoration(labelText: 'Technician (optional)'),
          items: widget.formData.technicians
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
              .toList(),
          onChanged: notifier.setTechnician,
        ),
        const SizedBox(height: 12),
        const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: repairPriorityOptions
              .map((p) => ChoiceChip(
                    label: Text(p[0].toUpperCase() + p.substring(1)),
                    selected: state.priority == p,
                    onSelected: (_) => notifier.setPriority(p),
                  ))
              .toList(),
        ),

        const Divider(height: 28),

        // ── Cost & Warranty ──────────────────────────────────────────────────
        const Text('Cost & Warranty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _estimateController,
          decoration: const InputDecoration(
            labelText: 'Estimate Cost',
            hintText: '0',
            prefixIcon: Icon(Icons.attach_money, size: 20),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => notifier.setEstimateCost(num.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _advanceController,
          decoration: const InputDecoration(
            labelText: 'Advance Paid',
            hintText: '0',
            prefixIcon: Icon(Icons.payments_outlined, size: 20),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => notifier.setAdvancePaid(num.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _warrantyController,
          decoration: const InputDecoration(
            labelText: 'Warranty Days',
            hintText: '0',
            prefixIcon: Icon(Icons.verified_outlined, size: 20),
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) => notifier.setWarrantyDays(int.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            state.dueDate == null
                ? 'Expected Ready Date (optional)'
                : DateFormat('dd MMM yyyy').format(state.dueDate!),
          ),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.dueDate ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) notifier.setDueDate(picked);
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
          maxLines: 2,
          onChanged: notifier.setNotes,
        ),
        const SizedBox(height: 16),
        _summaryRow('Balance Due', formatMoney(state.balanceDue), bold: true),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.isSubmitting
                ? null
                : () async {
                    try {
                      final result = await notifier.submit();
                      if (context.mounted) {
                        await showReceiptSendSheet(context, job: result);
                        if (context.mounted) {
                          context.pushReplacement('/repair-jobs/${result.id}');
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
            child: Text(state.isSubmitting ? 'Creating...' : 'Create Repair Job'),
          ),
        ),
      ],
    );
  }

  Widget _suggestionBox(List<Widget> tiles) {
    return Container(
      constraints: BoxConstraints(maxHeight: min(tiles.length * 56.0, 200)),
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView(shrinkWrap: true, children: tiles),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
