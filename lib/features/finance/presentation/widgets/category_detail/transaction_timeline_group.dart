import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../domain/entities/transaction_item.dart';
import 'transaction_tile.dart';

class TransactionTimelineGroup extends StatelessWidget {
  final DateTime date;
  final List<TransactionItem> transactions;
  final ValueChanged<TransactionItem> onEdit;
  final ValueChanged<TransactionItem> onDelete;

  const TransactionTimelineGroup({
    super.key,
    required this.date,
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.mintSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Text(
              DateFormatter.full(date),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: transactions
                  .map(
                    (item) => TransactionTile(
                      transaction: item,
                      onEdit: () => onEdit(item),
                      onDelete: () => onDelete(item),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
