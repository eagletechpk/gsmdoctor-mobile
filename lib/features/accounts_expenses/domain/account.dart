class AccountRow {
  const AccountRow({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.isDefault,
    required this.totalIn,
    required this.totalOut,
  });

  final int id;
  final String name;
  final String type;
  final num balance;
  final String currency;
  final bool isDefault;
  final num totalIn;
  final num totalOut;

  factory AccountRow.fromJson(Map<String, dynamic> j) => AccountRow(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        type: j['type'] as String? ?? '',
        balance: j['balance'] as num? ?? 0,
        currency: j['currency'] as String? ?? 'PKR',
        isDefault: j['is_default'] == true || j['is_default'] == 1,
        totalIn: j['total_in'] as num? ?? 0,
        totalOut: j['total_out'] as num? ?? 0,
      );
}

class RecentTransaction {
  const RecentTransaction({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.category,
    this.note,
  });

  final int id;
  final int accountId;
  final String accountName;
  final String type;
  final num amount;
  final num balanceAfter;
  final DateTime createdAt;
  final String? category;
  final String? note;

  factory RecentTransaction.fromJson(Map<String, dynamic> j) => RecentTransaction(
        id: j['id'] as int,
        accountId: j['account_id'] as int? ?? 0,
        accountName: j['account_name'] as String? ?? '',
        type: j['type'] as String? ?? '',
        amount: j['amount'] as num? ?? 0,
        balanceAfter: j['balance_after'] as num? ?? 0,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
        category: j['category'] as String?,
        note: j['note'] as String?,
      );
}

class AccountsPageData {
  const AccountsPageData({
    required this.accounts,
    required this.recentTransactions,
    required this.totalBalance,
  });

  final List<AccountRow> accounts;
  final List<RecentTransaction> recentTransactions;
  final num totalBalance;
}

class ExpenseRow {
  const ExpenseRow({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
    this.accountId,
    this.accountName,
    this.createdBy,
  });

  final int id;
  final String category;
  final num amount;
  final String description;
  final String date;
  final DateTime createdAt;
  final int? accountId;
  final String? accountName;
  final String? createdBy;

  factory ExpenseRow.fromJson(Map<String, dynamic> j) => ExpenseRow(
        id: j['id'] as int,
        category: j['category'] as String? ?? '',
        amount: j['amount'] as num? ?? 0,
        description: j['description'] as String? ?? '',
        date: j['date'] as String? ?? '',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
        accountId: j['account_id'] as int?,
        accountName: j['account_name'] as String?,
        createdBy: j['created_by'] as String?,
      );
}

class ExpenseFormData {
  const ExpenseFormData({required this.accounts, required this.categories});

  final List<Map<String, dynamic>> accounts;
  final List<String> categories;
}
