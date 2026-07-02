import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_controller.dart';
import '../data/pos_repository.dart';
import 'pos_models.dart';

final posRepositoryProvider = Provider<PosRepository>((ref) => PosRepository(ref.watch(dioProvider)));

final posTerminalProvider = FutureProvider.autoDispose<PosTerminalData>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(posRepositoryProvider).terminal();
});

final posProductSearchProvider = FutureProvider.family.autoDispose<List<PosProduct>, String>((ref, q) {
  if (q.isEmpty) return Future.value(const <PosProduct>[]);
  return ref.watch(posRepositoryProvider).productSearch(q);
});

class PosCartState {
  const PosCartState({
    this.items = const [],
    this.customerId,
    this.customerName = '',
    this.customerPhone = '',
    this.discountType = 'fixed',
    this.discountValue = 0,
    this.paymentMethod = 'cash',
    this.note = '',
    this.previousDuesPaid = 0,
    this.isSubmitting = false,
  });

  final List<CartLine> items;
  final int? customerId;
  final String customerName;
  final String customerPhone;
  final String discountType;
  final num discountValue;
  final String paymentMethod;
  final String note;
  final num previousDuesPaid;
  final bool isSubmitting;

  num get subtotal => items.fold<num>(0, (sum, item) => sum + item.total);

  num get discountAmount =>
      discountType == 'percent' ? (subtotal * discountValue / 100) : discountValue;

  num get total => (subtotal - discountAmount).clamp(0, double.infinity);

  num get grandTotal => total + previousDuesPaid;

  PosCartState copyWith({
    List<CartLine>? items,
    int? customerId,
    bool clearCustomer = false,
    String? customerName,
    String? customerPhone,
    String? discountType,
    num? discountValue,
    String? paymentMethod,
    String? note,
    num? previousDuesPaid,
    bool? isSubmitting,
  }) {
    return PosCartState(
      items: items ?? this.items,
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      customerName: clearCustomer ? '' : (customerName ?? this.customerName),
      customerPhone: clearCustomer ? '' : (customerPhone ?? this.customerPhone),
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      previousDuesPaid: clearCustomer ? 0 : (previousDuesPaid ?? this.previousDuesPaid),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Local cart for the POS terminal screen — items live only in memory until
/// checkout (always-online v1, no offline persistence; see plan §Decisions).
class PosCartController extends Notifier<PosCartState> {
  @override
  PosCartState build() => const PosCartState();

  void addProduct(PosProduct product) {
    final items = [...state.items];
    final idx = items.indexWhere((l) => l.product.id == product.id);
    if (idx >= 0) {
      items[idx].qty += 1;
    } else {
      items.add(CartLine(product: product));
    }
    state = state.copyWith(items: items);
  }

  void updateQty(int index, int qty) {
    if (qty < 1) {
      removeAt(index);
      return;
    }
    final items = [...state.items];
    items[index].qty = qty;
    state = state.copyWith(items: items);
  }

  void removeAt(int index) {
    final items = [...state.items]..removeAt(index);
    state = state.copyWith(items: items);
  }

  void setDiscount(String type, num value) {
    state = state.copyWith(discountType: type, discountValue: value);
  }

  void setCustomer({int? id, String name = '', String phone = '', num previousDuesPaid = 0}) {
    state = state.copyWith(customerId: id, customerName: name, customerPhone: phone, previousDuesPaid: previousDuesPaid);
  }

  void clearCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  void updateItemDiscount(int index, num discount) {
    final items = [...state.items];
    items[index].discount = discount;
    state = state.copyWith(items: items);
  }

  void updateItemImeiSn(int index, String value) {
    final items = [...state.items];
    items[index].imeiSn = value.isEmpty ? null : value;
    state = state.copyWith(items: items);
  }

  void updateItemWarrantyDays(int index, int days) {
    final items = [...state.items];
    items[index].warrantyDays = days;
    state = state.copyWith(items: items);
  }

  void toggleItemField(int index, String field) {
    final items = [...state.items];
    final item = items[index];
    switch (field) {
      case 'discount': item.discountOpen = !item.discountOpen;
      case 'imei': item.imeiOpen = !item.imeiOpen;
      case 'warranty': item.warrantyOpen = !item.warrantyOpen;
    }
    state = state.copyWith(items: items);
  }

  void clear() {
    state = const PosCartState();
  }

  Future<SaleResult> checkout(num paidAmount) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final result = await ref.read(posRepositoryProvider).sale(
            items: state.items,
            customerId: state.customerId,
            customerName: state.customerName,
            customerPhone: state.customerPhone,
            discountType: state.discountType,
            discountValue: state.discountValue,
            paymentMethod: state.paymentMethod,
            paidAmount: paidAmount,
            previousDuesPaid: state.previousDuesPaid,
            note: state.note,
          );
      clear();
      ref.invalidate(posTerminalProvider);
      return result;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> hold() async {
    if (state.items.isEmpty) return;
    await ref.read(posRepositoryProvider).hold(items: state.items, note: state.note);
    clear();
    ref.invalidate(posTerminalProvider);
  }

  void resumeHeld(PosHeldSale held, List<PosProduct> catalog) {
    final items = <CartLine>[];
    for (final raw in held.items) {
      final map = raw as Map<String, dynamic>;
      final productId = map['id'] as int;
      PosProduct? product;
      for (final p in catalog) {
        if (p.id == productId) {
          product = p;
          break;
        }
      }
      if (product == null) continue;
      items.add(CartLine(
        product: product,
        qty: map['qty'] as int? ?? 1,
        price: map['price'] as num?,
        discount: map['disc'] as num? ?? 0,
        warrantyDays: map['warranty'] as int? ?? 0,
        imeiSn: map['imei_sn'] as String?,
      ));
    }
    state = state.copyWith(items: items, note: held.note ?? '');
  }
}

final posCartProvider = NotifierProvider<PosCartController, PosCartState>(PosCartController.new);
