enum RecurringOccurrenceStatus { completed, skipped }

class RecurringOccurrence {
  final String templateId;
  final DateTime dueDate;
  final RecurringOccurrenceStatus status;
  final DateTime processedAt;
  final String? transactionId;

  const RecurringOccurrence({
    required this.templateId,
    required this.dueDate,
    required this.status,
    required this.processedAt,
    this.transactionId,
  });

  String get key => occurrenceKey(templateId, dueDate);

  factory RecurringOccurrence.fromJson(Map<String, dynamic> json) {
    return RecurringOccurrence(
      templateId: json['template_id'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] == 'completed'
          ? RecurringOccurrenceStatus.completed
          : RecurringOccurrenceStatus.skipped,
      processedAt: DateTime.parse(json['processed_at'] as String),
      transactionId: json['transaction_id'] as String?,
    );
  }
}

String occurrenceKey(String templateId, DateTime dueDate) {
  final month = dueDate.month.toString().padLeft(2, '0');
  return '${templateId}_${dueDate.year}_$month';
}
