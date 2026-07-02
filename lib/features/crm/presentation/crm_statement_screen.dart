import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../domain/crm_controller.dart';
import '../domain/crm_customer.dart';

final _dateKeyFormat = DateFormat('yyyy-MM-dd');

class CrmStatementScreen extends ConsumerStatefulWidget {
  const CrmStatementScreen({super.key, required this.customerId});

  final int customerId;

  @override
  ConsumerState<CrmStatementScreen> createState() => _CrmStatementScreenState();
}

class _CrmStatementScreenState extends ConsumerState<CrmStatementScreen> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  Future<CrmStatement>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = ref.read(crmRepositoryProvider).statement(
            widget.customerId,
            from: _dateKeyFormat.format(_from),
            to: _dateKeyFormat.format(_to),
          );
    });
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range != null) {
      setState(() {
        _from = range.start;
        _to = range.end;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statement'),
        actions: [
          IconButton(icon: const Icon(Icons.sync), tooltip: 'Refresh', onPressed: _load),
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
        ],
      ),
      body: FutureBuilder<CrmStatement>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final statement = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${DateFormat('d MMM yyyy').format(_from)} – ${DateFormat('d MMM yyyy').format(_to)}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _summaryRow('Opening Balance', formatMoney(statement.openingBalance)),
                      _summaryRow('Total Debits', formatMoney(statement.totalDebits)),
                      _summaryRow('Total Credits', formatMoney(statement.totalCredits)),
                      const Divider(),
                      _summaryRow('Closing Balance', formatMoney(statement.closingBalance), bold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (statement.transactions.isEmpty)
                const Padding(padding: EdgeInsets.all(8), child: Text('No transactions in this range.'))
              else
                ...statement.transactions.map((tx) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        title: Text(statusLabel(tx.type)),
                        subtitle: Text('${formatDateTime(tx.createdAt)}${tx.note != null ? ' · ${tx.note}' : ''}'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${tx.amount > 0 ? '+' : ''}${formatMoney(tx.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx.amount > 0 ? Colors.red : Colors.green,
                              ),
                            ),
                            Text('Bal: ${formatMoney(tx.runningBalance)}', style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
