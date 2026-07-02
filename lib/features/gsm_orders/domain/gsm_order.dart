/// Row shape returned by Api\V1\OrderController@index/@show.
class GsmOrderSummary {
  const GsmOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    this.serviceName,
    this.serviceType,
    this.imei,
    this.quantity = 1,
    this.totalPrice = 0,
    this.customerName,
  });

  final int id;
  final String orderNumber;
  final String? serviceName;
  final String? serviceType;
  final String? imei;
  final int quantity;
  final num totalPrice;
  final String status;
  final String? customerName;
  final DateTime createdAt;

  factory GsmOrderSummary.fromJson(Map<String, dynamic> json) {
    return GsmOrderSummary(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String? ?? '',
      serviceName: json['service_name'] as String?,
      serviceType: json['service_type'] as String?,
      imei: json['imei'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      totalPrice: json['total_price'] as num? ?? 0,
      status: json['status'] as String? ?? 'pending',
      customerName: json['customer_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class GsmOrderDetail {
  const GsmOrderDetail({
    required this.summary,
    this.notes,
    this.result,
    this.unitPrice,
    this.username,
    this.sn,
    this.mep,
    this.pin,
    this.prd,
    this.kbh,
    this.reference,
    this.customerEmail,
    this.customerPhone,
    this.completedAt,
  });

  final GsmOrderSummary summary;
  final String? notes;
  final String? result;
  final num? unitPrice;
  final String? username;
  final String? sn;
  final String? mep;
  final String? pin;
  final String? prd;
  final String? kbh;
  final String? reference;
  final String? customerEmail;
  final String? customerPhone;
  final DateTime? completedAt;

  factory GsmOrderDetail.fromJson(Map<String, dynamic> json) {
    return GsmOrderDetail(
      summary: GsmOrderSummary.fromJson(json),
      notes: json['notes'] as String?,
      result: json['result'] as String?,
      unitPrice: json['unit_price'] as num?,
      username: json['username'] as String?,
      sn: json['sn'] as String?,
      mep: json['mep'] as String?,
      pin: json['pin'] as String?,
      prd: json['prd'] as String?,
      kbh: json['kbh'] as String?,
      reference: json['reference'] as String?,
      customerEmail: json['customer_email'] as String?,
      customerPhone: json['customer_phone'] as String?,
      completedAt: json['completed_at'] == null ? null : DateTime.tryParse(json['completed_at'] as String),
    );
  }
}

const gsmOrderStatusOptions = <String>['pending', 'processing', 'completed', 'failed', 'cancelled'];
