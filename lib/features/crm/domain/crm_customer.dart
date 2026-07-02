/// Row shape returned by Api\V1\CrmController@index/@search/@quickAdd.
class CrmCustomerSummary {
  const CrmCustomerSummary({
    required this.id,
    required this.name,
    required this.phone,
    this.city,
    this.totalDues = 0,
    this.totalSpent = 0,
    this.repairsCount,
    this.salesCount,
    this.createdAt,
  });

  final int id;
  final String name;
  final String phone;
  final String? city;
  final num totalDues;
  final num totalSpent;
  final int? repairsCount;
  final int? salesCount;
  final DateTime? createdAt;

  factory CrmCustomerSummary.fromJson(Map<String, dynamic> json) {
    return CrmCustomerSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String?,
      totalDues: json['total_dues'] as num? ?? 0,
      totalSpent: json['total_spent'] as num? ?? 0,
      repairsCount: json['repairs_count'] as int?,
      salesCount: json['sales_count'] as int?,
      createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
    );
  }
}

class CrmRepairRow {
  const CrmRepairRow({
    required this.id,
    required this.jobNumber,
    required this.status,
    required this.createdAt,
    this.deviceModel,
    this.technicianName,
  });

  final int id;
  final String jobNumber;
  final String? deviceModel;
  final String status;
  final String? technicianName;
  final DateTime createdAt;

  factory CrmRepairRow.fromJson(Map<String, dynamic> json) {
    return CrmRepairRow(
      id: json['id'] as int,
      jobNumber: json['job_number'] as String? ?? '',
      deviceModel: json['device_model'] as String?,
      status: json['status'] as String? ?? 'received',
      technicianName: json['technician_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CrmSaleRow {
  const CrmSaleRow({
    required this.id,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.dueAmount,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String invoiceNumber;
  final num totalAmount;
  final num dueAmount;
  final String status;
  final DateTime createdAt;

  factory CrmSaleRow.fromJson(Map<String, dynamic> json) {
    return CrmSaleRow(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      totalAmount: json['total_amount'] as num? ?? 0,
      dueAmount: json['due_amount'] as num? ?? 0,
      status: json['status'] as String? ?? 'completed',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CrmDuesRow {
  const CrmDuesRow({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.note,
  });

  final int id;
  final String type;
  final num amount;
  final num balanceAfter;
  final String? note;
  final DateTime createdAt;

  factory CrmDuesRow.fromJson(Map<String, dynamic> json) {
    return CrmDuesRow(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      amount: json['amount'] as num? ?? 0,
      balanceAfter: json['balance_after'] as num? ?? 0,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class CrmWarrantyRow {
  const CrmWarrantyRow({required this.id, required this.status, this.productName, this.expiryDate});

  final int id;
  final String? productName;
  final String? expiryDate;
  final String status;

  factory CrmWarrantyRow.fromJson(Map<String, dynamic> json) {
    return CrmWarrantyRow(
      id: json['id'] as int,
      productName: json['product_name'] as String?,
      expiryDate: json['expiry_date'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class CrmCustomerDetail {
  const CrmCustomerDetail({
    required this.summary,
    required this.repairs,
    required this.sales,
    required this.dues,
    required this.warranties,
    this.phone2,
    this.email,
    this.address,
    this.source,
  });

  final CrmCustomerSummary summary;
  final List<CrmRepairRow> repairs;
  final List<CrmSaleRow> sales;
  final List<CrmDuesRow> dues;
  final List<CrmWarrantyRow> warranties;
  final String? phone2;
  final String? email;
  final String? address;
  final String? source;

  factory CrmCustomerDetail.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>;
    return CrmCustomerDetail(
      summary: CrmCustomerSummary.fromJson(customer),
      repairs: (json['repairs'] as List).map((e) => CrmRepairRow.fromJson(e as Map<String, dynamic>)).toList(),
      sales: (json['sales'] as List).map((e) => CrmSaleRow.fromJson(e as Map<String, dynamic>)).toList(),
      dues: (json['dues'] as List).map((e) => CrmDuesRow.fromJson(e as Map<String, dynamic>)).toList(),
      warranties:
          (json['warranties'] as List).map((e) => CrmWarrantyRow.fromJson(e as Map<String, dynamic>)).toList(),
      phone2: customer['phone2'] as String?,
      email: customer['email'] as String?,
      address: customer['address'] as String?,
      source: customer['source'] as String?,
    );
  }
}

class CrmStatementRow {
  const CrmStatementRow({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    required this.runningBalance,
    this.note,
  });

  final int id;
  final String type;
  final num amount;
  final String? note;
  final DateTime createdAt;
  final num runningBalance;

  factory CrmStatementRow.fromJson(Map<String, dynamic> json) {
    return CrmStatementRow(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      amount: json['amount'] as num? ?? 0,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      runningBalance: json['running_balance'] as num? ?? 0,
    );
  }
}

class CrmStatement {
  const CrmStatement({
    required this.customer,
    required this.from,
    required this.to,
    required this.openingBalance,
    required this.transactions,
    required this.totalDebits,
    required this.totalCredits,
    required this.closingBalance,
  });

  final CrmCustomerSummary customer;
  final String from;
  final String to;
  final num openingBalance;
  final List<CrmStatementRow> transactions;
  final num totalDebits;
  final num totalCredits;
  final num closingBalance;

  factory CrmStatement.fromJson(Map<String, dynamic> json) {
    return CrmStatement(
      customer: CrmCustomerSummary.fromJson(json['customer'] as Map<String, dynamic>),
      from: json['from'] as String,
      to: json['to'] as String,
      openingBalance: json['opening_balance'] as num? ?? 0,
      transactions:
          (json['transactions'] as List).map((e) => CrmStatementRow.fromJson(e as Map<String, dynamic>)).toList(),
      totalDebits: json['total_debits'] as num? ?? 0,
      totalCredits: json['total_credits'] as num? ?? 0,
      closingBalance: json['closing_balance'] as num? ?? 0,
    );
  }
}
