import '../entities/recurring_due_item.dart';
import '../entities/recurring_occurrence.dart';
import '../entities/transaction_template.dart';

class MonthlyRecurrenceCalculator {
  const MonthlyRecurrenceCalculator._();

  static DateTime dueDateForMonth({
    required int year,
    required int month,
    required int preferredDay,
  }) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, preferredDay.clamp(1, lastDay));
  }

  static List<RecurringDueItem> pendingItems({
    required List<TransactionTemplate> templates,
    required List<RecurringOccurrence> occurrences,
    required DateTime today,
  }) {
    final normalizedToday = _dateOnly(today);
    final processedKeys = occurrences.map((item) => item.key).toSet();
    final items = <RecurringDueItem>[];

    for (final template in templates) {
      final day = template.dayOfMonth;
      if (!template.isRecurring || !template.isActive || day == null) continue;

      final start = _dateOnly(template.activeFromDate);
      final end = template.endDate == null
          ? normalizedToday
          : _dateOnly(template.endDate!);
      final effectiveEnd = end.isBefore(normalizedToday)
          ? end
          : normalizedToday;
      if (effectiveEnd.isBefore(start)) continue;

      var cursor = DateTime(start.year, start.month);
      final lastMonth = DateTime(effectiveEnd.year, effectiveEnd.month);
      while (!cursor.isAfter(lastMonth)) {
        final dueDate = dueDateForMonth(
          year: cursor.year,
          month: cursor.month,
          preferredDay: day,
        );
        if (!dueDate.isBefore(start) &&
            !dueDate.isAfter(effectiveEnd) &&
            !processedKeys.contains(occurrenceKey(template.id, dueDate))) {
          items.add(
            RecurringDueItem(
              template: template,
              dueDate: dueDate,
              isOverdue: dueDate.isBefore(normalizedToday),
            ),
          );
        }
        cursor = DateTime(cursor.year, cursor.month + 1);
      }
    }

    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items;
  }

  static DateTime? nextFutureDueDate({
    required TransactionTemplate template,
    required DateTime now,
  }) {
    final day = template.dayOfMonth;
    if (!template.isRecurring ||
        !template.isActive ||
        !template.reminderEnabled ||
        day == null) {
      return null;
    }

    final start = _dateOnly(template.activeFromDate);
    var cursor = DateTime(now.year, now.month);
    for (var attempts = 0; attempts < 240; attempts++) {
      final date = dueDateForMonth(
        year: cursor.year,
        month: cursor.month,
        preferredDay: day,
      );
      final scheduled = DateTime(
        date.year,
        date.month,
        date.day,
        template.reminderHour,
        template.reminderMinute,
      );
      final afterStart = !date.isBefore(start);
      final beforeEnd =
          template.endDate == null ||
          !date.isAfter(_dateOnly(template.endDate!));
      if (afterStart && beforeEnd && scheduled.isAfter(now)) {
        return scheduled;
      }
      if (!beforeEnd) return null;
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return null;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
