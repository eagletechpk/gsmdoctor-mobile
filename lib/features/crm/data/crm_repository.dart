import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/crm_customer.dart';

class CrmListPage {
  const CrmListPage({required this.customers, required this.page, required this.lastPage, required this.total});

  final List<CrmCustomerSummary> customers;
  final int page;
  final int lastPage;
  final int total;
}

/// Thin wrapper over Api\V1\CrmController — mirrors CRMController's
/// search/quick-add/collect-due/statement contract.
class CrmRepository {
  CrmRepository(this._dio);

  final Dio _dio;

  Future<CrmListPage> list({String search = '', int page = 1}) async {
    try {
      final response = await _dio.get('/crm', queryParameters: {
        if (search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': 20,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;
      final customers =
          (data['customers'] as List).map((e) => CrmCustomerSummary.fromJson(e as Map<String, dynamic>)).toList();
      return CrmListPage(
        customers: customers,
        page: meta['page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<CrmCustomerDetail> show(int id) async {
    try {
      final response = await _dio.get('/crm/$id');
      return CrmCustomerDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<CrmCustomerSummary>> search(String q) async {
    try {
      final response = await _dio.get('/crm/search', queryParameters: {'q': q});
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['customers'] as List).map((e) => CrmCustomerSummary.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<CrmCustomerSummary> quickAdd({required String name, required String phone, String? city}) async {
    try {
      final response = await _dio.post('/crm/quick-add', data: {
        'name': name,
        'phone': phone,
        if (city != null && city.isNotEmpty) 'city': city,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return CrmCustomerSummary.fromJson(data['customer'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<num> collectDue(int id, double amount) async {
    try {
      final response = await _dio.post('/crm/$id/collect-due', data: {'amount': amount});
      final data = response.data['data'] as Map<String, dynamic>;
      return data['remaining_dues'] as num? ?? 0;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<CrmStatement> statement(int id, {String? from, String? to}) async {
    try {
      final response = await _dio.get('/crm/$id/statement', queryParameters: {
        'from': ?from,
        'to': ?to,
      });
      return CrmStatement.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
