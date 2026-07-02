/// Row shapes returned by Api\V1\PosController.
class PosProduct {
  const PosProduct({
    required this.id,
    required this.name,
    required this.sellPrice,
    this.sku,
    this.barcode,
    this.costPrice,
    this.stockQty = 0,
    this.categoryId,
    this.categoryName,
    this.enableSnImei = false,
  });

  final int id;
  final String name;
  final String? sku;
  final String? barcode;
  final num sellPrice;
  final num? costPrice;
  final int stockQty;
  final int? categoryId;
  final String? categoryName;
  final bool enableSnImei;

  factory PosProduct.fromJson(Map<String, dynamic> json) {
    return PosProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      sellPrice: json['sell_price'] as num? ?? 0,
      costPrice: json['cost_price'] as num?,
      stockQty: json['stock_qty'] as int? ?? 0,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      enableSnImei: json['enable_sn_imei'] as bool? ?? false,
    );
  }
}

class PosCategory {
  const PosCategory({required this.id, required this.name});
  final int id;
  final String name;

  factory PosCategory.fromJson(Map<String, dynamic> json) =>
      PosCategory(id: json['id'] as int, name: json['name'] as String? ?? '');
}

class PosAccount {
  const PosAccount({required this.id, required this.name, this.balance = 0});
  final int id;
  final String name;
  final num balance;

  factory PosAccount.fromJson(Map<String, dynamic> json) =>
      PosAccount(id: json['id'] as int, name: json['name'] as String? ?? '', balance: json['balance'] as num? ?? 0);
}

class PosPaymentMethod {
  const PosPaymentMethod({required this.id, required this.name, required this.type});
  final int id;
  final String name;
  final String type;

  factory PosPaymentMethod.fromJson(Map<String, dynamic> json) => PosPaymentMethod(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'cash',
      );
}

class PosTaxRate {
  const PosTaxRate({required this.id, required this.name, required this.rate});
  final int id;
  final String name;
  final num rate;

  factory PosTaxRate.fromJson(Map<String, dynamic> json) =>
      PosTaxRate(id: json['id'] as int, name: json['name'] as String? ?? '', rate: json['rate'] as num? ?? 0);
}

class PosHeldSale {
  const PosHeldSale({required this.id, required this.items, this.note, this.createdAt});
  final int id;
  final List<dynamic> items;
  final String? note;
  final DateTime? createdAt;

  factory PosHeldSale.fromJson(Map<String, dynamic> json) => PosHeldSale(
        id: json['id'] as int,
        items: (json['items'] as List?) ?? const [],
        note: json['note'] as String?,
        createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'] as String),
      );
}

class PosTerminalData {
  const PosTerminalData({
    required this.products,
    required this.categories,
    required this.accounts,
    required this.paymentMethods,
    required this.taxRates,
    required this.heldSales,
  });

  final List<PosProduct> products;
  final List<PosCategory> categories;
  final List<PosAccount> accounts;
  final List<PosPaymentMethod> paymentMethods;
  final List<PosTaxRate> taxRates;
  final List<PosHeldSale> heldSales;

  factory PosTerminalData.fromJson(Map<String, dynamic> json) {
    return PosTerminalData(
      products: (json['products'] as List).map((e) => PosProduct.fromJson(e as Map<String, dynamic>)).toList(),
      categories:
          (json['categories'] as List).map((e) => PosCategory.fromJson(e as Map<String, dynamic>)).toList(),
      accounts: (json['accounts'] as List).map((e) => PosAccount.fromJson(e as Map<String, dynamic>)).toList(),
      paymentMethods: (json['payment_methods'] as List)
          .map((e) => PosPaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList(),
      taxRates: (json['tax_rates'] as List).map((e) => PosTaxRate.fromJson(e as Map<String, dynamic>)).toList(),
      heldSales:
          (json['held_sales'] as List).map((e) => PosHeldSale.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Client-side cart line — mirrors the shape PosController::sale() expects
/// in its `items` JSON array ({id, qty, price, disc, warranty, imei_sn}).
class CartLine {
  CartLine({
    required this.product,
    this.qty = 1,
    num? price,
    this.discount = 0,
    this.warrantyDays = 0,
    this.imeiSn,
    this.discountOpen = false,
    this.imeiOpen = false,
    this.warrantyOpen = false,
  }) : price = price ?? product.sellPrice;

  final PosProduct product;
  int qty;
  num price;
  num discount;
  int warrantyDays;
  String? imeiSn;

  // UI toggle state — open/close expandable option rows
  bool discountOpen;
  bool imeiOpen;
  bool warrantyOpen;

  num get total => (price * qty - discount).clamp(0, double.infinity);

  Map<String, dynamic> toJson() => {
        'id': product.id,
        'qty': qty,
        'price': price,
        'disc': discount,
        'warranty': warrantyDays,
        if (imeiSn != null && imeiSn!.isNotEmpty) 'imei_sn': imeiSn,
      };
}

class SaleResult {
  const SaleResult({required this.invoiceNumber, required this.saleId, required this.change, required this.total});
  final String invoiceNumber;
  final int saleId;
  final num change;
  final num total;

  factory SaleResult.fromJson(Map<String, dynamic> json) => SaleResult(
        invoiceNumber: json['invoice_number'] as String,
        saleId: json['sale_id'] as int,
        change: json['change'] as num? ?? 0,
        total: json['total'] as num? ?? 0,
      );
}
