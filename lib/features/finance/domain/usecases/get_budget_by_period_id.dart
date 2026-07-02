import '../entities/budget_snapshot.dart';
import '../repositories/finance_repository.dart';

class GetBudgetByPeriodId {
  final FinanceRepository repository;

  const GetBudgetByPeriodId(this.repository);

  Future<BudgetSnapshot> call(String periodId) {
    return repository.getBudgetByPeriodId(periodId);
  }
}
