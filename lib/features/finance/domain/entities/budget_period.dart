class BudgetPeriod {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final int totalIncome;
  final int totalAllocatable;
  final bool allocationsFollowIncome;

  const BudgetPeriod({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalAllocatable,
    required this.allocationsFollowIncome,
  });

  factory BudgetPeriod.fromJson(Map<String, dynamic> json) {
    final categories = json['categories'];
    final inferredAllocationsFollowIncome =
        categories is List &&
        categories.whereType<Map<String, dynamic>>().any(
          (category) => category.containsKey('allocation_percent'),
        );

    return BudgetPeriod(
      id: json['period_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalIncome: json['total_income'] as int,
      totalAllocatable: json['total_allocatable'] as int,
      allocationsFollowIncome:
          json['allocations_follow_income'] as bool? ??
          inferredAllocationsFollowIncome,
    );
  }
}
