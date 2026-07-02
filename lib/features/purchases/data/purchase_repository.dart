import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/purchase.dart';

class PurchaseListPage {
  const PurchaseListPage({required this.purchaseOrders, required this.page, required this.lastPage, required this.total});

  final List<PurchaseOrderSummary> purchaseOrders;
  final int page;
  final int lastPage;
  final int total;
}

/// Thin wrapper over Api\V1\PurchaseController — list, create, status
/// update, and add-payment for purchase orders.
class PurchaseRepository {
  PurchaseRepository(this._dio);

  final Dio _dio;

  Future<PurchaseListPage> list({String search = '', String status = '', int page = 1}) async {
    try {
      final response = await _dio.get('/purchases', queryParameters: {
        if (search.isNotEmpty) 'search': search,
        if (status.isNotEmpty) 'status': status,
        'page': page,
        'per_page': 20,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;
      final pos =
          (data['purchase_orders'] as List).map((e) => PurchaseOrderSummary.fromJson(e as Map<String, dynamic>)).toList();
      return PurchaseListPage(
        purchaseOrders: pos,
        page: meta['page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<PurchaseFormData> formData() async {
    try {
      final response = await _dio.get('/purchases/form-data');
      return PurchaseFormData.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<PurchaseOrderDetail> show(int id) async {
    try {
      final response = await _dio.get('/purchases/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return PurchaseOrderDetail.fromJson(data['purchase_order'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<PurchaseOrderDetail> create({
    required int supplierId,
    required String status,
    required List<NewPurchaseItem> items,
    required num paidAmount,
    int? accountId,
    num cargoCharges = 0,
    String notes = '',
  }) async {
    try {
      final response = await _dio.post('/purchases', data: {
        'supplier_id': supplierId,
        'status': status,
        'items': jsonEncode(items.map((e) => e.toJson()).toList()),
        'paid_amount': paidAmount,
        'account_id': ?accountId,
        'cargo_charges': cargoCharges,
        'notes': notes,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return PurchaseOrderDetail.fromJson(data['purchase_order'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> updateStatus(int id, {required String status, String notes = ''}) async {
    try {
      await _dio.post('/purchases/$id/status', data: {'status': status, 'notes': notes});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> addPayment(int id, {required num amount, required int accountId, String note = ''}) async {
    try {
      await _dio.post('/purchases/$id/payment', data: {
        'amount': amount,
        'account_id': accountId,
        if (note.isNotEmpty) 'note': note,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
