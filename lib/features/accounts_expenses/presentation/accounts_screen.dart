import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../domain/account.dart';
import '../domain/accounts_controller.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(accountsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Expenses',
            onPressed: () => context.push('/expenses'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load accounts: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(accountsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _TotalBalanceCard(total: data.totalBalance),
              const SizedBox(height: 16),
              const Text('Accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...data.accounts.map((a) => _AccountTile(account: a, ref: ref)),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(onPressed: () => context.push('/expenses'), child: const Text('Expenses')),
                ],
              ),
              const SizedBox(height: 8),
              if (data.recentTransactions.isEmpty)
                const Padding(padding: EdgeInsets.all(8), child: Text('No recent transactions.'))
              else
                ...data.recentTransactions.map((t) => _TxTile(tx: t)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
        onPressed: () => _showAddTxDialog(context, ref),
      ),
    );
  }

  void _showAddTxDialog(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.read(accountsProvider);
    final accounts = accountsAsync.value?.accounts ?? [];
    if (accounts.isEmpty) return;

    int? selectedAccountId = accounts.first.id;
    String type = 'income';
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedAccountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: accounts
                      .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedAccountId = v),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_downward)),
                    ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setState(() => type = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0 || selectedAccountId == null) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(accountsRepoProvider).storeTransaction(
                        accountId: selectedAccountId!,
                        type: type,
                        amount: amount,
                        category: categoryCtrl.text.trim(),
                        note: noteCtrl.text.trim(),
                      );
                  ref.invalidate(accountsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction recorded.')),
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

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({required this.total});
  final num total;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Balance', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
            const SizedBox(height: 4),
            Text(
              formatMoney(total),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account, required this.ref});
  final AccountRow account;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            account.isDefault ? Icons.account_balance : Icons.savings_outlined,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${account.type.toUpperCase()} · ${account.currency}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatMoney(account.balance), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(
              '↑${formatMoney(account.totalIn)}  ↓${formatMoney(account.totalOut)}',
              style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile({required this.tx});
  final RecentTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: isIncome ? Colors.green.shade100 : Colors.red.shade100,
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          size: 14,
          color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
      title: Text(tx.category?.isNotEmpty == true ? tx.category! : tx.type.toUpperCase(),
          style: const TextStyle(fontSize: 13)),
      subtitle: Text('${tx.accountName} · ${tx.note ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isIncome ? '+' : '-'}${formatMoney(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 13,
            ),
          ),
          Text(
            DateFormat('MMM d').format(tx.createdAt),
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
