import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../domain/entities/transaction_item.dart';
import '../../../domain/services/finance_entry_sorter.dart';
import 'transaction_tile.dart';

class TransactionTimeline extends StatelessWidget {
  final List<TransactionItem> transactions;
  final ValueChanged<TransactionItem> onEdit;
  final ValueChanged<TransactionItem> onDelete;

  const TransactionTimeline({
    super.key,
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...transactions]
      ..sort(FinanceEntrySorter.newestTransactionFirst);

    if (sorted.isEmpty) {
      return EmptyState(
        message: context.tr('no_expenses_in_this_category_yet'),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < sorted.length; index++) ...[
          TransactionTile(
            transaction: sorted[index],
            onEdit: () => onEdit(sorted[index]),
            onDelete: () => onDelete(sorted[index]),
          ),
          if (index != sorted.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
