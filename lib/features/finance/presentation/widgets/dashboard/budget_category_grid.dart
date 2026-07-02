import 'package:flutter/material.dart';

import '../../../domain/entities/category_budget.dart';
import '../../../domain/entities/transaction_item.dart';
import '../../../domain/entities/transaction_type.dart';
import 'budget_category_card.dart';

class BudgetCategoryGrid extends StatelessWidget {
  final List<CategoryBudget> categories;
  final List<TransactionItem> transactions;
  final ValueChanged<CategoryBudget> onCategoryTap;
  final ValueChanged<CategoryBudget> onCategoryEdit;
  final ValueChanged<CategoryBudget> onCategoryIncrease;
  final ValueChanged<CategoryBudget> onCategoryDecrease;
  final ValueChanged<CategoryBudget> onCategorySetAmount;
  final ValueChanged<CategoryBudget> onCategoryDelete;
  final ValueChanged<CategoryBudget> onCategoryDeleteBlocked;
  final bool Function(CategoryBudget category) canDeleteCategory;

  const BudgetCategoryGrid({
    super.key,
    required this.categories,
    required this.transactions,
    required this.onCategoryTap,
    required this.onCategoryEdit,
    required this.onCategoryIncrease,
    required this.onCategoryDecrease,
    required this.onCategorySetAmount,
    required this.onCategoryDelete,
    required this.onCategoryDeleteBlocked,
    required this.canDeleteCategory,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = categories[index];
        final canDelete = canDeleteCategory(category);
        return BudgetCategoryCard(
          category: category,
          transactionCount: transactions
              .where(
                (transaction) =>
                    transaction.type == TransactionType.expense &&
                    transaction.categoryId == category.id,
              )
              .length,
          canDelete: canDelete,
          onTap: () => onCategoryTap(category),
          onEdit: () => onCategoryEdit(category),
          onIncrease: () => onCategoryIncrease(category),
          onDecrease: () => onCategoryDecrease(category),
          onSetAmount: () => onCategorySetAmount(category),
          onDelete: () => canDelete
              ? onCategoryDelete(category)
              : onCategoryDeleteBlocked(category),
        );
      },
    );
  }
}
