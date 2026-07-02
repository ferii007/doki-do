import '../repositories/finance_repository.dart';

class AddCategory {
  final FinanceRepository repository;

  const AddCategory(this.repository);

  Future<void> call({
    required String periodId,
    required String name,
    required int allocatedAmount,
    num? allocationPercent,
  }) {
    return repository.addCategory(
      periodId: periodId,
      name: name,
      allocatedAmount: allocatedAmount,
      allocationPercent: allocationPercent,
    );
  }
}
