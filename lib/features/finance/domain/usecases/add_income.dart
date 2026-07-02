import '../repositories/finance_repository.dart';

class AddIncome {
  final FinanceRepository repository;

  const AddIncome(this.repository);

  Future<void> call({
    required String periodId,
    required int amount,
    required String title,
    required DateTime date,
  }) {
    return repository.addIncome(
      periodId: periodId,
      amount: amount,
      title: title,
      date: date,
    );
  }
}
