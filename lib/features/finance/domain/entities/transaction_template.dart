import 'transaction_type.dart';

class TransactionTemplate {
  final String id;
  final String title;
  final int amount;
  final TransactionType type;
  final String? preferredCategoryName;
  final int? dayOfMonth;
  final DateTime createdAt;

  const TransactionTemplate({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.preferredCategoryName,
    this.dayOfMonth,
  });

  bool get isRecurring => dayOfMonth != null;

  factory TransactionTemplate.fromJson(Map<String, dynamic> json) {
    return TransactionTemplate(
      id: json['transaction_template_id'] as String,
      title: json['title'] as String,
      amount: json['amount'] as int,
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      preferredCategoryName: json['preferred_category_name'] as String?,
      dayOfMonth: json['day_of_month'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
