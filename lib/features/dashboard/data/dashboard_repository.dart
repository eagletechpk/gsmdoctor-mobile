import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/dashboard_data.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardData> fetch() async {
    try {
      final response = await _dio.get('/dashboard');
      return DashboardData.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
