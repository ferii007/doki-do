import 'package:intl/intl.dart';

enum AppCurrency {
  idr(
    code: 'IDR',
    labelKey: 'currency_idr',
    symbol: 'Rp ',
    locale: 'id_ID',
    decimalDigits: 0,
  );
  // USD dinonaktifkan sementara sampai dukungan multi-currency siap.
  // usd(
  //   code: 'USD',
  //   labelKey: 'currency_usd',
  //   symbol: r'$',
  //   locale: 'en_US',
  //   decimalDigits: 2,
  // );

  final String code;
  final String labelKey;
  final String symbol;
  final String locale;
  final int decimalDigits;

  const AppCurrency({
    required this.code,
    required this.labelKey,
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
