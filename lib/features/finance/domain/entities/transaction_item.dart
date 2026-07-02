import 'transaction_type.dart';

class TransactionItem {
  final String id;
  final String? categoryId;
  final String title;
  final int amount;
  final DateTime date;
  final TransactionType type;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.categoryId,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['transaction_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      amount: json['amount'] as int,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
    );
  }
}
