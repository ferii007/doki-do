import 'budget_period.dart';
import 'category_adjustment.dart';
import 'category_budget.dart';
import 'transaction_item.dart';
import 'transaction_type.dart';

class BudgetSnapshot {
  final BudgetPeriod period;
  final List<CategoryBudget> categories;
  final List<TransactionItem> transactions;
  final List<CategoryAdjustment> categoryAdjustments;

  const BudgetSnapshot({
    required this.period,
    required this.categories,
    required this.transactions,
    required this.categoryAdjustments,
  });

  factory BudgetSnapshot.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    return BudgetSnapshot(
      period: BudgetPeriod.fromJson(data),
      categories: (data['categories'] as List)
          .map((item) => CategoryBudget.fromJson(item as Map<String, dynamic>))
          .toList(),
      transactions: (data['transactions'] as List)
          .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      categoryAdjustments: (data['category_adjustments'] as List? ?? [])
          .map(
            (item) => CategoryAdjustment.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  int get totalExpense {
    return transactions
        .where((item) => item.type == TransactionType.expense)
        .fold<int>(0, (total, item) => total + item.amount);
  }

  int get totalIncomeFromTransactions {
    return transactions
        .where((item) => item.type == TransactionType.income)
        .fold<int>(0, (total, item) => total + item.amount);
  }
}
