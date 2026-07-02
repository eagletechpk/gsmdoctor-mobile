import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../domain/settings_data.dart';

class SettingsRepository {
  final Dio _dio;
  SettingsRepository(this._dio);

  Future<SettingsData> getSettings() async {
    try {
      final res = await _dio.get('/settings');
      return SettingsData.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> updateSettings(Map<String, String> values) async {
    try {
      await _dio.post('/settings', data: values);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<CurrencyRow> storeCurrency(
      {required String code, required String name, required String symbol}) async {
    try {
      final res = await _dio.post('/settings/currencies', data: {
        'code': code,
        'name': name,
        'symbol': symbol,
      });
      return CurrencyRow.fromJson(
          res.data['data']['currency'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> updateCurrency(int id, {required String name, required String symbol}) async {
    try {
      await _dio.post('/settings/currencies/$id/update',
          data: {'name': name, 'symbol': symbol});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> toggleCurrency(int id) async {
    try {
      await _dio.post('/settings/currencies/$id/toggle');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> setBaseCurrency(int id) async {
    try {
      await _dio.post('/settings/currencies/$id/set-base');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteCurrency(int id) async {
    try {
      await _dio.delete('/settings/currencies/$id');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
