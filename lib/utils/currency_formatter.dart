import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _pesoFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 0, // change if you want cents
  );

  static String format(num amount) {
    return _pesoFormat.format(amount);
  }
}
