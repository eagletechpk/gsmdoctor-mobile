/// Row shape returned by Api\V1\PurchaseController@index/@show.
class PurchaseOrderSummary {
  const PurchaseOrderSummary({
    required this.id,
    required this.poNumber,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.status,
    required this.createdAt,
    this.supplierName,
  });

  final int id;
  final String poNumber;
  final String? supplierName;
  final num totalAmount;
  final num paidAmount;
  final num dueAmount;
  final String status;
  final DateTime createdAt;

  factory PurchaseOrderSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderSummary(
      id: json['id'] as int,
      poNumber: json['po_number'] as String? ?? '',
      supplierName: json['supplier_name'] as String?,
      totalAmount: json['total_amount'] as num? ?? 0,
      paidAmount: json['paid_amount'] as num? ?? 0,
      dueAmount: json['due_amount'] as num? ?? 0,
      status: json['status'] as String? ?? 'draft',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PurchaseOrderItemRow {
  const PurchaseOrderItemRow({
    required this.id,
    required this.productId,
    required this.qty,
    required this.costPrice,
    required this.total,
    this.productName,
    this.imeiSn,
  });

  final int id;
  final int productId;
  final String? productName;
  final int qty;
  final num costPrice;
  final num total;
  final String? imeiSn;

  factory PurchaseOrderItemRow.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItemRow(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String?,
      qty: json['qty'] as int? ?? 0,
      costPrice: json['cost_price'] as num? ?? 0,
      total: json['total'] as num? ?? 0,
      imeiSn: json['imei_sn'] as String?,
    );
  }
}

class PurchaseOrderDetail {
  const PurchaseOrderDetail({required this.summary, required this.items, this.notes, this.cargoCharges = 0, this.createdByName});

  final PurchaseOrderSummary summary;
  final List<PurchaseOrderItemRow> items;
  final String? notes;
  final num cargoCharges;
  final String? createdByName;

  factory PurchaseOrderDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderDetail(
      summary: PurchaseOrderSummary.fromJson(json),
      items: (json['items'] as List).map((e) => PurchaseOrderItemRow.fromJson(e as Map<String, dynamic>)).toList(),
      notes: json['notes'] as String?,
      cargoCharges: json['cargo_charges'] as num? ?? 0,
      createdByName: json['created_by_name'] as String?,
    );
  }
}

class SupplierOption {
  const SupplierOption({required this.id, required this.name, this.company, this.balance = 0});
  final int id;
  final String name;
  final String? company;
  final num balance;

  factory SupplierOption.fromJson(Map<String, dynamic> json) => SupplierOption(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        company: json['company'] as String?,
        balance: json['balance'] as num? ?? 0,
      );
}

class PurchaseProductOption {
  const PurchaseProductOption({required this.id, required this.name, this.sku, this.costPrice = 0, this.stockQty = 0});
  final int id;
  final String name;
  final String? sku;
  final num costPrice;
  final int stockQty;

  factory PurchaseProductOption.fromJson(Map<String, dynamic> json) => PurchaseProductOption(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String?,
        costPrice: json['cost_price'] as num? ?? 0,
        stockQty: json['stock_qty'] as int? ?? 0,
      );
}

class PurchaseAccountOption {
  const PurchaseAccountOption({required this.id, required this.name, this.balance = 0});
  final int id;
  final String name;
  final num balance;

  factory PurchaseAccountOption.fromJson(Map<String, dynamic> json) => PurchaseAccountOption(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        balance: json['balance'] as num? ?? 0,
      );
}

class PurchaseFormData {
  const PurchaseFormData({required this.suppliers, required this.products, required this.accounts});
  final List<SupplierOption> suppliers;
  final List<PurchaseProductOption> products;
  final List<PurchaseAccountOption> accounts;

  factory PurchaseFormData.fromJson(Map<String, dynamic> json) {
    return PurchaseFormData(
      suppliers: (json['suppliers'] as List).map((e) => SupplierOption.fromJson(e as Map<String, dynamic>)).toList(),
      products: (json['products'] as List).map((e) => PurchaseProductOption.fromJson(e as Map<String, dynamic>)).toList(),
      accounts: (json['accounts'] as List).map((e) => PurchaseAccountOption.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class NewPurchaseItem {
  NewPurchaseItem({required this.product, this.qty = 1, num? costPrice}) : costPrice = costPrice ?? product.costPrice;

  final PurchaseProductOption product;
  int qty;
  num costPrice;

  num get total => qty * costPrice;

  Map<String, dynamic> toJson() => {'product_id': product.id, 'qty': qty, 'cost_price': costPrice};
}

const purchaseOrderStatusOptions = <String>['draft', 'ordered', 'received', 'cancelled'];
