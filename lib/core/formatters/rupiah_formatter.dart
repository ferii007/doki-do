import '../../features/settings/domain/entities/app_currency.dart';

class CurrencyFormatterPreference {
  static AppCurrency current = AppCurrency.idr;
}

class RupiahFormatter {
  static String format(int value) {
    return CurrencyFormatterPreference.current.format(value);
  }
}
