import 'package:flutter_test/flutter_test.dart';
import 'package:doki_do/core/formatters/rupiah_formatter.dart';
import 'package:doki_do/features/settings/domain/entities/app_currency.dart';

void main() {
  setUp(() {
    CurrencyFormatterPreference.current = AppCurrency.idr;
    FinancialPrivacyPreference.hideAmounts = false;
  });

  tearDown(() {
    FinancialPrivacyPreference.hideAmounts = false;
  });

  test('formats rupiah with Indonesian thousand separator', () {
    expect(RupiahFormatter.format(100000000), 'Rp 100.000.000');
  });

  test('masks financial amount while privacy mode is enabled', () {
    FinancialPrivacyPreference.hideAmounts = true;

    expect(RupiahFormatter.format(100000000), 'Rp ••••••');
    expect(RupiahFormatter.format(-500000), 'Rp ••••••');
  });
}
