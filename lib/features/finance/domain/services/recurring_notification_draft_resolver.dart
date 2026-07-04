import '../entities/recurring_due_item.dart';
import '../entities/recurring_occurrence.dart';
import '../entities/transaction_template.dart';

class RecurringNotificationDraftResolver {
  const RecurringNotificationDraftResolver._();

  static RecurringTransactionDraft? resolve({
    required String templateId,
    required DateTime dueDate,
    required List<TransactionTemplate> templates,
    required List<RecurringOccurrence> occurrences,
  }) {
    final key = occurrenceKey(templateId, dueDate);
    if (occurrences.any((item) => item.key == key)) return null;

    for (final template in templates) {
      if (template.id != templateId ||
          !template.isRecurring ||
          !template.isActive ||
          !template.reminderEnabled) {
        continue;
      }

      final normalizedDueDate = _dateOnly(dueDate);
      if (normalizedDueDate.isBefore(_dateOnly(template.activeFromDate)) ||
          (template.endDate != null &&
              normalizedDueDate.isAfter(_dateOnly(template.endDate!)))) {
        return null;
      }

      return RecurringTransactionDraft(
        template: template,
        dueDate: normalizedDueDate,
      );
    }
    return null;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
