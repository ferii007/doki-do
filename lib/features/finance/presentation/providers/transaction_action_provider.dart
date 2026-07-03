import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/budget_allocation_draft.dart';
import '../../domain/entities/budget_period.dart';
import '../../domain/usecases/add_budget_period.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/add_expense.dart';
import '../../domain/usecases/add_income.dart';
import 'current_budget_provider.dart';
import 'finance_repository_provider.dart';
import 'selected_period_provider.dart';
import 'transaction_template_provider.dart';

final transactionActionProvider =
    NotifierProvider<TransactionActionNotifier, bool>(
      TransactionActionNotifier.new,
    );

class TransactionActionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> addIncome({
    required String periodId,
    required int amount,
    required String title,
    required DateTime date,
    String? recurringTemplateId,
    DateTime? recurringDueDate,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await AddIncome(repository).call(
        periodId: periodId,
        amount: amount,
        title: title,
        date: date,
        recurringTemplateId: recurringTemplateId,
        recurringDueDate: recurringDueDate,
      );
      ref.invalidate(currentBudgetProvider);
      ref.invalidate(budgetByPeriodProvider(periodId));
      ref.invalidate(budgetPeriodsProvider);
      ref.invalidate(allBudgetSnapshotsProvider);
      ref.invalidate(recurringOccurrencesProvider);
      ref.invalidate(recurringDueItemsProvider);
    } finally {
      state = false;
    }
  }

  Future<void> updateIncome({
    required String periodId,
    required String transactionId,
    required int amount,
    required String title,
    required DateTime date,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.updateIncome(
        periodId: periodId,
        transactionId: transactionId,
        amount: amount,
        title: title,
        date: date,
      );
      _invalidatePeriod(periodId);
    } finally {
      state = false;
    }
  }

  Future<void> addExpense({
    required String periodId,
    required String categoryId,
    required int amount,
    required String title,
    required DateTime date,
    String? recurringTemplateId,
    DateTime? recurringDueDate,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await AddExpense(repository).call(
        periodId: periodId,
        categoryId: categoryId,
        amount: amount,
        title: title,
        date: date,
        recurringTemplateId: recurringTemplateId,
        recurringDueDate: recurringDueDate,
      );
      ref.invalidate(currentBudgetProvider);
      ref.invalidate(budgetByPeriodProvider(periodId));
      ref.invalidate(budgetPeriodsProvider);
      ref.invalidate(allBudgetSnapshotsProvider);
      ref.invalidate(recurringOccurrencesProvider);
      ref.invalidate(recurringDueItemsProvider);
    } finally {
      state = false;
    }
  }

  Future<void> updateExpense({
    required String periodId,
    required String transactionId,
    required String categoryId,
    required int amount,
    required String title,
    required DateTime date,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.updateExpense(
        periodId: periodId,
        transactionId: transactionId,
        categoryId: categoryId,
        amount: amount,
        title: title,
        date: date,
      );
      _invalidatePeriod(periodId);
    } finally {
      state = false;
    }
  }

  Future<void> deleteTransaction({
    required String periodId,
    required String transactionId,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.deleteTransaction(
        periodId: periodId,
        transactionId: transactionId,
      );
      _invalidatePeriod(periodId);
    } finally {
      state = false;
    }
  }

  Future<void> addCategory({
    required String periodId,
    required String name,
    required int allocatedAmount,
    num? allocationPercent,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await AddCategory(repository).call(
        periodId: periodId,
        name: name,
        allocatedAmount: allocatedAmount,
        allocationPercent: allocationPercent,
      );
      ref.invalidate(currentBudgetProvider);
      ref.invalidate(budgetByPeriodProvider(periodId));
      ref.invalidate(budgetPeriodsProvider);
      ref.invalidate(allBudgetSnapshotsProvider);
    } finally {
      state = false;
    }
  }

  Future<void> updateCategory({
    required String periodId,
    required String categoryId,
    required String name,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.updateCategory(
        periodId: periodId,
        categoryId: categoryId,
        name: name,
      );
      _invalidatePeriod(periodId);
    } finally {
      state = false;
    }
  }

  Future<void> adjustCategoryBudget({
    required String periodId,
    required String categoryId,
    required String action,
    required int amount,
    required String reason,
    required DateTime date,
    String? relatedCategoryId,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.adjustCategoryBudget(
        periodId: periodId,
        categoryId: categoryId,
        action: action,
        amount: amount,
        reason: reason,
        date: date,
        relatedCategoryId: relatedCategoryId,
      );
      _invalidatePeriod(periodId);
    } finally {
      state = false;
    }
  }

  Future<void> deleteCategory({
    required String periodId,
    required String categoryId,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.deleteCategory(
        periodId: periodId,
        categoryId: categoryId,
      );
      _invalidatePeriod(periodId);
    } finally {
      state = false;
    }
  }

  Future<BudgetPeriod> addBudgetPeriod({
    required DateTime startDate,
    required DateTime endDate,
    required int initialIncome,
    required String incomeSource,
    required List<BudgetAllocationDraft> defaultAllocations,
    required bool allocationsFollowIncome,
    String? carryOverFromPeriodId,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      final period = await AddBudgetPeriod(repository).call(
        startDate: startDate,
        endDate: endDate,
        initialIncome: initialIncome,
        incomeSource: incomeSource,
        defaultAllocations: defaultAllocations,
        allocationsFollowIncome: allocationsFollowIncome,
        carryOverFromPeriodId: carryOverFromPeriodId,
      );
      ref.read(selectedPeriodIdProvider.notifier).select(period.id);
      ref.invalidate(currentBudgetProvider);
      ref.invalidate(budgetPeriodsProvider);
      ref.invalidate(budgetByPeriodProvider(period.id));
      ref.invalidate(allBudgetSnapshotsProvider);
      return period;
    } finally {
      state = false;
    }
  }

  Future<void> deleteBudgetPeriod(String periodId) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.deleteBudgetPeriod(periodId);
      final periods = await repository.getBudgetPeriods();
      ref
          .read(selectedPeriodIdProvider.notifier)
          .select(periods.isEmpty ? null : periods.first.id);
      ref.invalidate(currentBudgetProvider);
      ref.invalidate(budgetPeriodsProvider);
      ref.invalidate(budgetByPeriodProvider(periodId));
      ref.invalidate(allBudgetSnapshotsProvider);
    } finally {
      state = false;
    }
  }

  Future<void> updateBudgetPeriod({
    required String periodId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.updateBudgetPeriod(
        periodId: periodId,
        startDate: startDate,
        endDate: endDate,
      );
      _invalidatePeriod(periodId);
    } finally {
      state = false;
    }
  }

  void _invalidatePeriod(String periodId) {
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetByPeriodProvider(periodId));
    ref.invalidate(budgetPeriodsProvider);
    ref.invalidate(allBudgetSnapshotsProvider);
  }
}
