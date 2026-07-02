class OnlineOrderSummary {
  final int id;
  final String orderNumber;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final double totalAmount;
  final String paymentStatus;
  final String fulfillmentStatus;
  final String? paymentMethod;
  final String? createdAt;

  const OnlineOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.totalAmount,
    required this.paymentStatus,
    required this.fulfillmentStatus,
    this.paymentMethod,
    this.createdAt,
  });

  factory OnlineOrderSummary.fromJson(Map<String, dynamic> json) =>
      OnlineOrderSummary(
        id: json['id'] as int,
        orderNumber: json['order_number'] as String,
        customerName: json['customer_name'] as String,
        customerEmail: json['customer_email'] as String?,
        customerPhone: json['customer_phone'] as String?,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        fulfillmentStatus: json['fulfillment_status'] as String? ?? 'unfulfilled',
        paymentMethod: json['payment_method'] as String?,
        createdAt: json['created_at'] as String?,
      );
}

class OnlineOrderItem {
  final int id;
  final String itemType;
  final String name;
  final double price;
  final int quantity;
  final String? imei;
  final String? notes;
  final String? replyCode;
  final int? productId;
  final int? serviceId;

  const OnlineOrderItem({
    required this.id,
    required this.itemType,
    required this.name,
    required this.price,
    required this.quantity,
    this.imei,
    this.notes,
    this.replyCode,
    this.productId,
    this.serviceId,
  });

  factory OnlineOrderItem.fromJson(Map<String, dynamic> json) => OnlineOrderItem(
        id: json['id'] as int,
        itemType: json['item_type'] as String,
        name: json['name'] as String,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        imei: json['imei'] as String?,
        notes: json['notes'] as String?,
        replyCode: json['reply_code'] as String?,
        productId: json['product_id'] as int?,
        serviceId: json['service_id'] as int?,
      );

  bool get needsServiceCode => itemType == 'service' && (replyCode == null || replyCode!.isEmpty);
}

class OnlineOrderDetail {
  final int id;
  final String orderNumber;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? shippingAddress;
  final double subtotal;
  final double shippingCost;
  final double taxAmount;
  final double totalAmount;
  final String? paymentMethod;
  final String? paymentProof;
  final String paymentStatus;
  final String fulfillmentStatus;
  final String? createdAt;
  final List<OnlineOrderItem> items;

  const OnlineOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.shippingAddress,
    required this.subtotal,
    required this.shippingCost,
    required this.taxAmount,
    required this.totalAmount,
    this.paymentMethod,
    this.paymentProof,
    required this.paymentStatus,
    required this.fulfillmentStatus,
    this.createdAt,
    required this.items,
  });

  factory OnlineOrderDetail.fromJson(Map<String, dynamic> json) => OnlineOrderDetail(
        id: json['id'] as int,
        orderNumber: json['order_number'] as String,
        customerName: json['customer_name'] as String,
        customerEmail: json['customer_email'] as String?,
        customerPhone: json['customer_phone'] as String?,
        shippingAddress: json['shipping_address'] as String?,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0,
        taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        paymentMethod: json['payment_method'] as String?,
        paymentProof: json['payment_proof'] as String?,
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        fulfillmentStatus: json['fulfillment_status'] as String? ?? 'unfulfilled',
        createdAt: json['created_at'] as String?,
        items: (json['items'] as List? ?? [])
            .map((i) => OnlineOrderItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class OnlineOrderPage {
  final List<OnlineOrderSummary> orders;
  final int total;
  final int page;
  final Map<String, int> counts;

  const OnlineOrderPage({
    required this.orders,
    required this.total,
    required this.page,
    required this.counts,
  });
}
