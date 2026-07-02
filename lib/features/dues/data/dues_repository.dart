import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/due.dart';

class DuesListPage {
  const DuesListPage({
    required this.customers,
    required this.totalOutstanding,
    required this.overdue,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  final List<DueCustomerRow> customers;
  final num totalOutstanding;
  final List<OverdueRow> overdue;
  final int page;
  final int lastPage;
  final int total;
}

/// Thin wrapper over Api\V1\DuesController — outstanding dues list +
/// customer ledger detail + snooze.
class DuesRepository {
  DuesRepository(this._dio);

  final Dio _dio;

  Future<DuesListPage> list({int page = 1}) async {
    try {
      final response = await _dio.get('/dues', queryParameters: {'page': page, 'per_page': 20});
      final data = response.data['data'] as Map<String, dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;
      return DuesListPage(
        customers: (data['customers'] as List).map((e) => DueCustomerRow.fromJson(e as Map<String, dynamic>)).toList(),
        totalOutstanding: num.tryParse(data['total_outstanding'].toString()) ?? 0,
        overdue: (data['overdue'] as List).map((e) => OverdueRow.fromJson(e as Map<String, dynamic>)).toList(),
        page: meta['page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<DueCustomerDetail> show(int id) async {
    try {
      final response = await _dio.get('/dues/$id');
      return DueCustomerDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<String> snooze(int id, {required int days, String note = ''}) async {
    try {
      final response = await _dio.post('/dues/$id/snooze', data: {
        'days': days,
        if (note.isNotEmpty) 'note': note,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return data['snoozed_until'] as String;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
