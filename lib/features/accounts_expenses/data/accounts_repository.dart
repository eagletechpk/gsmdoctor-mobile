import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/account.dart';

class AccountsRepository {
  AccountsRepository(this._dio);
  final Dio _dio;

  Future<AccountsPageData> getAccounts() async {
    try {
      final r = await _dio.get('/accounts');
      final data = r.data['data'] as Map<String, dynamic>;
      return AccountsPageData(
        accounts: (data['accounts'] as List).map((e) => AccountRow.fromJson(e as Map<String, dynamic>)).toList(),
        recentTransactions: (data['recent_transactions'] as List)
            .map((e) => RecentTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalBalance: data['total_balance'] as num? ?? 0,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> storeTransaction({
    required int accountId,
    required String type,
    required double amount,
    String? category,
    String? note,
  }) async {
    try {
      await _dio.post('/accounts/transaction', data: {
        'account_id': accountId,
        'type': type,
        'amount': amount,
        if (category != null && category.isNotEmpty) 'category': category,
        if (note != null && note.isNotEmpty) 'note': note,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}

class ExpensesRepository {
  ExpensesRepository(this._dio);
  final Dio _dio;

  Future<({List<ExpenseRow> expenses, num totalAmount, int lastPage})> list({
    int page = 1,
    String search = '',
    String category = '',
  }) async {
    try {
      final r = await _dio.get('/expenses', queryParameters: {
        'page': page,
        'per_page': 20,
        if (search.isNotEmpty) 'search': search,
        if (category.isNotEmpty) 'category': category,
      });
      final data = r.data['data'] as Map<String, dynamic>;
      final meta = r.data['meta'] as Map<String, dynamic>;
      return (
        expenses: (data['expenses'] as List).map((e) => ExpenseRow.fromJson(e as Map<String, dynamic>)).toList(),
        totalAmount: data['total_amount'] as num? ?? 0,
        lastPage: meta['last_page'] as int,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<ExpenseFormData> formData() async {
    try {
      final r = await _dio.get('/expenses/form-data');
      final data = r.data['data'] as Map<String, dynamic>;
      return ExpenseFormData(
        accounts: (data['accounts'] as List).map((e) => e as Map<String, dynamic>).toList(),
        categories: (data['categories'] as List).map((e) => e as String).toList(),
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<ExpenseRow> store({
    required String category,
    required double amount,
    required int accountId,
    required String description,
    required String date,
  }) async {
    try {
      final r = await _dio.post('/expenses', data: {
        'category': category,
        'amount': amount,
        'account_id': accountId,
        'description': description,
        'date': date,
      });
      return ExpenseRow.fromJson((r.data['data'] as Map<String, dynamic>)['expense'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
