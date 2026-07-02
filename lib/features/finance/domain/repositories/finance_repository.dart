import '../entities/budget_period.dart';
import '../entities/budget_allocation_draft.dart';
import '../entities/budget_snapshot.dart';
import '../entities/transaction_template.dart';

abstract class FinanceRepository {
  Future<BudgetSnapshot?> getCurrentBudget();

  Future<List<BudgetPeriod>> getBudgetPeriods();

  Future<BudgetSnapshot> getBudgetByPeriodId(String periodId);

  Future<List<TransactionTemplate>> getTransactionTemplates();

  Future<void> saveTransactionTemplate({
    String? templateId,
    required String type,
    required String title,
    required int amount,
    String? preferredCategoryName,
    int? dayOfMonth,
  });

  Future<void> deleteTransactionTemplate(String templateId);

  Future<BudgetPeriod> addBudgetPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required int initialIncome,
    required String incomeSource,
    required List<BudgetAllocationDraft> defaultAllocations,
    required bool allocationsFollowIncome,
    String? carryOverFromPeriodId,
  });

  Future<void> addIncome({
    required String periodId,
    required int amount,
    required String title,
    required DateTime date,
  });

  Future<void> updateIncome({
    required String periodId,
    required String transactionId,
    required int amount,
    required String title,
    required DateTime date,
  });

  Future<void> addExpense({
    required String periodId,
    required String categoryId,
    required int amount,
    required String title,
    required DateTime date,
  });

  Future<void> updateExpense({
    required String periodId,
    required String transactionId,
    required String categoryId,
    required int amount,
    required String title,
    required DateTime date,
  });

  Future<void> deleteTransaction({
    required String periodId,
    required String transactionId,
  });

  Future<void> addCategory({
    required String periodId,
    required String name,
    required int allocatedAmount,
    num? allocationPercent,
  });

  Future<void> updateCategory({
    required String periodId,
    required String categoryId,
    required String name,
  });

  Future<void> adjustCategoryBudget({
    required String periodId,
    required String categoryId,
    required String action,
    required int amount,
    required String reason,
    required DateTime date,
    String? relatedCategoryId,
  });

  Future<void> deleteCategory({
    required String periodId,
    required String categoryId,
  });

  Future<void> updateBudgetPeriod({
    required String periodId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> deleteBudgetPeriod(String periodId);
}
