import '../repositories/finance_repository.dart';

class AddExpense {
  final FinanceRepository repository;

  const AddExpense(this.repository);

  Future<void> call({
    required String periodId,
    required String categoryId,
    required int amount,
    required String title,
    required DateTime date,
  }) {
    return repository.addExpense(
      periodId: periodId,
      categoryId: categoryId,
      amount: amount,
      title: title,
      date: date,
    );
  }
}
