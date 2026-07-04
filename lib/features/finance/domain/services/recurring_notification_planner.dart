import '../entities/recurring_occurrence.dart';
import '../entities/transaction_template.dart';
import 'monthly_recurrence_calculator.dart';

class RecurringNotificationSchedule {
  final TransactionTemplate template;
  final DateTime dueDate;
  final DateTime scheduledAt;

  const RecurringNotificationSchedule({
    required this.template,
    required this.dueDate,
    required this.scheduledAt,
  });
}

class RecurringNotificationPlanner {
  const RecurringNotificationPlanner._();

  static List<RecurringNotificationSchedule> build({
    required List<TransactionTemplate> templates,
    required List<RecurringOccurrence> occurrences,
    required DateTime now,
    int maximumSchedules = 48,
  }) {
    final processedKeys = occurrences.map((item) => item.key).toSet();
    final schedules = <RecurringNotificationSchedule>[];

    for (final template in templates) {
      final preferredDay = template.dayOfMonth;
      if (!template.isRecurring ||
          !template.isActive ||
          !template.reminderEnabled ||
          preferredDay == null) {
        continue;
      }

      var month = DateTime(now.year, now.month);
      for (var index = 0; index < 24; index++) {
        final dueDate = MonthlyRecurrenceCalculator.dueDateForMonth(
          year: month.year,
          month: month.month,
          preferredDay: preferredDay,
        );
        final scheduledAt = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          template.reminderHour,
          template.reminderMinute,
        );
        final withinActiveRange =
            !dueDate.isBefore(_dateOnly(template.activeFromDate)) &&
            (template.endDate == null ||
                !dueDate.isAfter(_dateOnly(template.endDate!)));
        final processed = processedKeys.contains(
          occurrenceKey(template.id, dueDate),
        );

        if (withinActiveRange && !processed && scheduledAt.isAfter(now)) {
          schedules.add(
            RecurringNotificationSchedule(
              template: template,
              dueDate: dueDate,
              scheduledAt: scheduledAt,
            ),
          );
        }

        if (template.endDate != null &&
            month.isAfter(
              DateTime(template.endDate!.year, template.endDate!.month),
            )) {
          break;
        }
        month = DateTime(month.year, month.month + 1);
      }
    }

    schedules.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return schedules.take(maximumSchedules).toList();
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
