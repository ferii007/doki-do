import '../entities/budget_period.dart';
import '../repositories/finance_repository.dart';

class GetBudgetPeriods {
  final FinanceRepository repository;

  const GetBudgetPeriods(this.repository);

  Future<List<BudgetPeriod>> call() {
    return repository.getBudgetPeriods();
  }
}
