import '../entities/category_adjustment.dart';
import '../entities/transaction_item.dart';

abstract final class FinanceEntrySorter {
  static int newestTransactionFirst(TransactionItem a, TransactionItem b) {
    final byTransactionDate = b.date.compareTo(a.date);
    if (byTransactionDate != 0) return byTransactionDate;

    final byCreatedAt = b.createdAt.compareTo(a.createdAt);
    if (byCreatedAt != 0) return byCreatedAt;

    return b.id.compareTo(a.id);
  }

  static int oldestTransactionFirst(TransactionItem a, TransactionItem b) {
    final byTransactionDate = a.date.compareTo(b.date);
    if (byTransactionDate != 0) return byTransactionDate;

    final byCreatedAt = a.createdAt.compareTo(b.createdAt);
    if (byCreatedAt != 0) return byCreatedAt;

    return a.id.compareTo(b.id);
  }

  static int newestAdjustmentFirst(CategoryAdjustment a, CategoryAdjustment b) {
    final byAdjustmentDate = b.date.compareTo(a.date);
    if (byAdjustmentDate != 0) return byAdjustmentDate;

    final byCreatedAt = b.createdAt.compareTo(a.createdAt);
    if (byCreatedAt != 0) return byCreatedAt;

    return b.id.compareTo(a.id);
  }
}
