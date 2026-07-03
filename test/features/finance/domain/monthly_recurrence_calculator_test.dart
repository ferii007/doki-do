import 'package:doki_do/features/finance/domain/entities/recurring_occurrence.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_template.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_type.dart';
import 'package:doki_do/features/finance/domain/services/monthly_recurrence_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthlyRecurrenceCalculator', () {
    test('clamps day 31 to the final day of shorter months', () {
      expect(
        MonthlyRecurrenceCalculator.dueDateForMonth(
          year: 2026,
          month: 2,
          preferredDay: 31,
        ),
        DateTime(2026, 2, 28),
      );
      expect(
        MonthlyRecurrenceCalculator.dueDateForMonth(
          year: 2028,
          month: 2,
          preferredDay: 31,
        ),
        DateTime(2028, 2, 29),
      );
    });

    test(
      'returns overdue and current due items but excludes processed months',
      () {
        final template = _template(
          activeFromDate: DateTime(2026, 5),
          dayOfMonth: 5,
        );
        final occurrences = [
          RecurringOccurrence(
            templateId: template.id,
            dueDate: DateTime(2026, 5, 5),
            status: RecurringOccurrenceStatus.completed,
            processedAt: DateTime(2026, 5, 5),
            transactionId: 'transaction-1',
          ),
        ];

        final items = MonthlyRecurrenceCalculator.pendingItems(
          templates: [template],
          occurrences: occurrences,
          today: DateTime(2026, 7, 5, 18),
        );

        expect(items, hasLength(2));
        expect(items.first.dueDate, DateTime(2026, 6, 5));
        expect(items.first.isOverdue, isTrue);
        expect(items.last.dueDate, DateTime(2026, 7, 5));
        expect(items.last.isOverdue, isFalse);
      },
    );

    test('honors pause state and end date', () {
      final paused = _template(
        isActive: false,
        activeFromDate: DateTime(2026, 5),
      );
      final ended = _template(
        id: 'ended',
        activeFromDate: DateTime(2026, 5),
        endDate: DateTime(2026, 6, 30),
      );

      final items = MonthlyRecurrenceCalculator.pendingItems(
        templates: [paused, ended],
        occurrences: const [],
        today: DateTime(2026, 7, 5),
      );

      expect(items.map((item) => item.template.id), everyElement('ended'));
      expect(items.map((item) => item.dueDate.month), [5, 6]);
    });

    test('finds the next future reminder with a clamped date', () {
      final template = _template(
        activeFromDate: DateTime(2026),
        dayOfMonth: 31,
      );

      final next = MonthlyRecurrenceCalculator.nextFutureDueDate(
        template: template,
        now: DateTime(2026, 2, 27, 10),
      );

      expect(next, DateTime(2026, 2, 28, 9));
    });
  });
}

TransactionTemplate _template({
  String id = 'template-1',
  int dayOfMonth = 5,
  bool isActive = true,
  required DateTime activeFromDate,
  DateTime? endDate,
}) {
  return TransactionTemplate(
    id: id,
    title: 'Internet Rumah',
    amount: 300000,
    type: TransactionType.expense,
    createdAt: activeFromDate,
    isActive: isActive,
    activeFromDate: activeFromDate,
    endDate: endDate,
    reminderEnabled: true,
    reminderHour: 9,
    reminderMinute: 0,
    preferredCategoryName: 'Kebutuhan Harian',
    dayOfMonth: dayOfMonth,
  );
}
