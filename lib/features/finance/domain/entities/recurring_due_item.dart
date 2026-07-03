import 'transaction_template.dart';

class RecurringDueItem {
  final TransactionTemplate template;
  final DateTime dueDate;
  final bool isOverdue;

  const RecurringDueItem({
    required this.template,
    required this.dueDate,
    required this.isOverdue,
  });
}

class RecurringTransactionDraft {
  final TransactionTemplate template;
  final DateTime dueDate;

  const RecurringTransactionDraft({
    required this.template,
    required this.dueDate,
  });
}
