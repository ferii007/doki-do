enum CategoryAdjustmentType { increase, decrease, setAmount }

class CategoryAdjustment {
  final String id;
  final String categoryId;
  final String? relatedCategoryId;
  final CategoryAdjustmentType type;
  final int amount;
  final int deltaAmount;
  final int previousAmount;
  final int newAmount;
  final String reason;
  final DateTime date;

  const CategoryAdjustment({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.deltaAmount,
    required this.previousAmount,
    required this.newAmount,
    required this.reason,
    required this.date,
    this.relatedCategoryId,
  });

  factory CategoryAdjustment.fromJson(Map<String, dynamic> json) {
    return CategoryAdjustment(
      id: json['adjustment_id'] as String,
      categoryId: json['category_id'] as String,
      relatedCategoryId: json['related_category_id'] as String?,
      type: _typeFromJson(json['type'] as String?),
      amount: json['amount'] as int,
      deltaAmount: json['delta_amount'] as int,
      previousAmount: json['previous_amount'] as int,
      newAmount: json['new_amount'] as int,
      reason: json['reason'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  static CategoryAdjustmentType _typeFromJson(String? value) {
    switch (value) {
      case 'increase':
        return CategoryAdjustmentType.increase;
      case 'decrease':
        return CategoryAdjustmentType.decrease;
      case 'set':
        return CategoryAdjustmentType.setAmount;
      default:
        return CategoryAdjustmentType.increase;
    }
  }
}
