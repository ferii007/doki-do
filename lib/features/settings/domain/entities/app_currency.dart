import 'package:intl/intl.dart';

enum AppCurrency {
  idr(
    code: 'IDR',
    label: 'Rupiah',
    symbol: 'Rp ',
    locale: 'id_ID',
    decimalDigits: 0,
  ),
  usd(
    code: 'USD',
    label: 'US Dollar',
    symbol: r'$',
    locale: 'en_US',
    decimalDigits: 2,
  );

  final String code;
  final String label;
  final String symbol;
  final String locale;
  final int decimalDigits;

  const AppCurrency({
    required this.code,
    required this.label,
    required this.symbol,
    required this.locale,
    required this.decimalDigits,
  });

  String format(int amount) {
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  static AppCurrency byCode(String code) {
    return values.firstWhere(
      (currency) => currency.code == code,
      orElse: () => AppCurrency.idr,
    );
  }
}
