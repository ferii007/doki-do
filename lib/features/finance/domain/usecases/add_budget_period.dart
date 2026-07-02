import '../entities/budget_period.dart';
import '../entities/budget_allocation_draft.dart';
import '../repositories/finance_repository.dart';

class AddBudgetPeriod {
  final FinanceRepository repository;

  const AddBudgetPeriod(this.repository);

  Future<BudgetPeriod> call({
    required DateTime startDate,
    required DateTime endDate,
    required int initialIncome,
    required String incomeSource,
    required List<BudgetAllocationDraft> defaultAllocations,
    required bool allocationsFollowIncome,
    String? carryOverFromPeriodId,
  }) {
    return repository.addBudgetPeriod(
      startDate: startDate,
      endDate: endDate,
      initialIncome: initialIncome,
      incomeSource: incomeSource,
      defaultAllocations: defaultAllocations,
      allocationsFollowIncome: allocationsFollowIncome,
      carryOverFromPeriodId: carryOverFromPeriodId,
    );
  }
}
