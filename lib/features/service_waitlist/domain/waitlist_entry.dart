class WaitlistEntry {
  const WaitlistEntry({
    required this.id,
    required this.customerId,
    required this.neededType,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.customerPhone,
    this.neededService,
    this.productId,
    this.productName,
    this.imeiSn,
    this.osVersion,
    this.customData,
    this.availableForSale = false,
  });

  final int id;
  final int customerId;
  final String neededType;
  final String status;
  final DateTime createdAt;
  final String? customerName;
  final String? customerPhone;
  final String? neededService;
  final int? productId;
  final String? productName;
  final String? imeiSn;
  final String? osVersion;
  final String? customData;
  final bool availableForSale;

  String get displayName => neededService ?? productName ?? customData ?? '—';

  factory WaitlistEntry.fromJson(Map<String, dynamic> j) => WaitlistEntry(
        id: j['id'] as int,
        customerId: j['customer_id'] as int? ?? 0,
        customerName: j['customer_name'] as String?,
        customerPhone: j['customer_phone'] as String?,
        neededType: j['needed_type'] as String? ?? 'custom',
        neededService: j['needed_service'] as String?,
        productId: j['product_id'] as int?,
        productName: j['product_name'] as String?,
        imeiSn: j['imei_sn'] as String?,
        osVersion: j['os_version'] as String?,
        customData: j['custom_data'] as String?,
        availableForSale: j['available_for_sale'] == true || j['available_for_sale'] == 1,
        status: j['status'] as String? ?? 'pending',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

class WaitlistPage {
  const WaitlistPage({
    required this.entries,
    required this.counts,
    required this.lastPage,
    required this.total,
  });

  final List<WaitlistEntry> entries;
  final Map<String, int> counts;
  final int lastPage;
  final int total;
}
