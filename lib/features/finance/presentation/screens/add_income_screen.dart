import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/currency_input_formatter.dart';
import '../../../../core/layout/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/current_budget_provider.dart';
import '../providers/selected_period_provider.dart';
import '../providers/transaction_action_provider.dart';
import '../providers/transaction_template_provider.dart';
import '../widgets/transaction_form/amount_input.dart';
import '../widgets/transaction_form/budget_period_picker.dart';
import '../widgets/transaction_form/transaction_date_picker.dart';
import '../widgets/transaction_form/transaction_note_field.dart';
import '../widgets/transaction_form/transaction_template_picker.dart';
import '../widgets/transaction_form/transaction_template_save_options.dart';
import '../../domain/entities/budget_period.dart';
import '../../domain/entities/recurring_due_item.dart';
import '../../domain/entities/transaction_template.dart';
import '../../domain/entities/transaction_type.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  String? _periodId;
  DateTime _date = DateTime.now();
  bool _saveAsTemplate = false;
  bool _saveAsRecurring = false;
  bool _routeTemplateApplied = false;
  RecurringTransactionDraft? _recurringDraft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeTemplateApplied) return;
    final argument = ModalRoute.of(context)?.settings.arguments;
    final template = switch (argument) {
      RecurringTransactionDraft(:final template)
          when template.type == TransactionType.income =>
        template,
      TransactionTemplate() when argument.type == TransactionType.income =>
        argument,
      _ => null,
    };
    if (template != null) {
      if (argument is RecurringTransactionDraft) {
        _recurringDraft = argument;
        _date = argument.dueDate;
      }
      _amountController.text = CurrencyInputFormatter.format(template.amount);
      _titleController.text = template.title;
      _routeTemplateApplied = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(transactionActionProvider);
    final periodsAsync = ref.watch(budgetPeriodsProvider);
    final selectedDashboardPeriodId = ref.watch(selectedPeriodIdProvider);
    final templates = ref.watch(transactionTemplatesProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('record_income'))),
      body: periodsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (periods) {
          if (periods.isEmpty) {
            return const _CreatePeriodPrompt();
          }

          _periodId ??=
              _findPeriodForDate(periods, _recurringDraft?.dueDate)?.id ??
              selectedDashboardPeriodId ??
              periods.first.id;
          final selectedPeriod = periods.firstWhere(
            (period) => period.id == _periodId,
            orElse: () => periods.first,
          );
          _date = _clampDate(
            _date,
            selectedPeriod.startDate,
            selectedPeriod.endDate,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BudgetPeriodPicker(
                periods: periods,
                selectedPeriodId: _periodId,
                onChanged: (value) {
                  final period = periods.firstWhere(
                    (item) => item.id == value,
                    orElse: () => periods.first,
                  );
                  setState(() {
                    _periodId = value;
                    _date = _clampDate(_date, period.startDate, period.endDate);
                  });
                },
              ),
              if (templates != null && templates.isNotEmpty) ...[
                const AppFormControlGap(),
                TransactionTemplatePicker(
                  templates: templates,
                  type: TransactionType.income,
                  onSelected: (template) {
                    setState(() {
                      _amountController.text = CurrencyInputFormatter.format(
                        template.amount,
                      );
                      _titleController.text = template.title;
                      _saveAsTemplate = false;
                      _saveAsRecurring = false;
                    });
                    AppToast.show(context, context.tr('template_applied'));
                  },
                ),
              ],
              if (templates != null && templates.isNotEmpty)
                const AppFormControlGap()
              else
                const AppFormFieldGap(),
              AmountInput(controller: _amountController),
              const AppFormFieldGap(),
              TransactionNoteField(
                controller: _titleController,
                label: context.tr('where_did_this_money_come_from'),
              ),
              const AppFormControlGap(),
              TransactionDatePicker(
                date: _date,
                firstDate: selectedPeriod.startDate,
                lastDate: selectedPeriod.endDate,
                onChanged: (value) => setState(() => _date = value),
              ),
              const AppFormControlGap(),
              TransactionTemplateSaveOptions(
                saveAsTemplate: _saveAsTemplate,
                saveAsRecurring: _saveAsRecurring,
                recurringDay: _date.day,
                onTemplateChanged: (value) =>
                    setState(() => _saveAsTemplate = value),
                onRecurringChanged: (value) =>
                    setState(() => _saveAsRecurring = value),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isSaving ? null : _submit,
                child: Text(context.tr(isSaving ? 'saving' : 'save_income')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    final amount = CurrencyInputFormatter.parse(_amountController.text);
    final title = _titleController.text.trim();
    final periodId = _periodId;

    if (periodId == null) {
      AppToast.show(
        context,
        context.tr('choose_a_period_for_this_income_first'),
      );
      return;
    }

    if (amount <= 0) {
      AppToast.show(context, context.tr('enter_the_income_amount_first'));
      return;
    }

    if (title.isEmpty) {
      AppToast.show(context, context.tr('write_the_income_source_first'));
      return;
    }

    try {
      await ref
          .read(transactionActionProvider.notifier)
          .addIncome(
            periodId: periodId,
            amount: amount,
            title: title,
            date: _date,
            recurringTemplateId: _recurringDraft?.template.id,
            recurringDueDate: _recurringDraft?.dueDate,
          );

      if (_saveAsTemplate || _saveAsRecurring) {
        await ref
            .read(transactionTemplateActionProvider.notifier)
            .save(
              type: TransactionType.income,
              amount: amount,
              title: title,
              dayOfMonth: _saveAsRecurring ? _date.day : null,
              activeFromDate: _date,
            );
      }
    } on StateError catch (error) {
      if (!mounted) return;
      AppToast.show(context, context.tr(error.message.toString()));
      return;
    }

    if (mounted) {
      AppToast.show(context, context.tr('income_recorded_successfully'));
      Navigator.pop(context);
    }
  }

  DateTime _clampDate(DateTime value, DateTime min, DateTime max) {
    if (value.isBefore(min)) return min;
    if (value.isAfter(max)) return max;
    return value;
  }

  BudgetPeriod? _findPeriodForDate(List<BudgetPeriod> periods, DateTime? date) {
    if (date == null) return null;
    for (final period in periods) {
      if (!date.isBefore(period.startDate) && !date.isAfter(period.endDate)) {
        return period;
      }
    }
    return null;
  }
}

class _CreatePeriodPrompt extends StatelessWidget {
  const _CreatePeriodPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range_rounded, color: AppColors.primary, size: 42),
            const SizedBox(height: 12),
            Text(
              context.tr('create_a_financial_period_first_2'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'income_needs_to_be_placed_in_a_period_so_records_stay_organized',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.addPeriod),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('create_period')),
            ),
          ],
        ),
      ),
    );
  }
}
