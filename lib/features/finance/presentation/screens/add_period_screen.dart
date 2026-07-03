import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/currency_input_formatter.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/formatters/rupiah_formatter.dart';
import '../../../../core/layout/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_calendar.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/budget_allocation_draft.dart';
import '../../domain/entities/budget_period.dart';
import '../../domain/entities/budget_snapshot.dart';
import '../providers/current_budget_provider.dart';
import '../providers/transaction_action_provider.dart';
import '../widgets/transaction_form/amount_input.dart';
import '../widgets/transaction_form/transaction_note_field.dart';

class AddPeriodScreen extends ConsumerStatefulWidget {
  const AddPeriodScreen({super.key});

  @override
  ConsumerState<AddPeriodScreen> createState() => _AddPeriodScreenState();
}

class _AddPeriodScreenState extends ConsumerState<AddPeriodScreen> {
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _budgetNameControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _customPercentageControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _customAmountControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _visibleMonth;
  int _selectedFormulaIndex = 0;
  bool _allocationsFollowIncome = true;
  bool _useCustomFormula = false;
  bool _transferPreviousRemaining = true;
  _CustomFormulaMode _customFormulaMode = _CustomFormulaMode.percentage;
  bool _localizedDefaultsInitialized = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_refreshPreview);
    for (final controller in _budgetNameControllers) {
      controller.addListener(_refreshPreview);
    }
    for (final controller in [
      ..._customPercentageControllers,
      ..._customAmountControllers,
    ]) {
      controller.addListener(_refreshPreview);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localizedDefaultsInitialized) return;
    _localizedDefaultsInitialized = true;
    _budgetNameControllers[0].text = context.tr('default_daily_needs');
    _budgetNameControllers[1].text = context.tr('default_savings_investment');
    _budgetNameControllers[2].text = context.tr('default_entertainment');
  }

  @override
  void dispose() {
    _amountController
      ..removeListener(_refreshPreview)
      ..dispose();
    _sourceController.dispose();
    for (final controller in _budgetNameControllers) {
      controller
        ..removeListener(_refreshPreview)
        ..dispose();
    }
    for (final controller in [
      ..._customPercentageControllers,
      ..._customAmountControllers,
    ]) {
      controller
        ..removeListener(_refreshPreview)
        ..dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshotsAsync = ref.watch(allBudgetSnapshotsProvider);
    final isSaving = ref.watch(transactionActionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('add_financial_period'))),
      body: snapshotsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (snapshots) {
          final periods = snapshots.map((snapshot) => snapshot.period).toList();
          _visibleMonth ??= _initialVisibleMonth(periods);
          final visibleMonth = _visibleMonth!;
          final budgetNames = _budgetNames;
          final formulas = _formulaTemplates(context, budgetNames.length);
          final selectedFormulaIndex = _selectedFormulaIndex >= formulas.length
              ? 0
              : _selectedFormulaIndex;
          final selectedFormula = formulas[selectedFormulaIndex];
          final carryOverCandidate = _carryOverCandidate(snapshots);
          final carryOverAmount =
              _transferPreviousRemaining && carryOverCandidate != null
              ? carryOverCandidate.amount
              : 0;
          final totalFunding = _initialIncome + carryOverAmount;
          final allocations = _useCustomFormula
              ? _buildCustomAllocations(budgetNames, totalFunding)
              : _buildAllocations(
                  budgetNames,
                  selectedFormula.percentages,
                  totalFunding,
                );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.paddingOf(context).bottom + 32,
            ),
            children: [
              _SelectedRangeCard(startDate: _startDate, endDate: _endDate),
              const SizedBox(height: 12),
              AppCalendar(
                initialVisibleMonth: visibleMonth,
                selectedStart: _startDate,
                selectedEnd: _endDate,
                isDateDisabled: (date) => _isDateOccupied(periods, date),
                onDateTap: (date) => _handleDateTap(periods, date),
              ),
              const AppFormControlGap(),
              AmountInput(controller: _amountController),
              const AppFormFieldGap(),
              TransactionNoteField(
                controller: _sourceController,
                label: context.tr('opening_balance_source_2'),
              ),
              if (carryOverCandidate != null) ...[
                const AppFormControlGap(),
                _CarryOverCard(
                  candidate: carryOverCandidate,
                  selected: _transferPreviousRemaining,
                  onChanged: (value) =>
                      setState(() => _transferPreviousRemaining = value),
                ),
              ],
              const AppFormControlGap(),
              _SectionHeader(
                title: context.tr('initial_budget_plan'),
                actionLabel: context.tr('add'),
                onActionTap: _addDefaultBudget,
              ),
              const AppFormControlGap(),
              for (
                var index = 0;
                index < _budgetNameControllers.length;
                index++
              ) ...[
                _DefaultBudgetField(
                  controller: _budgetNameControllers[index],
                  index: index,
                  canDelete: _budgetNameControllers.length > 1,
                  onDelete: () => _confirmRemoveDefaultBudget(index),
                ),
                if (index != _budgetNameControllers.length - 1)
                  const AppFormFieldGap(),
              ],
              const SizedBox(height: 18),
              _SectionHeader(title: context.tr('how_to_split_the_balance')),
              const SizedBox(height: 10),
              for (var index = 0; index < formulas.length; index++) ...[
                _FormulaCard(
                  formula: formulas[index],
                  selected: !_useCustomFormula && index == selectedFormulaIndex,
                  onTap: () => setState(() {
                    _useCustomFormula = false;
                    _selectedFormulaIndex = index;
                  }),
                ),
                if (index != formulas.length - 1) const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              _CustomFormulaCard(
                selected: _useCustomFormula,
                onTap: () => setState(() {
                  _useCustomFormula = true;
                  _seedCustomPercentages(selectedFormula.percentages);
                }),
              ),
              if (_useCustomFormula) ...[
                const SizedBox(height: 12),
                _CustomFormulaModeSelector(
                  mode: _customFormulaMode,
                  onChanged: (value) => setState(() {
                    _customFormulaMode = value;
                    if (value == _CustomFormulaMode.amount) {
                      _allocationsFollowIncome = false;
                    }
                  }),
                ),
                const AppFormControlGap(),
                for (var index = 0; index < budgetNames.length; index++) ...[
                  _CustomAllocationField(
                    name: budgetNames[index],
                    controller:
                        _customFormulaMode == _CustomFormulaMode.percentage
                        ? _customPercentageControllers[index]
                        : _customAmountControllers[index],
                    mode: _customFormulaMode,
                  ),
                  if (index != budgetNames.length - 1) const AppFormFieldGap(),
                ],
              ],
              const SizedBox(height: 14),
              _AllocationModeSelector(
                allocationsFollowIncome: _allocationsFollowIncome,
                onChanged: (value) =>
                    setState(() => _allocationsFollowIncome = value),
              ),
              const SizedBox(height: 14),
              _AllocationPreview(allocations: allocations),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () => _submit(
                        periods,
                        budgetNames,
                        allocations,
                        carryOverCandidate,
                      ),
                child: Text(context.tr(isSaving ? 'saving' : 'save_period')),
              ),
            ],
          );
        },
      ),
    );
  }

  int get _initialIncome =>
      CurrencyInputFormatter.parse(_amountController.text);

  List<String> get _budgetNames {
    return _budgetNameControllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<void> _submit(
    List<BudgetPeriod> periods,
    List<String> budgetNames,
    List<BudgetAllocationDraft> allocations,
    _CarryOverCandidate? carryOverCandidate,
  ) async {
    final startDate = _startDate;
    final endDate = _endDate;
    final initialIncome = _initialIncome;
    final incomeSource = _sourceController.text.trim();
    final carryOverAmount =
        _transferPreviousRemaining && carryOverCandidate != null
        ? carryOverCandidate.amount
        : 0;

    if (startDate == null || endDate == null) {
      AppToast.show(
        context,
        context.tr('choose_the_start_and_end_dates_first'),
      );
      return;
    }

    if (_rangeOverlapsExistingPeriod(periods, startDate, endDate)) {
      AppToast.show(
        context,
        context.tr('the_selected_date_overlaps_with_an_existing_period'),
      );
      return;
    }

    if (initialIncome <= 0 && carryOverAmount <= 0) {
      AppToast.show(context, context.tr('enter_the_opening_balance_first'));
      return;
    }

    if (initialIncome + carryOverAmount <= 0) {
      AppToast.show(
        context,
        context.tr('opening_balance_is_not_enough_to_cover_previous_deficit'),
      );
      return;
    }

    if (initialIncome > 0 && incomeSource.isEmpty) {
      AppToast.show(
        context,
        context.tr('write_the_opening_balance_source_first'),
      );
      return;
    }

    if (budgetNames.isEmpty) {
      AppToast.show(
        context,
        context.tr('add_at_least_one_initial_budget_plan'),
      );
      return;
    }

    if (budgetNames.toSet().length != budgetNames.length) {
      AppToast.show(
        context,
        context.tr('budget_category_names_cannot_be_duplicated'),
      );
      return;
    }

    if (_useCustomFormula &&
        !_validateCustomAllocations(initialIncome + carryOverAmount)) {
      return;
    }

    if (!mounted) return;

    final usesCustomAmount =
        _useCustomFormula && _customFormulaMode == _CustomFormulaMode.amount;
    final allocationsFollowIncome =
        _allocationsFollowIncome && !usesCustomAmount;

    final period = await ref
        .read(transactionActionProvider.notifier)
        .addBudgetPeriod(
          startDate: startDate,
          endDate: endDate,
          initialIncome: initialIncome,
          incomeSource: incomeSource,
          defaultAllocations: allocations,
          allocationsFollowIncome: allocationsFollowIncome,
          carryOverFromPeriodId:
              _transferPreviousRemaining && carryOverCandidate != null
              ? carryOverCandidate.period.id
              : null,
        );

    if (!mounted) return;
    AppToast.show(
      context,
      context.trf('financial_period_period_added_successfully', {
        'period': DateFormatter.periodFull(period.startDate, period.endDate),
      }),
    );
    Navigator.pop(context);
  }

  void _addDefaultBudget() {
    final controller = _trackedController();
    setState(() {
      _budgetNameControllers.add(controller);
      _customPercentageControllers.add(_trackedController());
      _customAmountControllers.add(_trackedController());
      _selectedFormulaIndex = 0;
    });
  }

  void _removeDefaultBudget(int index) {
    final controller = _budgetNameControllers.removeAt(index);
    final percentageController = _customPercentageControllers.removeAt(index);
    final amountController = _customAmountControllers.removeAt(index);
    controller
      ..removeListener(_refreshPreview)
      ..dispose();
    percentageController
      ..removeListener(_refreshPreview)
      ..dispose();
    amountController
      ..removeListener(_refreshPreview)
      ..dispose();
    setState(() => _selectedFormulaIndex = 0);
  }

  Future<void> _confirmRemoveDefaultBudget(int index) async {
    final name = _budgetNameControllers[index].text.trim();
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: context.tr('delete_budget_plan'),
      message: context.l10n.categoryDeleteMessage(
        name.isEmpty ? '${context.tr('budget')} ${index + 1}' : name,
      ),
    );
    if (!confirmed || !mounted) return;

    _removeDefaultBudget(index);
  }

  TextEditingController _trackedController([String? text]) {
    final controller = TextEditingController(text: text);
    controller.addListener(_refreshPreview);
    return controller;
  }

  void _seedCustomPercentages(List<int> percentages) {
    final allEmpty = _customPercentageControllers.every(
      (controller) => controller.text.trim().isEmpty,
    );
    if (!allEmpty ||
        percentages.length != _customPercentageControllers.length) {
      return;
    }

    for (var index = 0; index < percentages.length; index++) {
      _customPercentageControllers[index].text = '${percentages[index]}';
    }
  }

  bool _validateCustomAllocations(int initialIncome) {
    if (_customFormulaMode == _CustomFormulaMode.percentage) {
      final percentages = _customPercentages;
      if (percentages.any((value) => value <= 0)) {
        AppToast.show(
          context,
          context.tr('all_custom_percentages_must_be_greater_than_0'),
        );
        return false;
      }
      final total = percentages.fold<int>(0, (sum, value) => sum + value);
      if (total != 100) {
        AppToast.show(
          context,
          context.tr('total_percentage_must_be_exactly_100'),
        );
        return false;
      }
      return true;
    }

    final amounts = _customAmounts;
    if (amounts.any((value) => value <= 0)) {
      AppToast.show(
        context,
        context.tr('all_custom_amounts_must_be_greater_than_0'),
      );
      return false;
    }
    final total = amounts.fold<int>(0, (sum, value) => sum + value);
    if (total > initialIncome) {
      AppToast.show(
        context,
        context.trf('total_amount_exceeds_the_opening_balance_of_amount', {
          'amount': RupiahFormatter.format(initialIncome),
        }),
      );
      return false;
    }
    return true;
  }

  List<_FormulaTemplate> _formulaTemplates(
    BuildContext context,
    int categoryCount,
  ) {
    _FormulaTemplate formula(
      String name,
      String descriptionKey,
      List<int> percentages,
    ) {
      return _FormulaTemplate(
        name: name,
        description: context.tr(descriptionKey),
        percentages: percentages,
      );
    }

    switch (categoryCount) {
      case 1:
        return [
          formula('100', 'formula_all_to_one', [100]),
        ];
      case 2:
        return [
          formula('80/20', 'formula_main_then_other', [80, 20]),
          formula('70/30', 'formula_main_and_support', [70, 30]),
          formula('60/40', 'formula_two_important', [60, 40]),
          formula('50/50', 'formula_even_two', [50, 50]),
          formula('90/10', 'formula_almost_all_main', [90, 10]),
        ];
      case 3:
        return [
          formula('50/30/20', 'formula_main_flexible_savings', [50, 30, 20]),
          formula('50/25/25', 'formula_main_two_balanced', [50, 25, 25]),
          formula('60/30/10', 'formula_required_costs_high', [60, 30, 10]),
          formula('60/20/20', 'formula_required_high_two_funded', [60, 20, 20]),
          formula('70/20/10', 'formula_lean_essential_high', [70, 20, 10]),
          formula('80/10/10', 'formula_most_required', [80, 10, 10]),
          formula('40/30/30', 'formula_flexible_two_others', [40, 30, 30]),
        ];
      case 4:
        return [
          formula(
            '50/30/10/10',
            'formula_needs_flexible_entertainment_others',
            [50, 30, 10, 10],
          ),
          formula('50/20/20/10', 'formula_503020_four', [50, 20, 20, 10]),
          formula('40/30/20/10', 'formula_balanced_four', [40, 30, 20, 10]),
          formula('40/30/15/15', 'formula_large_flexible_two_small', [
            40,
            30,
            15,
            15,
          ]),
          formula('60/20/10/10', 'formula_high_required_controlled', [
            60,
            20,
            10,
            10,
          ]),
          formula('60/30/5/5', 'formula_603010_four', [60, 30, 5, 5]),
          formula('65/15/10/10', 'formula_high_daily_expensive', [
            65,
            15,
            10,
            10,
          ]),
          formula('70/10/10/10', 'formula_prioritize_required', [
            70,
            10,
            10,
            10,
          ]),
          formula('80/10/5/5', 'formula_very_strict_main', [80, 10, 5, 5]),
          formula('25/25/25/25', 'formula_even_four', [25, 25, 25, 25]),
        ];
      case 5:
        return [
          formula('50/20/10/10/10', 'formula_503020_five', [
            50,
            20,
            10,
            10,
            10,
          ]),
          formula('40/20/20/10/10', 'formula_lighter_main', [
            40,
            20,
            20,
            10,
            10,
          ]),
          formula('60/15/10/10/5', 'formula_dominant_required_small_reserve', [
            60,
            15,
            10,
            10,
            5,
          ]),
          formula('70/10/10/5/5', 'formula_lean_five', [70, 10, 10, 5, 5]),
          formula('30/25/20/15/10', 'formula_gradual_priority', [
            30,
            25,
            20,
            15,
            10,
          ]),
        ];
      default:
        return [
          formula(
            context.tr('formula_priority'),
            'formula_first_larger_rest_even',
            _priorityPercentages(categoryCount),
          ),
          _FormulaTemplate(
            name: context.tr('formula_balanced'),
            description: context.trf('formula_even_categories', {
              'count': categoryCount,
            }),
            percentages: _equalPercentages(categoryCount),
          ),
        ];
    }
  }

  List<int> _priorityPercentages(int count) {
    if (count <= 0) return const [];
    if (count == 1) return const [100];

    final first = count <= 6 ? 50 : 40;
    final remaining = 100 - first;
    final base = remaining ~/ (count - 1);
    final remainder = remaining - (base * (count - 1));

    return [
      first,
      for (var index = 1; index < count; index++)
        index == count - 1 ? base + remainder : base,
    ];
  }

  List<int> _equalPercentages(int count) {
    if (count <= 0) return const [];
    final base = 100 ~/ count;
    final remainder = 100 - (base * count);
    return [
      for (var index = 0; index < count; index++)
        index == count - 1 ? base + remainder : base,
    ];
  }

  List<BudgetAllocationDraft> _buildAllocations(
    List<String> names,
    List<int> percentages,
    int totalAmount,
  ) {
    final rows = <BudgetAllocationDraft>[];
    var usedAmount = 0;

    for (var index = 0; index < names.length; index++) {
      final percentage = percentages[index];
      final isLast = index == names.length - 1;
      final amount = isLast
          ? totalAmount - usedAmount
          : ((totalAmount * percentage) / 100).round();

      usedAmount += amount;
      rows.add(
        BudgetAllocationDraft(
          name: names[index],
          percentage: percentage,
          amount: amount,
        ),
      );
    }

    return rows;
  }

  List<BudgetAllocationDraft> _buildCustomAllocations(
    List<String> names,
    int totalAmount,
  ) {
    if (_customFormulaMode == _CustomFormulaMode.percentage) {
      return _buildAllocations(names, _customPercentages, totalAmount);
    }

    final amounts = _customAmounts;
    return [
      for (var index = 0; index < names.length; index++)
        BudgetAllocationDraft(
          name: names[index],
          percentage: totalAmount <= 0
              ? 0
              : _percentageFromAmount(amounts[index], totalAmount),
          amount: amounts[index],
        ),
    ];
  }

  num _percentageFromAmount(int amount, int totalAmount) {
    if (totalAmount <= 0) return 0;
    final value = (amount / totalAmount) * 100;
    final rounded = double.parse(value.toStringAsFixed(6));
    if (rounded == rounded.roundToDouble()) return rounded.toInt();
    return rounded;
  }

  List<int> get _customPercentages {
    return [
      for (final controller in _customPercentageControllers)
        int.tryParse(controller.text.trim()) ?? 0,
    ];
  }

  List<int> get _customAmounts {
    return [
      for (final controller in _customAmountControllers)
        CurrencyInputFormatter.parse(controller.text),
    ];
  }

  _CarryOverCandidate? _carryOverCandidate(List<BudgetSnapshot> snapshots) {
    final startDate = _startDate;
    if (startDate == null) return null;

    final previousSnapshots =
        snapshots
            .where((snapshot) => snapshot.period.endDate.isBefore(startDate))
            .toList()
          ..sort((a, b) => b.period.endDate.compareTo(a.period.endDate));
    if (previousSnapshots.isEmpty) return null;

    final previous = previousSnapshots.first;
    final amount = previous.period.totalIncome - previous.totalExpense;
    if (amount == 0) return null;

    return _CarryOverCandidate(snapshot: previous, amount: amount);
  }

  DateTime _initialVisibleMonth(List<BudgetPeriod> periods) {
    if (periods.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month);
    }

    final latestEnd = periods
        .map((period) => _dateOnly(period.endDate))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final nextAvailable = latestEnd.add(const Duration(days: 1));
    return DateTime(nextAvailable.year, nextAvailable.month);
  }

  void _handleDateTap(List<BudgetPeriod> periods, DateTime date) {
    if (_isDateOccupied(periods, date)) return;

    setState(() {
      if (_startDate == null ||
          (_startDate != null && _endDate != null) ||
          date.isBefore(_startDate!)) {
        _startDate = date;
        _endDate = null;
        return;
      }

      if (_rangeOverlapsExistingPeriod(periods, _startDate!, date)) {
        AppToast.show(
          context,
          context.tr('the_selected_date_overlaps_with_an_existing_period'),
        );
        return;
      }

      _endDate = date;
    });
  }

  bool _isDateOccupied(List<BudgetPeriod> periods, DateTime date) {
    final normalizedDate = _dateOnly(date);

    return periods.any((period) {
      final start = _dateOnly(period.startDate);
      final end = _dateOnly(period.endDate);
      return !normalizedDate.isBefore(start) && !normalizedDate.isAfter(end);
    });
  }

  bool _rangeOverlapsExistingPeriod(
    List<BudgetPeriod> periods,
    DateTime startDate,
    DateTime endDate,
  ) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    return periods.any((period) {
      final periodStart = _dateOnly(period.startDate);
      final periodEnd = _dateOnly(period.endDate);
      return !end.isBefore(periodStart) && !start.isAfter(periodEnd);
    });
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }
}

class _FormulaTemplate {
  final String name;
  final String description;
  final List<int> percentages;

  const _FormulaTemplate({
    required this.name,
    required this.description,
    required this.percentages,
  });
}

class _CarryOverCandidate {
  final BudgetSnapshot snapshot;
  final int amount;

  const _CarryOverCandidate({required this.snapshot, required this.amount});

  BudgetPeriod get period => snapshot.period;
  bool get isDeficit => amount < 0;
  int get displayAmount => amount.abs();
}

enum _CustomFormulaMode { percentage, amount }

class _CarryOverCard extends StatelessWidget {
  final _CarryOverCandidate candidate;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _CarryOverCard({
    required this.candidate,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDeficit = candidate.isDeficit;
    final accent = isDeficit ? AppColors.danger : AppColors.primary;
    final periodLabel = DateFormatter.periodFull(
      candidate.period.startDate,
      candidate.period.endDate,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onChanged(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.12)
                    : AppColors.cream.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: selected ? accent : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.trf(
                      isDeficit
                          ? 'cover_previous_period_deficit_from_period'
                          : 'transfer_remaining_money_from_period',
                      {'period': periodLabel},
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr(
                      isDeficit
                          ? 'recorded_as_covering_previous_period'
                          : 'recorded_as_transfer_to_this_period',
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              RupiahFormatter.format(candidate.displayAmount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actionLabel != null && onActionTap != null)
          TextButton.icon(
            onPressed: onActionTap,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _DefaultBudgetField extends StatelessWidget {
  final TextEditingController controller;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;

  const _DefaultBudgetField({
    required this.controller,
    required this.index,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: context.tr('category_name'),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: canDelete ? onDelete : null,
          icon: const Icon(Icons.delete_outline),
          color: canDelete ? AppColors.danger : AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _FormulaCard extends StatelessWidget {
  final _FormulaTemplate formula;
  final bool selected;
  final VoidCallback onTap;

  const _FormulaCard({
    required this.formula,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintSurface : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.mintSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                formula.name.split('/').first,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formula.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr(formula.description),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _CustomFormulaCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CustomFormulaCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintSurface : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.mintSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('customize'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr(
                      'enter_percentages_or_amounts_for_each_category',
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _CustomFormulaModeSelector extends StatelessWidget {
  final _CustomFormulaMode mode;
  final ValueChanged<_CustomFormulaMode> onChanged;

  const _CustomFormulaModeSelector({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CompactModePill(
              label: context.tr('percentage'),
              selected: mode == _CustomFormulaMode.percentage,
              onTap: () => onChanged(_CustomFormulaMode.percentage),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _CompactModePill(
              label: context.tr('rupiah'),
              selected: mode == _CustomFormulaMode.amount,
              onTap: () => onChanged(_CustomFormulaMode.amount),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactModePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CompactModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CustomAllocationField extends StatelessWidget {
  final String name;
  final TextEditingController controller;
  final _CustomFormulaMode mode;

  const _CustomAllocationField({
    required this.name,
    required this.controller,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final isAmount = mode == _CustomFormulaMode.amount;

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: isAmount ? [CurrencyInputFormatter()] : null,
      decoration: InputDecoration(
        labelText: name,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: isAmount ? const _CurrencyPrefix() : null,
        prefixIconConstraints: isAmount
            ? const BoxConstraints(minWidth: 52)
            : null,
        suffixText: isAmount ? null : '%',
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _CurrencyPrefix extends StatelessWidget {
  const _CurrencyPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 8),
      child: Text(
        CurrencyFormatterPreference.current.symbol,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AllocationModeSelector extends StatelessWidget {
  final bool allocationsFollowIncome;
  final ValueChanged<bool> onChanged;

  const _AllocationModeSelector({
    required this.allocationsFollowIncome,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModePill(
              title: context.tr('follows_income'),
              description: context.tr('amount_changes_when_income_changes'),
              selected: allocationsFollowIncome,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModePill(
              title: context.tr('fixed_amount'),
              description: context.tr('amount_is_not_recalculated'),
              selected: !allocationsFollowIncome,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ModePill({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationPreview extends StatelessWidget {
  final List<BudgetAllocationDraft> allocations;

  const _AllocationPreview({required this.allocations});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final allocation in allocations) ...[
            _AllocationPreviewRow(allocation: allocation),
            if (allocation != allocations.last)
              Divider(color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _AllocationPreviewRow extends StatelessWidget {
  final BudgetAllocationDraft allocation;

  const _AllocationPreviewRow({required this.allocation});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            allocation.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '${_formatPercentage(allocation.percentage)}%',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 116,
          child: Text(
            RupiahFormatter.format(allocation.amount),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  String _formatPercentage(num value) {
    final normalized = double.parse(value.toStringAsFixed(2));
    if (normalized == normalized.roundToDouble()) {
      return normalized.toInt().toString();
    }
    return normalized.toStringAsFixed(2);
  }
}

class _SelectedRangeCard extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const _SelectedRangeCard({required this.startDate, required this.endDate});

  @override
  Widget build(BuildContext context) {
    final label = startDate == null
        ? context.tr('choose_start_and_end_date')
        : endDate == null
        ? context.trf('start_date_value', {
            'date': DateFormatter.full(startDate!),
          })
        : DateFormatter.periodFull(startDate!, endDate!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.date_range_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
