import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/online_order.dart';

class OnlineOrdersRepository {
  final Dio _dio;
  OnlineOrdersRepository(this._dio);

  Future<OnlineOrderPage> list({
    int page = 1,
    String? search,
    String? paymentStatus,
    String? fulfillmentStatus,
  }) async {
    try {
      final res = await _dio.get('/online-orders', queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (paymentStatus != null) 'payment_status': paymentStatus,
        if (fulfillmentStatus != null) 'fulfillment_status': fulfillmentStatus,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      final meta = res.data['meta'] as Map<String, dynamic>? ?? {};
      final orders = (data['orders'] as List)
          .map((o) => OnlineOrderSummary.fromJson(o as Map<String, dynamic>))
          .toList();
      final counts = Map<String, int>.from(
          (data['counts'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, (v as num).toInt())));
      return OnlineOrderPage(
        orders: orders,
        total: (meta['total'] as num?)?.toInt() ?? orders.length,
        page: page,
        counts: counts,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<OnlineOrderDetail> getOne(int id) async {
    try {
      final res = await _dio.get('/online-orders/$id');
      return OnlineOrderDetail.fromJson(
          res.data['data']['order'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> updatePayment(int id, String status) async {
    try {
      await _dio.post('/online-orders/$id/payment', data: {'payment_status': status});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> updateFulfillment(int id, String status) async {
    try {
      await _dio
          .post('/online-orders/$id/fulfillment', data: {'fulfillment_status': status});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deliverService(int orderId, int itemId, String replyCode) async {
    try {
      await _dio.post('/online-orders/$orderId/deliver/$itemId',
          data: {'reply_code': replyCode});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
