import '../../features/settings/domain/entities/app_currency.dart';

class CurrencyFormatterPreference {
  static AppCurrency current = AppCurrency.idr;
}

class FinancialPrivacyPreference {
  static bool hideAmounts = false;
}

class RupiahFormatter {
  static String format(int value) {
    if (FinancialPrivacyPreference.hideAmounts) {
      return '${CurrencyFormatterPreference.current.symbol.trim()} ••••••';
    }
    return CurrencyFormatterPreference.current.format(value);
  }
}
