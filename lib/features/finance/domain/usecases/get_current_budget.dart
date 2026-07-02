import '../entities/budget_snapshot.dart';
import '../repositories/finance_repository.dart';

class GetCurrentBudget {
  final FinanceRepository repository;

  const GetCurrentBudget(this.repository);

  Future<BudgetSnapshot?> call() {
    return repository.getCurrentBudget();
  }
}
