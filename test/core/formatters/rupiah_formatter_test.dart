import 'package:flutter_test/flutter_test.dart';
import 'package:doki_do/core/formatters/rupiah_formatter.dart';

void main() {
  test('formats rupiah with Indonesian thousand separator', () {
    expect(RupiahFormatter.format(100000000), 'Rp 100.000.000');
  });
}
