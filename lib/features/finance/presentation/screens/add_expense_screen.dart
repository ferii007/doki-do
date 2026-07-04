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
import '../../domain/entities/budget_period.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/recurring_due_item.dart';
import '../../domain/entities/transaction_template.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/current_budget_provider.dart';
import '../providers/recurring_notification_provider.dart';
import '../providers/selected_period_provider.dart';
import '../providers/transaction_action_provider.dart';
import '../providers/transaction_template_provider.dart';
import '../widgets/transaction_form/amount_input.dart';
import '../widgets/transaction_form/budget_period_picker.dart';
import '../widgets/transaction_form/category_picker.dart';
import '../widgets/transaction_form/transaction_date_picker.dart';
import '../widgets/transaction_form/transaction_note_field.dart';
import '../widgets/transaction_form/transaction_template_picker.dart';
import '../widgets/transaction_form/transaction_template_save_options.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  String? _periodId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _saveAsTemplate = false;
  bool _saveAsRecurring = false;
  bool _routeTemplateLoaded = false;
  bool _routeTemplateApplied = false;
  TransactionTemplate? _routeTemplate;
  RecurringTransactionDraft? _recurringDraft;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeTemplateLoaded) return;
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is RecurringTransactionDraft &&
        argument.template.type == TransactionType.expense) {
      _recurringDraft = argument;
      _routeTemplate = argument.template;
      _date = argument.dueDate;
    } else if (argument is TransactionTemplate &&
        argument.type == TransactionType.expense) {
      _routeTemplate = argument;
    }
    _routeTemplateLoaded = true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(budgetPeriodsProvider);
    final selectedDashboardPeriodId = ref.watch(selectedPeriodIdProvider);
    final isSaving = ref.watch(transactionActionProvider);
    final loadedPeriods = periodsAsync.asData?.value ?? const <BudgetPeriod>[];
    final recurringPeriodId = _findPeriodForDate(
      loadedPeriods,
      _recurringDraft?.dueDate,
    )?.id;
    final activePeriodId =
        _periodId ?? recurringPeriodId ?? selectedDashboardPeriodId;
    final templates = ref.watch(transactionTemplatesProvider).asData?.value;
    final budgetAsync = activePeriodId == null
        ? ref.watch(currentBudgetProvider)
        : ref.watch(budgetByPeriodProvider(activePeriodId));

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('record_expense'))),
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

          return budgetAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(error: error),
            data: (snapshot) {
              if (snapshot == null) {
                return const _CreatePeriodPrompt();
              }

              if (!_routeTemplateApplied && _routeTemplate != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _routeTemplateApplied) return;
                  _applyTemplate(_routeTemplate!, snapshot.categories);
                  _routeTemplateApplied = true;
                });
              }

              _date = _clampDate(
                _date,
                snapshot.period.startDate,
                snapshot.period.endDate,
              );
              final validCategory = snapshot.categories.any(
                (category) => category.id == _categoryId,
              );
              if (!validCategory) {
                _categoryId = snapshot.categories.isEmpty
                    ? null
                    : snapshot.categories.first.id;
              }

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
                        _categoryId = null;
                        _date = _clampDate(
                          _date,
                          period.startDate,
                          period.endDate,
                        );
                      });
                    },
                  ),
                  if (templates != null && templates.isNotEmpty) ...[
                    const AppFormControlGap(),
                    TransactionTemplatePicker(
                      templates: templates,
                      type: TransactionType.expense,
                      onSelected: (template) {
                        _applyTemplate(template, snapshot.categories);
                      },
                    ),
                  ],
                  if (templates != null && templates.isNotEmpty)
                    const AppFormControlGap()
                  else
                    const AppFormFieldGap(),
                  CategoryPicker(
                    categories: snapshot.categories,
                    selectedCategoryId: _categoryId,
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  const AppFormFieldGap(),
                  AmountInput(controller: _amountController),
                  const AppFormFieldGap(),
                  TransactionNoteField(
                    controller: _titleController,
                    label: context.tr('what_was_it_used_for'),
                  ),
                  const AppFormControlGap(),
                  TransactionDatePicker(
                    date: _date,
                    firstDate: snapshot.period.startDate,
                    lastDate: snapshot.period.endDate,
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
                    child: Text(
                      context.tr(isSaving ? 'saving' : 'save_expense'),
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

  Future<void> _submit() async {
    final amount = CurrencyInputFormatter.parse(_amountController.text);
    final title = _titleController.text.trim();
    final periodId = _periodId;
    final categoryId = _categoryId;

    if (periodId == null) {
      AppToast.show(
        context,
        context.tr('choose_a_period_for_this_expense_first'),
      );
      return;
    }

    if (categoryId == null) {
      AppToast.show(context, context.tr('choose_the_budget_category_first'));
      return;
    }

    if (amount <= 0) {
      AppToast.show(context, context.tr('enter_the_expense_amount_first'));
      return;
    }

    if (title.isEmpty) {
      AppToast.show(
        context,
        context.tr('write_what_the_money_was_used_for_first'),
      );
      return;
    }

    final categoryName = _findCategoryName(periodId, categoryId);
    var notificationPermissionDenied = false;
    try {
      await ref
          .read(transactionActionProvider.notifier)
          .addExpense(
            periodId: periodId,
            categoryId: categoryId,
            amount: amount,
            title: title,
            date: _date,
            recurringTemplateId: _recurringDraft?.template.id,
            recurringDueDate: _recurringDraft?.dueDate,
          );

      if (_saveAsTemplate || _saveAsRecurring) {
        final permissionGranted = await ref
            .read(transactionTemplateActionProvider.notifier)
            .save(
              type: TransactionType.expense,
              amount: amount,
              title: title,
              preferredCategoryName: categoryName,
              dayOfMonth: _saveAsRecurring ? _date.day : null,
              activeFromDate: _date,
            );
        notificationPermissionDenied = permissionGranted == false;
      }
    } on StateError catch (error) {
      if (!mounted) return;
      AppToast.show(context, context.tr(error.message.toString()));
      return;
    }

    if (mounted) {
      final notificationService = notificationPermissionDenied
          ? ref.read(recurringNotificationServiceProvider)
          : null;
      AppToast.show(
        context,
        context.tr(
          notificationPermissionDenied
              ? 'expense_recorded_notification_not_allowed'
              : 'expense_recorded_successfully',
        ),
        actionLabel: notificationPermissionDenied
            ? context.tr('open_settings')
            : null,
        onAction: notificationService == null
            ? null
            : () => notificationService.openNotificationSettings(),
      );
      Navigator.pop(context);
    }
  }

  DateTime _clampDate(DateTime value, DateTime min, DateTime max) {
    if (value.isBefore(min)) return min;
    if (value.isAfter(max)) return max;
    return value;
  }

  void _applyTemplate(
    TransactionTemplate template,
    List<CategoryBudget> categories,
  ) {
    final preferredName = template.preferredCategoryName?.trim().toLowerCase();
    final matchedCategory = preferredName == null
        ? null
        : _findCategoryByName(categories, preferredName);

    setState(() {
      _amountController.text = CurrencyInputFormatter.format(template.amount);
      _titleController.text = template.title;
      if (matchedCategory != null) _categoryId = matchedCategory.id;
      _saveAsTemplate = false;
      _saveAsRecurring = false;
    });

    AppToast.show(
      context,
      matchedCategory == null && template.preferredCategoryName != null
          ? context.tr('template_applied_choose_category')
          : context.tr('template_applied'),
    );
  }

  String? _findCategoryName(String periodId, String categoryId) {
    final snapshot = ref.read(budgetByPeriodProvider(periodId)).asData?.value;
    if (snapshot == null) return null;
    for (final category in snapshot.categories) {
      if (category.id == categoryId) return category.name;
    }
    return null;
  }

  CategoryBudget? _findCategoryByName(
    List<CategoryBudget> categories,
    String normalizedName,
  ) {
    for (final category in categories) {
      if (category.name.trim().toLowerCase() == normalizedName) {
        return category;
      }
    }
    return null;
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
                'expenses_need_to_be_placed_in_a_period_and_budget_category',
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
