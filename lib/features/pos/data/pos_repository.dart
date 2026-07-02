import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/pos_models.dart';

/// Thin wrapper over Api\V1\PosController — terminal bootstrap data, product
/// search, sale submission, held sales, and quick-add product.
class PosRepository {
  PosRepository(this._dio);

  final Dio _dio;

  Future<PosTerminalData> terminal() async {
    try {
      final response = await _dio.get('/pos/terminal');
      return PosTerminalData.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<PosProduct>> productSearch(String q) async {
    try {
      final response = await _dio.get('/pos/products/search', queryParameters: {'q': q});
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['products'] as List).map((e) => PosProduct.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<SaleResult> sale({
    required List<CartLine> items,
    int? customerId,
    String customerName = '',
    String customerPhone = '',
    String discountType = 'fixed',
    num discountValue = 0,
    String paymentMethod = 'cash',
    required num paidAmount,
    num previousDuesPaid = 0,
    String note = '',
  }) async {
    try {
      final response = await _dio.post('/pos/sale', data: {
        'items': jsonEncode(items.map((e) => e.toJson()).toList()),
        'customer_id': ?customerId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'discount_type': discountType,
        'discount_value': discountValue,
        'payment_method': paymentMethod,
        'paid_amount': paidAmount,
        'previous_dues_paid': previousDuesPaid,
        'note': note,
      });
      return SaleResult.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<PosHeldSale> hold({required List<CartLine> items, String note = ''}) async {
    try {
      final response = await _dio.post('/pos/held', data: {
        'items': jsonEncode(items.map((e) => e.toJson()).toList()),
        if (note.isNotEmpty) 'note': note,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return PosHeldSale.fromJson(data['held_sale'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<PosHeldSale>> getHeld() async {
    try {
      final response = await _dio.get('/pos/held');
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['held_sales'] as List).map((e) => PosHeldSale.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> deleteHeld(int id) async {
    try {
      await _dio.delete('/pos/held/$id');
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<Map<String, dynamic>>> salesList({String? from, String? to, String q = ''}) async {
    try {
      final response = await _dio.get('/pos/sales', queryParameters: {
        'from': from,
        'to': to,
        if (q.isNotEmpty) 'q': q,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['sales'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<int>> invoicePdf(int saleId) async {
    try {
      final response = await _dio.get(
        '/pos/invoice/$saleId',
        options: Options(responseType: ResponseType.bytes),
      );
      return (response.data as List).cast<int>();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<PosProduct> quickAddProduct({
    required String name,
    required num sellPrice,
    String? sku,
    String? barcode,
    num? costPrice,
    int? categoryId,
    int stockQty = 10,
  }) async {
    try {
      final response = await _dio.post('/pos/products/quick-add', data: {
        'name': name,
        'sell_price': sellPrice,
        if (sku != null && sku.isNotEmpty) 'sku': sku,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        'cost_price': ?costPrice,
        'category_id': ?categoryId,
        'stock_qty': stockQty,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      return PosProduct.fromJson(data['product'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
