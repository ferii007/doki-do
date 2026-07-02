import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/formatters/rupiah_formatter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/category_adjustment.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/current_budget_provider.dart';
import '../providers/transaction_action_provider.dart';
import '../widgets/category_detail/category_balance_header.dart';
import '../widgets/category_detail/transaction_timeline.dart';
import '../widgets/transaction_form/transaction_edit_sheet.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = ModalRoute.of(context)?.settings.arguments as String?;
    final budgetAsync = ref.watch(currentBudgetProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('budget_details'))),
      body: budgetAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (snapshot) {
          if (snapshot == null) {
            return EmptyState(
              message: context.tr(
                'create_a_financial_period_first_to_view_the_budget',
              ),
            );
          }

          final matches = snapshot.categories.where(
            (item) => item.id == categoryId,
          );
          final category = matches.isEmpty ? null : matches.first;

          if (category == null) {
            return EmptyState(message: context.tr('this_budget_was_not_found'));
          }

          final transactions = snapshot.transactions
              .where(
                (item) =>
                    item.categoryId == category.id &&
                    item.type == TransactionType.expense,
              )
              .toList();
          final adjustments =
              snapshot.categoryAdjustments
                  .where((item) => item.categoryId == category.id)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CategoryBalanceHeader(category: category),
              const SizedBox(height: 16),
              Text(
                context.tr('expense_history'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TransactionTimeline(
                transactions: transactions,
                onEdit: (transaction) async {
                  final result =
                      await showModalBottomSheet<TransactionEditResult>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => TransactionEditSheet(
                          transaction: transaction,
                          firstDate: snapshot.period.startDate,
                          lastDate: snapshot.period.endDate,
                          categories: snapshot.categories,
                        ),
                      );
                  if (result == null || !context.mounted) return;

                  await ref
                      .read(transactionActionProvider.notifier)
                      .updateExpense(
                        periodId: snapshot.period.id,
                        transactionId: transaction.id,
                        categoryId: result.categoryId ?? category.id,
                        amount: result.amount,
                        title: result.title,
                        date: result.date,
                      );
                },
                onDelete: (transaction) async {
                  final confirmed = await showDeleteConfirmationDialog(
                    context,
                    title: context.tr('delete_expense'),
                    message: context.trf(
                      'title_will_be_removed_from_expense_history_this_action_cannot_be_undone',
                      {'title': transaction.title},
                    ),
                  );
                  if (!confirmed || !context.mounted) return;

                  await ref
                      .read(transactionActionProvider.notifier)
                      .deleteTransaction(
                        periodId: snapshot.period.id,
                        transactionId: transaction.id,
                      );
                },
              ),
              const SizedBox(height: 22),
              Text(
                context.tr('budget_change_history'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _AdjustmentTimeline(adjustments: adjustments),
            ],
          );
        },
      ),
    );
  }
}

class _AdjustmentTimeline extends StatelessWidget {
  final List<CategoryAdjustment> adjustments;

  const _AdjustmentTimeline({required this.adjustments});

  @override
  Widget build(BuildContext context) {
    if (adjustments.isEmpty) {
      return EmptyState(message: context.tr('no_budget_changes_yet'));
    }

    return Column(
      children: [
        for (var index = 0; index < adjustments.length; index++) ...[
          _AdjustmentTile(adjustment: adjustments[index]),
          if (index != adjustments.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AdjustmentTile extends StatelessWidget {
  final CategoryAdjustment adjustment;

  const _AdjustmentTile({required this.adjustment});

  @override
  Widget build(BuildContext context) {
    final isIncrease = adjustment.deltaAmount > 0;
    final color = isIncrease ? AppColors.primary : AppColors.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncrease
                    ? Icons.add_card_outlined
                    : Icons.remove_circle_outline,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(context),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    adjustment.reason,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormatter.full(adjustment.date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${isIncrease ? '+' : '-'}${RupiahFormatter.format(adjustment.amount)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(BuildContext context) {
    return switch (adjustment.type) {
      CategoryAdjustmentType.increase => context.tr('budget_increased'),
      CategoryAdjustmentType.decrease => context.tr('budget_decreased'),
      CategoryAdjustmentType.setAmount => context.tr('budget_set'),
    };
  }
}
