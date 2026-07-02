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
import '../../domain/entities/transaction_type.dart';
import '../providers/current_budget_provider.dart';
import '../providers/transaction_action_provider.dart';
import '../widgets/transaction_form/transaction_edit_sheet.dart';
import '../widgets/transaction_history_card.dart';

class IncomeDetailScreen extends ConsumerWidget {
  const IncomeDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodId = ModalRoute.of(context)?.settings.arguments as String?;
    final budgetAsync = periodId == null
        ? ref.watch(currentBudgetProvider)
        : ref.watch(budgetByPeriodProvider(periodId));

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('income_details'))),
      body: budgetAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (snapshot) {
          if (snapshot == null) {
            return EmptyState(
              message: context.tr(
                'create_a_financial_period_first_to_view_income',
              ),
            );
          }

          final incomes =
              snapshot.transactions
                  .where((item) => item.type == TransactionType.income)
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
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
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
                        context.tr('total_income'),
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      AmountText(
                        amount: snapshot.period.totalIncome,
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
                context.tr('income_history'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (incomes.isEmpty)
                EmptyState(
                  message: context.tr('no_income_recorded_in_this_period_yet'),
                )
              else
                ...incomes.map(
                  (income) => TransactionHistoryCard(
                    title: income.title,
                    date: income.date,
                    amount: income.amount,
                    isIncome: true,
                    onEdit: () async {
                      final result =
                          await showModalBottomSheet<TransactionEditResult>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => TransactionEditSheet(
                              transaction: income,
                              firstDate: snapshot.period.startDate,
                              lastDate: snapshot.period.endDate,
                            ),
                          );
                      if (result == null || !context.mounted) return;

                      await ref
                          .read(transactionActionProvider.notifier)
                          .updateIncome(
                            periodId: snapshot.period.id,
                            transactionId: income.id,
                            amount: result.amount,
                            title: result.title,
                            date: result.date,
                          );
                    },
                    onDelete: () async {
                      final confirmed = await showDeleteConfirmationDialog(
                        context,
                        title: context.tr('delete_income'),
                        message: context.trf(
                          'title_will_be_removed_from_income_history_this_action_cannot_be_undone',
                          {'title': income.title},
                        ),
                      );
                      if (!confirmed || !context.mounted) return;

                      await ref
                          .read(transactionActionProvider.notifier)
                          .deleteTransaction(
                            periodId: snapshot.period.id,
                            transactionId: income.id,
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
}
