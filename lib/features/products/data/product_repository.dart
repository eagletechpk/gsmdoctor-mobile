import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/product.dart';

class ProductListPage {
  const ProductListPage({required this.products, required this.page, required this.lastPage, required this.total});

  final List<ProductSummary> products;
  final int page;
  final int lastPage;
  final int total;
}

/// Thin wrapper over Api\V1\ProductController — read-heavy inventory
/// browsing + quick stock adjustment.
class ProductRepository {
  ProductRepository(this._dio);

  final Dio _dio;

  Future<ProductListPage> list({
    String search = '',
    int? categoryId,
    bool lowStockOnly = false,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get('/products', queryParameters: {
        if (search.isNotEmpty) 'search': search,
        'category': ?categoryId,
        if (lowStockOnly) 'low_stock': 1,
        'page': page,
        'per_page': 20,
      });
      final data = response.data['data'] as Map<String, dynamic>;
      final meta = response.data['meta'] as Map<String, dynamic>;
      final products = (data['products'] as List).map((e) => ProductSummary.fromJson(e as Map<String, dynamic>)).toList();
      return ProductListPage(
        products: products,
        page: meta['page'] as int,
        lastPage: meta['last_page'] as int,
        total: meta['total'] as int,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<ProductCategoryOption>> categories() async {
    try {
      final response = await _dio.get('/products/categories');
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['categories'] as List).map((e) => ProductCategoryOption.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<ProductDetail> show(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      return ProductDetail.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> adjustStock(int id, {required int qty, String note = ''}) async {
    try {
      await _dio.post('/products/$id/adjust-stock', data: {
        'qty': qty,
        if (note.isNotEmpty) 'note': note,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
