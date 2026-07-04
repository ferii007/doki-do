import 'package:doki_do/features/finance/domain/entities/recurring_occurrence.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_template.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_type.dart';
import 'package:doki_do/features/finance/domain/services/recurring_notification_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not schedule an occurrence that was completed', () {
    final template = _template();
    final schedules = RecurringNotificationPlanner.build(
      templates: [template],
      occurrences: [
        RecurringOccurrence(
          templateId: template.id,
          dueDate: DateTime(2026, 7, 5),
          status: RecurringOccurrenceStatus.completed,
          processedAt: DateTime(2026, 7, 4),
          transactionId: 'transaction-1',
        ),
      ],
      now: DateTime(2026, 7, 4, 10),
    );

    expect(schedules, isNotEmpty);
    expect(schedules.first.dueDate, DateTime(2026, 8, 5));
    expect(
      schedules.any((item) => item.dueDate == DateTime(2026, 7, 5)),
      isFalse,
    );
  });

  test('does not schedule an occurrence that was skipped', () {
    final template = _template();
    final schedules = RecurringNotificationPlanner.build(
      templates: [template],
      occurrences: [
        RecurringOccurrence(
          templateId: template.id,
          dueDate: DateTime(2026, 7, 5),
          status: RecurringOccurrenceStatus.skipped,
          processedAt: DateTime(2026, 7, 4),
        ),
      ],
      now: DateTime(2026, 7, 4, 10),
    );

    expect(
      schedules.any((item) => item.dueDate == DateTime(2026, 7, 5)),
      isFalse,
    );
    expect(schedules.first.dueDate, DateTime(2026, 8, 5));
  });

  test('honors inactive reminders and the platform schedule limit', () {
    final schedules = RecurringNotificationPlanner.build(
      templates: [
        _template(id: 'active'),
        _template(id: 'paused', isActive: false),
      ],
      occurrences: const [],
      now: DateTime(2026, 7, 4, 10),
      maximumSchedules: 3,
    );

    expect(schedules, hasLength(3));
    expect(schedules.map((item) => item.template.id), everyElement('active'));
  });
}

TransactionTemplate _template({
  String id = 'template-1',
  bool isActive = true,
}) {
  return TransactionTemplate(
    id: id,
    title: 'Internet Rumah',
    amount: 300000,
    type: TransactionType.expense,
    createdAt: DateTime(2026, 7),
    isActive: isActive,
    activeFromDate: DateTime(2026, 7),
    reminderEnabled: true,
    reminderHour: 9,
    reminderMinute: 0,
    preferredCategoryName: 'Kebutuhan Harian',
    dayOfMonth: 5,
  );
}
