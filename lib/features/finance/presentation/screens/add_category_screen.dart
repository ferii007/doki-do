import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/currency_input_formatter.dart';
import '../../../../core/formatters/rupiah_formatter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/budget_period.dart';
import '../../domain/entities/budget_snapshot.dart';
import '../providers/current_budget_provider.dart';
import '../providers/selected_period_provider.dart';
import '../providers/transaction_action_provider.dart';
import '../widgets/transaction_form/amount_input.dart';
import '../widgets/transaction_form/budget_period_picker.dart';
import '../widgets/transaction_form/transaction_note_field.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String? _periodId;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(transactionActionProvider);
    final periodsAsync = ref.watch(budgetPeriodsProvider);
    final selectedDashboardPeriodId = ref.watch(selectedPeriodIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('add_budget_category'))),
      body: periodsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (periods) {
          final selectedPeriodId = _resolveSelectedPeriodId(
            periods,
            selectedDashboardPeriodId,
          );

          if (selectedPeriodId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.tr(
                    'create_a_financial_period_before_adding_a_budget_category',
                  ),
                ),
              ),
            );
          }

          final budgetAsync = ref.watch(
            budgetByPeriodProvider(selectedPeriodId),
          );

          return budgetAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(error: error),
            data: (snapshot) {
              final remainingAllocation = _remainingAllocation(snapshot);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  BudgetPeriodPicker(
                    periods: periods,
                    selectedPeriodId: selectedPeriodId,
                    onChanged: (value) => setState(() => _periodId = value),
                  ),
                  const SizedBox(height: 12),
                  _RemainingAllocationCard(amount: remainingAllocation),
                  const SizedBox(height: 12),
                  TransactionNoteField(
                    controller: _nameController,
                    label: context.tr('budget_category_name'),
                  ),
                  const SizedBox(height: 12),
                  AmountInput(controller: _amountController),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isSaving ? null : () => _submit(snapshot),
                    child: Text(
                      context.tr(isSaving ? 'saving' : 'save_budget_category'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String? _resolveSelectedPeriodId(
    List<BudgetPeriod> periods,
    String? selectedDashboardPeriodId,
  ) {
    if (periods.isEmpty) return null;

    final current = _periodId;
    if (current != null && periods.any((period) => period.id == current)) {
      return current;
    }

    if (selectedDashboardPeriodId != null &&
        periods.any((period) => period.id == selectedDashboardPeriodId)) {
      _periodId = selectedDashboardPeriodId;
      return selectedDashboardPeriodId;
    }

    _periodId = periods.first.id;
    return _periodId;
  }

  int _remainingAllocation(BudgetSnapshot snapshot) {
    final allocatedTotal = snapshot.categories.fold<int>(
      0,
      (total, category) => total + category.allocatedAmount,
    );
    return snapshot.period.totalIncome - allocatedTotal;
  }

  Future<void> _submit(BudgetSnapshot snapshot) async {
    final name = _nameController.text.trim();
    final amount = CurrencyInputFormatter.parse(_amountController.text);
    final periodId = _periodId;
    final remainingAllocation = _remainingAllocation(snapshot);

    if (periodId == null) {
      AppToast.show(
        context,
        context.tr('choose_a_period_for_this_budget_category_first'),
      );
      return;
    }

    if (name.isEmpty) {
      AppToast.show(
        context,
        context.tr('enter_the_budget_category_name_first'),
      );
      return;
    }

    if (amount <= 0) {
      AppToast.show(context, context.tr('enter_the_budget_amount_first'));
      return;
    }

    if (amount > remainingAllocation) {
      AppToast.show(
        context,
        context.trf(
          'the_amount_exceeds_the_remaining_allocatable_balance_which_is_amount',
          {'amount': RupiahFormatter.format(remainingAllocation)},
        ),
      );
      return;
    }

    await ref
        .read(transactionActionProvider.notifier)
        .addCategory(
          periodId: periodId,
          name: name,
          allocatedAmount: amount,
          allocationPercent: _allocationPercent(snapshot, amount),
        );

    if (mounted) {
      AppToast.show(context, context.tr('budget_category_added_successfully'));
      Navigator.pop(context);
    }
  }

  num? _allocationPercent(BudgetSnapshot snapshot, int amount) {
    if (!snapshot.period.allocationsFollowIncome) return null;
    final totalIncome = snapshot.period.totalIncome;
    if (totalIncome <= 0) return null;
    final percentage = (amount / totalIncome) * 100;
    final rounded = double.parse(percentage.toStringAsFixed(6));
    if (rounded == rounded.roundToDouble()) return rounded.toInt();
    return rounded;
  }
}

class _RemainingAllocationCard extends StatelessWidget {
  final int amount;

  const _RemainingAllocationCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNegative
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.mintSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNegative
              ? AppColors.danger.withValues(alpha: 0.28)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: isNegative ? AppColors.danger : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('unallocated_balance'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            RupiahFormatter.format(amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isNegative ? AppColors.danger : AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
