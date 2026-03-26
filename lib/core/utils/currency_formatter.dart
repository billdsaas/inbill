import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static String format(double amount) => _inr.format(amount);
  static String compact(double amount) => _compact.format(amount);
  static String plain(double amount) => amount.toStringAsFixed(2);

  static double parse(String value) {
    final clean = value.replaceAll(RegExp(r'[₹,\s]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
}

class DateFormatter {
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _short = DateFormat('dd/MM/yy');
  static final DateFormat _db = DateFormat('yyyy-MM-dd HH:mm:ss');

  static String formatDate(DateTime dt) => _date.format(dt);
  static String formatDateTime(DateTime dt) => _dateTime.format(dt);
  static String formatShort(DateTime dt) => _short.format(dt);
  static String formatDb(DateTime dt) => _db.format(dt);

  static DateTime? parse(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
}
