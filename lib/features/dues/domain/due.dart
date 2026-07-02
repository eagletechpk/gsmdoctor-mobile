/// Row shape returned by Api\V1\DuesController@index/@show.
class DueCustomerRow {
  const DueCustomerRow({required this.id, required this.name, required this.phone, required this.totalDues, this.nextDue});

  final int id;
  final String name;
  final String phone;
  final num totalDues;
  final String? nextDue;

  factory DueCustomerRow.fromJson(Map<String, dynamic> json) {
    return DueCustomerRow(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      totalDues: json['total_dues'] as num? ?? 0,
      nextDue: json['next_due'] as String?,
    );
  }
}

class OverdueRow {
  const OverdueRow({required this.id, required this.name, required this.phone, required this.totalDues, required this.oldestDue});

  final int id;
  final String name;
  final String phone;
  final num totalDues;
  final String oldestDue;

  factory OverdueRow.fromJson(Map<String, dynamic> json) {
    return OverdueRow(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      totalDues: json['total_dues'] as num? ?? 0,
      oldestDue: json['oldest_due'] as String? ?? '',
    );
  }
}

class DueLedgerRow {
  const DueLedgerRow({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.dueDate,
    this.note,
  });

  final int id;
  final String type;
  final num amount;
  final num balanceAfter;
  final String? dueDate;
  final String? note;
  final DateTime createdAt;

  factory DueLedgerRow.fromJson(Map<String, dynamic> json) {
    return DueLedgerRow(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      amount: json['amount'] as num? ?? 0,
      balanceAfter: json['balance_after'] as num? ?? 0,
      dueDate: json['due_date'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DueCustomerDetail {
  const DueCustomerDetail({required this.id, required this.name, required this.phone, required this.totalDues, required this.ledger, this.snoozedUntil});

  final int id;
  final String name;
  final String phone;
  final num totalDues;
  final List<DueLedgerRow> ledger;
  final String? snoozedUntil;

  factory DueCustomerDetail.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>;
    return DueCustomerDetail(
      id: customer['id'] as int,
      name: customer['name'] as String? ?? '',
      phone: customer['phone'] as String? ?? '',
      totalDues: customer['total_dues'] as num? ?? 0,
      ledger: (json['ledger'] as List).map((e) => DueLedgerRow.fromJson(e as Map<String, dynamic>)).toList(),
      snoozedUntil: json['snoozed_until'] as String?,
    );
  }
}
