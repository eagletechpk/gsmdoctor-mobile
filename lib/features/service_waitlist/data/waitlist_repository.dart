import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/waitlist_entry.dart';

class WaitlistRepository {
  WaitlistRepository(this._dio);
  final Dio _dio;

  Future<WaitlistPage> list({int page = 1, String search = '', String status = ''}) async {
    try {
      final r = await _dio.get('/service-waitlist', queryParameters: {
        'page': page,
        'per_page': 20,
        if (search.isNotEmpty) 'search': search,
        if (status.isNotEmpty) 'status': status,
      });
      final data = r.data['data'] as Map<String, dynamic>;
      final meta = r.data['meta'] as Map<String, dynamic>;
      final counts = (data['counts'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));
      return WaitlistPage(
        entries: (data['entries'] as List)
            .map((e) => WaitlistEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        counts: counts,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<WaitlistEntry> store({
    required String name,
    required String phone,
    required String neededType,
    String? neededService,
    String? imeiSn,
    String? osVersion,
    String? customData,
    bool availableForSale = false,
  }) async {
    try {
      final r = await _dio.post('/service-waitlist', data: {
        'name': name,
        'phone': phone,
        'needed_type': neededType,
        if (neededService != null && neededService.isNotEmpty) 'needed_service': neededService,
        if (imeiSn != null && imeiSn.isNotEmpty) 'imei_sn': imeiSn,
        if (osVersion != null && osVersion.isNotEmpty) 'os_version': osVersion,
        if (customData != null && customData.isNotEmpty) 'custom_data': customData,
        'available_for_sale': availableForSale,
      });
      return WaitlistEntry.fromJson(
          (r.data['data'] as Map<String, dynamic>)['entry'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await _dio.post('/service-waitlist/$id/status', data: {'status': status});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/service-waitlist/$id');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
