import '../../repair_jobs/domain/repair_job.dart';

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalPrice,
    required this.customerName,
    required this.serviceName,
    required this.createdAt,
  });

  final int id;
  final String orderNumber;
  final String status;
  final num totalPrice;
  final String customerName;
  final String serviceName;
  final DateTime createdAt;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? '',
      totalPrice: json['total_price'] as num? ?? 0,
      customerName: json['customer_name'] as String? ?? 'N/A',
      serviceName: json['service_name'] as String? ?? 'N/A',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Raw stat values vary by role (admin sees revenue+repair+dues, staff sees
/// a subset gated by permission, customers see their own order totals) —
/// kept as a dynamic map rather than one rigid model, same as the web
/// dashboard's $stats array.
class DashboardData {
  const DashboardData({
    required this.stats,
    required this.recentOrders,
    required this.periodJobs,
    required this.ordersByStatus,
    required this.ecommerceStats,
  });

  final Map<String, dynamic> stats;
  final List<OrderSummary> recentOrders;
  final List<RepairJobSummary> periodJobs;
  final Map<String, dynamic> ordersByStatus;
  final Map<String, dynamic> ecommerceStats;

  num stat(String key) => (stats[key] as num?) ?? 0;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: (json['stats'] as Map).cast<String, dynamic>(),
      recentOrders: (json['recent_orders'] as List)
          .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      periodJobs: (json['period_jobs'] as List)
          .map((e) => RepairJobSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      ordersByStatus: (json['orders_by_status'] as Map).cast<String, dynamic>(),
      ecommerceStats: (json['ecommerce_stats'] as Map).cast<String, dynamic>(),
    );
  }
}
