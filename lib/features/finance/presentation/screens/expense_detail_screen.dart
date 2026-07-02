import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/transaction_item.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/current_budget_provider.dart';
import '../providers/transaction_action_provider.dart';
import '../widgets/transaction_form/transaction_edit_sheet.dart';
import '../widgets/transaction_history_card.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodId = ModalRoute.of(context)?.settings.arguments as String?;
    final budgetAsync = periodId == null
        ? ref.watch(currentBudgetProvider)
        : ref.watch(budgetByPeriodProvider(periodId));

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('expense_details'))),
      body: budgetAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (snapshot) {
          if (snapshot == null) {
            return EmptyState(
              message: context.tr(
                'create_a_financial_period_first_to_view_expenses',
              ),
            );
          }

          final expenses =
              snapshot.transactions
                  .where((item) => item.type == TransactionType.expense)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        DateFormatter.period(
                          snapshot.period.startDate,
                          snapshot.period.endDate,
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('total_expense'),
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      AmountText(
                        amount: snapshot.totalExpense,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('expense_history'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (expenses.isEmpty)
                EmptyState(
                  message: context.tr(
                    'no_expenses_recorded_in_this_period_yet',
                  ),
                )
              else
                ...expenses.map(
                  (expense) => TransactionHistoryCard(
                    title: _expenseTitle(snapshot.categories, expense),
                    date: expense.date,
                    amount: expense.amount,
                    isIncome: false,
                    onEdit: () async {
                      final result =
                          await showModalBottomSheet<TransactionEditResult>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => TransactionEditSheet(
                              transaction: expense,
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
                            transactionId: expense.id,
                            categoryId:
                                result.categoryId ?? expense.categoryId ?? '',
                            amount: result.amount,
                            title: result.title,
                            date: result.date,
                          );
                    },
                    onDelete: () async {
                      final confirmed = await showDeleteConfirmationDialog(
                        context,
                        title: context.tr('delete_expense'),
                        message: context.trf(
                          'title_will_be_removed_from_expense_history_this_action_cannot_be_undone',
                          {
                            'title': _expenseTitle(
                              snapshot.categories,
                              expense,
                            ),
                          },
                        ),
                      );
                      if (!confirmed || !context.mounted) return;

                      await ref
                          .read(transactionActionProvider.notifier)
                          .deleteTransaction(
                            periodId: snapshot.period.id,
                            transactionId: expense.id,
                          );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _expenseTitle(
    List<CategoryBudget> categories,
    TransactionItem expense,
  ) {
    if (expense.categoryId == null) return expense.title;

    final matches = categories.where(
      (category) => category.id == expense.categoryId,
    );
    return matches.isEmpty ? expense.title : matches.first.name;
  }
}
