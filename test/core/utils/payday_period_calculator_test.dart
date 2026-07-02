import 'package:flutter_test/flutter_test.dart';
import 'package:doki_do/core/utils/payday_period_calculator.dart';

void main() {
  test('date on payday starts a new period', () {
    final period = PaydayPeriodCalculator.currentPeriod(
      date: DateTime(2026, 5, 22),
      payday: 22,
    );

    expect(period.startDate, DateTime(2026, 5, 22));
    expect(period.endDate, DateTime(2026, 6, 21));
  });

  test('date before payday belongs to previous period', () {
    final period = PaydayPeriodCalculator.currentPeriod(
      date: DateTime(2026, 6, 21),
      payday: 22,
    );

    expect(period.startDate, DateTime(2026, 5, 22));
    expect(period.endDate, DateTime(2026, 6, 21));
  });
}
