import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/gsm_order.dart';

class GsmOrderListPage {
  const GsmOrderListPage({required this.orders, required this.page, required this.lastPage, required this.total});

  final List<GsmOrderSummary> orders;
  final int page;
  final int lastPage;
  final int total;
}

/// Thin wrapper over Api\V1\OrderController — moderation workflow for GSM
/// unlock/IMEI orders (list/show/accept/complete/cancel/reject).
class GsmOrderRepository {
  GsmOrderRepository(this._dio);

  final Dio _dio;

  Future<GsmOrderListPage> list({String status = '', String search = '', int page = 1}) async {
    try {
      final response = await _dio.get('/orders', queryParameters: {
        if (status.isNotEmpty) 'status': status,
        if (search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': 20,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;
      final orders = (data['orders'] as List).map((e) => GsmOrderSummary.fromJson(e as Map<String, dynamic>)).toList();
      return GsmOrderListPage(
        orders: orders,
        page: meta['page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<GsmOrderDetail> show(int id) async {
    try {
      final response = await _dio.get('/orders/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return GsmOrderDetail.fromJson(data['order'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> accept(int id) async {
    try {
      await _dio.post('/orders/$id/accept');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> complete(int id, {String result = ''}) async {
    try {
      await _dio.post('/orders/$id/complete', data: {'result': result});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _dio.post('/orders/$id/cancel');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> reject(int id) async {
    try {
      await _dio.post('/orders/$id/reject');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
