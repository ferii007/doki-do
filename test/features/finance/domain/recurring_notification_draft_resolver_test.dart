import 'package:doki_do/features/finance/domain/entities/recurring_occurrence.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_template.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_type.dart';
import 'package:doki_do/features/finance/domain/services/recurring_notification_draft_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurringNotificationDraftResolver', () {
    test('returns the matching active recurring draft', () {
      final template = _template();

      final draft = RecurringNotificationDraftResolver.resolve(
        templateId: template.id,
        dueDate: DateTime(2026, 7, 5, 9),
        templates: [template],
        occurrences: const [],
      );

      expect(draft, isNotNull);
      expect(draft!.template.id, template.id);
      expect(draft.dueDate, DateTime(2026, 7, 5));
    });

    test('rejects a completed or skipped occurrence', () {
      final template = _template();
      for (final status in RecurringOccurrenceStatus.values) {
        final draft = RecurringNotificationDraftResolver.resolve(
          templateId: template.id,
          dueDate: DateTime(2026, 7, 5),
          templates: [template],
          occurrences: [
            RecurringOccurrence(
              templateId: template.id,
              dueDate: DateTime(2026, 7, 5),
              status: status,
              processedAt: DateTime(2026, 7, 5),
            ),
          ],
        );

        expect(draft, isNull);
      }
    });

    test('rejects inactive, disabled, or out-of-range schedules', () {
      final variants = [
        _template(isActive: false),
        _template(reminderEnabled: false),
        _template(activeFromDate: DateTime(2026, 8)),
        _template(endDate: DateTime(2026, 6, 30)),
      ];

      for (final template in variants) {
        final draft = RecurringNotificationDraftResolver.resolve(
          templateId: template.id,
          dueDate: DateTime(2026, 7, 5),
          templates: [template],
          occurrences: const [],
        );

        expect(draft, isNull);
      }
    });
  });
}

TransactionTemplate _template({
  bool isActive = true,
  bool reminderEnabled = true,
  DateTime? activeFromDate,
  DateTime? endDate,
}) {
  return TransactionTemplate(
    id: 'template-1',
    title: 'Internet Rumah',
    amount: 300000,
    type: TransactionType.expense,
    createdAt: DateTime(2026),
    isActive: isActive,
    activeFromDate: activeFromDate ?? DateTime(2026),
    endDate: endDate,
    reminderEnabled: reminderEnabled,
    reminderHour: 9,
    reminderMinute: 0,
    preferredCategoryName: 'Kebutuhan Harian',
    dayOfMonth: 5,
  );
}
