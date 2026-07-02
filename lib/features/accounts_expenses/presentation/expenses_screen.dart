import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../domain/account.dart';
import '../domain/accounts_controller.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _category = '';
  int _page = 1;

  ({int page, String search, String category}) get _params =>
      (page: _page, search: _search, category: _category);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(expensesProvider(_params));
    final formAsync = ref.watch(expenseFormDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(expensesProvider(_params)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search expenses…',
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
                const SizedBox(width: 8),
                formAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (fd) => DropdownButton<String>(
                    value: _category.isEmpty ? null : _category,
                    hint: const Text('Category'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All')),
                      ...fd.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (v) => setState(() { _category = v ?? ''; _page = 1; }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed: $e')),
              data: (result) => result.expenses.isEmpty
                  ? const Center(child: Text('No expenses found.'))
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Row(
                            children: [
                              const Text('Total:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(formatMoney(result.totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async => ref.invalidate(expensesProvider(_params)),
                            child: ListView.separated(
                              itemCount: result.expenses.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) => _ExpenseTile(e: result.expenses[i]),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final formAsync = ref.read(expenseFormDataProvider);
    final fd = formAsync.value;
    if (fd == null) return;

    int? selectedAccountId = fd.accounts.isNotEmpty ? fd.accounts.first['id'] as int : null;
    String? selectedCategory = fd.categories.isNotEmpty ? fd.categories.first : null;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Record Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedAccountId,
                  decoration: const InputDecoration(labelText: 'Account *'),
                  items: fd.accounts
                      .map((a) => DropdownMenuItem<int>(
                            value: a['id'] as int,
                            child: Text('${a['name']} (${formatMoney(a['balance'] as num)})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedAccountId = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: fd.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.parse(dateStr),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => dateStr = DateFormat('yyyy-MM-dd').format(picked));
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
                    child: Text(dateStr),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                final desc = descCtrl.text.trim();
                if (amount == null || amount <= 0 || selectedAccountId == null ||
                    selectedCategory == null || desc.isEmpty) { return; }
                Navigator.pop(ctx);
                try {
                  await ref.read(expensesRepoProvider).store(
                        category: selectedCategory!,
                        amount: amount,
                        accountId: selectedAccountId!,
                        description: desc,
                        date: dateStr,
                      );
                  ref.invalidate(expensesProvider(_params));
                  ref.invalidate(accountsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Expense recorded.')),
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.e});
  final ExpenseRow e;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.red.shade50,
        child: Icon(Icons.arrow_upward, size: 16, color: Colors.red.shade700),
      ),
      title: Text(e.description, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text('${e.category} · ${e.accountName ?? ''} · ${e.date}',
          style: const TextStyle(fontSize: 11)),
      trailing: Text(formatMoney(e.amount),
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
    );
  }
}
