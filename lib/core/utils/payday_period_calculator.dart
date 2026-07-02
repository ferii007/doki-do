class PaydayPeriod {
  final DateTime startDate;
  final DateTime endDate;

  const PaydayPeriod({required this.startDate, required this.endDate});
}

class PaydayPeriodCalculator {
  static PaydayPeriod currentPeriod({
    required DateTime date,
    required int payday,
  }) {
    final normalized = DateTime(date.year, date.month, date.day);
    final startsThisMonth = normalized.day >= payday;
    final rawStartMonth = startsThisMonth
        ? normalized.month
        : normalized.month - 1;
    final startYear = rawStartMonth == 0
        ? normalized.year - 1
        : normalized.year;
    final startMonth = rawStartMonth == 0 ? 12 : rawStartMonth;
    final startDate = DateTime(startYear, startMonth, payday);
    final nextStartDate = DateTime(startDate.year, startDate.month + 1, payday);
    final endDate = nextStartDate.subtract(const Duration(days: 1));

    return PaydayPeriod(startDate: startDate, endDate: endDate);
  }
}
