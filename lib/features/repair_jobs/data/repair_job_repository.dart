import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/repair_job.dart';

class RepairJobListPage {
  const RepairJobListPage({required this.jobs, required this.page, required this.lastPage, required this.total});

  final List<RepairJobSummary> jobs;
  final int page;
  final int lastPage;
  final int total;
}

/// Thin wrapper over Api\V1\RepairJobController — mirrors RepairController's
/// query params (status/search/flag/sort/dir/page) so filtering behaves
/// identically to the web repair list.
class RepairJobRepository {
  RepairJobRepository(this._dio);

  final Dio _dio;

  Future<RepairJobListPage> list({
    String status = '',
    String search = '',
    int page = 1,
  }) async {
    try {
      final response = await _dio.get('/repair-jobs', queryParameters: {
        if (status.isNotEmpty) 'status': status,
        if (search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': 20,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;
      final jobs = (data['jobs'] as List)
          .map((e) => RepairJobSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      return RepairJobListPage(
        jobs: jobs,
        page: meta['page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<RepairJobDetail> show(int id) async {
    try {
      final response = await _dio.get('/repair-jobs/$id');
      return RepairJobDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> updateStatus(int id, String status, {String note = ''}) async {
    try {
      await _dio.post('/repair-jobs/$id/status', data: {'status': status, 'note': note});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> addNote(int id, String note) async {
    try {
      await _dio.post('/repair-jobs/$id/notes', data: {'note': note});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> setFlag(int id, String flag) async {
    try {
      await _dio.post('/repair-jobs/$id/flag', data: {'flag': flag});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<RepairFormData> formData() async {
    try {
      final response = await _dio.get('/repair-jobs/form-data');
      return RepairFormData.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<RepairJobSummary> store(NewRepairJobState state) async {
    try {
      final response = await _dio.post('/repair-jobs', data: {
        'customer_id': ?state.customerId,
        if (state.customerId == null) 'customer_name': state.customerName,
        if (state.customerId == null) 'customer_phone': state.customerPhone,
        'technician_id': ?state.technicianId,
        'brand_id': ?state.brandId,
        'device_model': state.deviceModel,
        'imei': state.imei,
        'color': state.color,
        'device_condition': ?state.deviceCondition,
        'checklist': state.checklist,
        'device_password': state.devicePassword,
        'reported_issue': state.reportedIssue,
        'priority': state.priority,
        'estimate_cost': state.estimateCost,
        'advance_paid': state.advancePaid,
        'warranty_days': state.warrantyDays,
        'due_date': ?state.dueDate?.toIso8601String().split('T').first,
        'notes': state.notes,
      });
      return RepairJobSummary.fromJson((response.data['data'] as Map<String, dynamic>)['job'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> addPart(int jobId, {required String name, required int qty, required double sellPrice}) async {
    try {
      await _dio.post('/repair-jobs/$jobId/parts', data: {
        'name': name,
        'qty': qty,
        'sell_price': sellPrice,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<int>> labelPdf(int id) => _downloadPdf('/repair-jobs/$id/label');

  Future<List<int>> invoicePdf(int id) => _downloadPdf('/repair-jobs/$id/invoice');

  Future<List<int>> receiptPdf(int id) => _downloadPdf('/repair-jobs/$id/receipt');

  Future<List<int>> _downloadPdf(String path) async {
    try {
      final response = await _dio.get<List<int>>(path, options: Options(responseType: ResponseType.bytes));
      return response.data!;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
