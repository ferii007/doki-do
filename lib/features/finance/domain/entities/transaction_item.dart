import 'transaction_type.dart';

class TransactionItem {
  final String id;
  final String? categoryId;
  final String title;
  final int amount;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TransactionType type;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? date,
       updatedAt = updatedAt ?? createdAt ?? date;

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    return TransactionItem(
      id: json['transaction_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      amount: json['amount'] as int,
      date: date,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? date,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          date,
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
    );
  }
}
