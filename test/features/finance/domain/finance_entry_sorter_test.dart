import 'package:doki_do/features/finance/domain/entities/category_adjustment.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_item.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_type.dart';
import 'package:doki_do/features/finance/domain/services/finance_entry_sorter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'sorts UI transactions by transaction date then newest created time',
    () {
      final tarikTunaiMorning = _expense(
        id: 'tarik-tunai-morning',
        title: 'Tarik Tunai',
        transactionDate: DateTime(2026, 7, 3),
        createdAt: DateTime(2026, 7, 3, 19),
      );
      final transfer = _expense(
        id: 'transfer',
        title: 'Transfer',
        transactionDate: DateTime(2026, 7, 3),
        createdAt: DateTime(2026, 7, 3, 21),
      );
      final netflix = _expense(
        id: 'netflix',
        title: 'Netflix',
        transactionDate: DateTime(2026, 7, 3),
        createdAt: DateTime(2026, 7, 3, 22),
      );
      final tarikTunaiLater = _expense(
        id: 'tarik-tunai-later',
        title: 'Tarik Tunai',
        transactionDate: DateTime(2026, 7, 3),
        createdAt: DateTime(2026, 7, 6, 16),
      );

      final transactions = [
        transfer,
        tarikTunaiMorning,
        netflix,
        tarikTunaiLater,
      ]..sort(FinanceEntrySorter.newestTransactionFirst);

      expect(transactions.map((item) => item.id), [
        'tarik-tunai-later',
        'netflix',
        'transfer',
        'tarik-tunai-morning',
      ]);
    },
  );

  test(
    'sorts export transactions by transaction date then oldest created time',
    () {
      final transactions = [
        _expense(
          id: 'netflix',
          title: 'Netflix',
          transactionDate: DateTime(2026, 7, 3),
          createdAt: DateTime(2026, 7, 3, 22),
        ),
        _expense(
          id: 'tarik-tunai-morning',
          title: 'Tarik Tunai',
          transactionDate: DateTime(2026, 7, 3),
          createdAt: DateTime(2026, 7, 3, 19),
        ),
        _expense(
          id: 'transfer',
          title: 'Transfer',
          transactionDate: DateTime(2026, 7, 3),
          createdAt: DateTime(2026, 7, 3, 21),
        ),
        _expense(
          id: 'tarik-tunai-later',
          title: 'Tarik Tunai',
          transactionDate: DateTime(2026, 7, 3),
          createdAt: DateTime(2026, 7, 6, 16),
        ),
      ]..sort(FinanceEntrySorter.oldestTransactionFirst);

      expect(transactions.map((item) => item.id), [
        'tarik-tunai-morning',
        'transfer',
        'netflix',
        'tarik-tunai-later',
      ]);
    },
  );

  test(
    'sorts budget adjustments by adjustment date then newest created time',
    () {
      final adjustments = [
        _adjustment(id: 'first', createdAt: DateTime(2026, 7, 3, 19)),
        _adjustment(id: 'third', createdAt: DateTime(2026, 7, 6, 16)),
        _adjustment(id: 'second', createdAt: DateTime(2026, 7, 3, 21)),
      ]..sort(FinanceEntrySorter.newestAdjustmentFirst);

      expect(adjustments.map((item) => item.id), ['third', 'second', 'first']);
    },
  );
}

TransactionItem _expense({
  required String id,
  required String title,
  required DateTime transactionDate,
  required DateTime createdAt,
}) {
  return TransactionItem(
    id: id,
    categoryId: 'category-1',
    title: title,
    amount: 100000,
    date: transactionDate,
    createdAt: createdAt,
    type: TransactionType.expense,
  );
}

CategoryAdjustment _adjustment({
  required String id,
  required DateTime createdAt,
}) {
  return CategoryAdjustment(
    id: id,
    categoryId: 'category-1',
    type: CategoryAdjustmentType.increase,
    amount: 100000,
    deltaAmount: 100000,
    previousAmount: 0,
    newAmount: 100000,
    reason: 'Testing',
    date: DateTime(2026, 7, 3),
    createdAt: createdAt,
  );
}
