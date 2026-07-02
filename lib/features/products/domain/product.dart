/// Row shape returned by Api\V1\ProductController@index/@show.
class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.sellPrice,
    this.sku,
    this.barcode,
    this.costPrice,
    this.stockQty = 0,
    this.minStock = 0,
    this.categoryId,
    this.categoryName,
    this.brandName,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String? sku;
  final String? barcode;
  final num sellPrice;
  final num? costPrice;
  final int stockQty;
  final int minStock;
  final int? categoryId;
  final String? categoryName;
  final String? brandName;
  final bool isActive;

  bool get isLowStock => stockQty <= minStock;

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      sellPrice: json['sell_price'] as num? ?? 0,
      costPrice: json['cost_price'] as num?,
      stockQty: json['stock_qty'] as int? ?? 0,
      minStock: json['min_stock'] as int? ?? 0,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      brandName: json['brand_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class ProductCategoryOption {
  const ProductCategoryOption({required this.id, required this.name});
  final int id;
  final String name;

  factory ProductCategoryOption.fromJson(Map<String, dynamic> json) =>
      ProductCategoryOption(id: json['id'] as int, name: json['name'] as String? ?? '');
}

class StockMovementRow {
  const StockMovementRow({
    required this.id,
    required this.type,
    required this.qty,
    required this.beforeQty,
    required this.afterQty,
    required this.createdAt,
    this.reference,
    this.note,
    this.createdByName,
  });

  final int id;
  final String type;
  final int qty;
  final int beforeQty;
  final int afterQty;
  final String? reference;
  final String? note;
  final String? createdByName;
  final DateTime createdAt;

  factory StockMovementRow.fromJson(Map<String, dynamic> json) {
    return StockMovementRow(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      qty: json['qty'] as int? ?? 0,
      beforeQty: json['before_qty'] as int? ?? 0,
      afterQty: json['after_qty'] as int? ?? 0,
      reference: json['reference'] as String?,
      note: json['note'] as String?,
      createdByName: json['created_by_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class ProductDetail {
  const ProductDetail({required this.summary, required this.movements, this.description, this.unit, this.enableSnImei = false});

  final ProductSummary summary;
  final List<StockMovementRow> movements;
  final String? description;
  final String? unit;
  final bool enableSnImei;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    return ProductDetail(
      summary: ProductSummary.fromJson(product),
      movements: (json['movements'] as List).map((e) => StockMovementRow.fromJson(e as Map<String, dynamic>)).toList(),
      description: product['description'] as String?,
      unit: product['unit'] as String?,
      enableSnImei: product['enable_sn_imei'] as bool? ?? false,
    );
  }
}
