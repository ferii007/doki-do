import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction_template.dart';
import '../../domain/entities/transaction_type.dart';
import 'finance_repository_provider.dart';

final transactionTemplatesProvider = FutureProvider<List<TransactionTemplate>>((
  ref,
) async {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getTransactionTemplates();
});

final transactionTemplateActionProvider =
    NotifierProvider<TransactionTemplateActionNotifier, bool>(
      TransactionTemplateActionNotifier.new,
    );

class TransactionTemplateActionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> save({
    String? templateId,
    required TransactionType type,
    required String title,
    required int amount,
    String? preferredCategoryName,
    int? dayOfMonth,
  }) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.saveTransactionTemplate(
        templateId: templateId,
        type: type == TransactionType.income ? 'income' : 'expense',
        title: title,
        amount: amount,
        preferredCategoryName: preferredCategoryName,
        dayOfMonth: dayOfMonth,
      );
      ref.invalidate(transactionTemplatesProvider);
    } finally {
      state = false;
    }
  }

  Future<void> delete(String templateId) async {
    state = true;
    try {
      final repository = ref.read(financeRepositoryProvider);
      await repository.deleteTransactionTemplate(templateId);
      ref.invalidate(transactionTemplatesProvider);
    } finally {
      state = false;
    }
  }
}
