import 'package:intl/intl.dart';

/// Mirrors format_money()'s default (app/helpers.php) for the base currency
/// (PKR, 2 decimals) — Phase 1 doesn't expose currency settings over the
/// API yet, so the symbol is fixed rather than fetched.
final _moneyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);
final _dateFormat = DateFormat('d MMM, h:mm a');
final _dayFormat = DateFormat('d MMM yyyy');

String formatMoney(num? amount) => _moneyFormat.format(amount ?? 0);

String formatDateTime(DateTime? dt) => dt == null ? '-' : _dateFormat.format(dt.toLocal());

String formatDay(DateTime? dt) => dt == null ? '-' : _dayFormat.format(dt.toLocal());

String statusLabel(String status) =>
    status.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
