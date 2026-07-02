class CategoryBudget {
  final String id;
  final String name;
  final int allocatedAmount;
  final int remainingAmount;
  final double? allocationPercent;

  const CategoryBudget({
    required this.id,
    required this.name,
    required this.allocatedAmount,
    required this.remainingAmount,
    this.allocationPercent,
  });

  factory CategoryBudget.fromJson(Map<String, dynamic> json) {
    return CategoryBudget(
      id: json['category_id'] as String,
      name: json['category_name'] as String,
      allocatedAmount: json['allocated_amount'] as int,
      remainingAmount: json['remaining_amount'] as int,
      allocationPercent: (json['allocation_percent'] as num?)?.toDouble(),
    );
  }

  CategoryBudget copyWith({
    String? id,
    String? name,
    int? allocatedAmount,
    int? remainingAmount,
    double? allocationPercent,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      name: name ?? this.name,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      allocationPercent: allocationPercent ?? this.allocationPercent,
    );
  }
}
