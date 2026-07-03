import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme_palette.dart';
import '../../../../core/formatters/currency_input_formatter.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/formatters/rupiah_formatter.dart';
import '../../../../core/layout/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_calendar.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../finance/domain/entities/budget_allocation_draft.dart';
import '../../../finance/presentation/providers/transaction_action_provider.dart';
import '../../../finance/presentation/widgets/transaction_form/amount_input.dart';
import '../../../settings/domain/entities/app_currency.dart';
import '../../../settings/domain/entities/app_language.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, required this.initialSettings});

  final AppSettings initialSettings;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  static const _stepTitles = [
    'profile',
    'preferences',
    'period',
    'opening_balance',
    'category',
    'allocation',
    'review',
  ];

  final _pageController = PageController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _categoryControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _customPercentageControllers = <TextEditingController>[
    TextEditingController(),
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
    TextEditingController(),
  ];

  int _stepIndex = 0;
  String _themeId = AppThemePalettes.tealBalance.id;
  AppLanguage _language = AppLanguage.id;
  AppCurrency _currency = AppCurrency.idr;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _incomeDate = DateTime.now();
  int _selectedFormulaIndex = 0;
  bool _useCustomAllocation = false;
  _CustomAllocationMode _customAllocationMode =
      _CustomAllocationMode.percentage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialSettings.hasCompletedSetup
        ? widget.initialSettings.displayName
        : '';
    _themeId = widget.initialSettings.themeId;
    _language = widget.initialSettings.language;
    _currency = widget.initialSettings.currency;
    final copy = AppLocalizations(_language);
    _categoryControllers[0].text = copy.tr('default_daily_needs');
    _categoryControllers[1].text = copy.tr('default_entertainment');
    _categoryControllers[2].text = copy.tr('default_others');
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate!.add(const Duration(days: 30));
    _incomeDate = _startDate!;
    for (final controller in [
      ..._categoryControllers,
      ..._customPercentageControllers,
      ..._customAmountControllers,
    ]) {
      controller.addListener(_refreshSetup);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _sourceController.dispose();
    for (final controller in _categoryControllers) {
      controller.removeListener(_refreshSetup);
      controller.dispose();
    }
    for (final controller in _customPercentageControllers) {
      controller.removeListener(_refreshSetup);
      controller.dispose();
    }
    for (final controller in _customAmountControllers) {
      controller.removeListener(_refreshSetup);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(transactionActionProvider);
    final palette = AppThemePalettes.byId(_themeId);
    CurrencyFormatterPreference.current = _currency;
    DateFormatterPreference.current = _language;
    final allocations = _buildAllocations();
    final canGoBack = _stepIndex > 0;

    return AppLocalizationsScope(
      localizations: AppLocalizations(_language),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background,
                AppColors.surface,
                AppColors.mintSurface.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _ProfileStep(
                        stepIndex: 0,
                        totalSteps: _stepTitles.length,
                        nameController: _nameController,
                      ),
                      _PreferenceStep(
                        stepIndex: 1,
                        totalSteps: _stepTitles.length,
                        selectedThemeId: _themeId,
                        selectedLanguage: _language,
                        selectedCurrency: _currency,
                        onThemeChanged: (value) =>
                            setState(() => _themeId = value),
                        onLanguageChanged: (value) =>
                            setState(() => _language = value),
                        onCurrencyChanged: (value) =>
                            setState(() => _currency = value),
                      ),
                      _PeriodStep(
                        stepIndex: 2,
                        totalSteps: _stepTitles.length,
                        startDate: _startDate,
                        endDate: _endDate,
                        onPickStart: () => _pickDate(
                          initialDate: _startDate ?? DateTime.now(),
                          onChanged: (date) {
                            setState(() {
                              _startDate = date;
                              if (_endDate == null ||
                                  !_endDate!.isAfter(date)) {
                                _endDate = date.add(const Duration(days: 30));
                              }
                              _incomeDate = _clampDate(
                                _incomeDate,
                                date,
                                _endDate!,
                              );
                            });
                          },
                        ),
                        onPickEnd: () => _pickDate(
                          initialDate: _endDate ?? DateTime.now(),
                          minimumDate: _startDate,
                          onChanged: (date) {
                            setState(() {
                              _endDate = date;
                              if (_startDate != null) {
                                _incomeDate = _clampDate(
                                  _incomeDate,
                                  _startDate!,
                                  date,
                                );
                              }
                            });
                          },
                        ),
                      ),
                      _BalanceStep(
                        stepIndex: 3,
                        totalSteps: _stepTitles.length,
                        amountController: _amountController,
                        sourceController: _sourceController,
                        incomeDate: _incomeDate,
                        onPickDate: () => _pickDate(
                          initialDate: _incomeDate,
                          minimumDate: _startDate,
                          maximumDate: _endDate,
                          onChanged: (date) =>
                              setState(() => _incomeDate = date),
                        ),
                      ),
                      _CategoryStep(
                        stepIndex: 4,
                        totalSteps: _stepTitles.length,
                        controllers: _categoryControllers,
                        onAdd: _addCategory,
                        onRemove: _removeCategory,
                      ),
                      _AllocationStep(
                        stepIndex: 5,
                        totalSteps: _stepTitles.length,
                        formulas: _formulaTemplates(_categoryNames.length),
                        selectedIndex: _selectedFormulaIndex,
                        useCustomAllocation: _useCustomAllocation,
                        customMode: _customAllocationMode,
                        customControllers: _customPercentageControllers,
                        customAmountControllers: _customAmountControllers,
                        allocations: allocations,
                        totalAmount: _initialIncome,
                        onSelect: (index) => setState(() {
                          _useCustomAllocation = false;
                          _selectedFormulaIndex = index;
                        }),
                        onCustomSelect: () {
                          setState(() {
                            _useCustomAllocation = true;
                          });
                        },
                        onCustomModeChanged: (mode) => setState(() {
                          _customAllocationMode = mode;
                        }),
                      ),
                      _ReviewStep(
                        stepIndex: 6,
                        totalSteps: _stepTitles.length,
                        displayName: _nameController.text.trim(),
                        palette: palette,
                        language: _language,
                        currency: _currency,
                        startDate: _startDate,
                        endDate: _endDate,
                        initialIncome: _initialIncome,
                        incomeSource: _sourceController.text.trim(),
                        allocations: allocations,
                      ),
                    ],
                  ),
                ),
                _SetupFooter(
                  canGoBack: canGoBack,
                  isSaving: isSaving,
                  isLastStep: _stepIndex == _stepTitles.length - 1,
                  onBack: _previousStep,
                  onNext: isSaving ? null : _nextStep,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int get _initialIncome =>
      CurrencyInputFormatter.parse(_amountController.text);

  List<String> get _categoryNames {
    return _categoryControllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  void _nextStep() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_validateStep(_stepIndex)) return;

    if (_stepIndex == _stepTitles.length - 1) {
      _finishSetup();
      return;
    }

    setState(() => _stepIndex += 1);
    _pageController.animateToPage(
      _stepIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _previousStep() {
    if (_stepIndex == 0) return;

    setState(() => _stepIndex -= 1);
    _pageController.animateToPage(
      _stepIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  bool _validateStep(int index) {
    switch (index) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          AppToast.show(context, context.tr('enter_your_display_name_first'));
          return false;
        }
      case 2:
        final startDate = _startDate;
        final endDate = _endDate;
        if (startDate == null || endDate == null) {
          AppToast.show(
            context,
            context.tr('choose_the_period_start_and_end_dates_first'),
          );
          return false;
        }
        if (!endDate.isAfter(startDate)) {
          AppToast.show(
            context,
            context.tr('the_end_date_must_be_after_the_start_date_2'),
          );
          return false;
        }
      case 3:
        if (_initialIncome <= 0) {
          AppToast.show(
            context,
            context.tr('enter_the_opening_balance_first_2'),
          );
          return false;
        }
        if (_sourceController.text.trim().isEmpty) {
          AppToast.show(
            context,
            context.tr('write_the_opening_balance_source_first_2'),
          );
          return false;
        }
      case 4:
        final names = _categoryNames;
        if (names.isEmpty) {
          AppToast.show(
            context,
            context.tr('add_at_least_one_budget_category'),
          );
          return false;
        }
        if (names.toSet().length != names.length) {
          AppToast.show(
            context,
            context.tr('budget_category_names_cannot_be_duplicated_2'),
          );
          return false;
        }
      case 5:
        if (_useCustomAllocation && !_validateCustomPercentages()) {
          return false;
        }
      default:
        return true;
    }

    return true;
  }

  Future<void> _finishSetup() async {
    if (!_validateStep(0) ||
        !_validateStep(2) ||
        !_validateStep(3) ||
        !_validateStep(4) ||
        !_validateStep(5)) {
      return;
    }

    final startDate = _startDate!;
    final endDate = _endDate!;
    final settings = widget.initialSettings.copyWith(
      displayName: _nameController.text.trim(),
      themeId: _themeId,
      languageCode: _language.code,
      currencyCode: _currency.code,
    );
    final usesCustomAmount =
        _useCustomAllocation &&
        _customAllocationMode == _CustomAllocationMode.amount;

    await ref
        .read(transactionActionProvider.notifier)
        .addBudgetPeriod(
          startDate: startDate,
          endDate: endDate,
          initialIncome: _initialIncome,
          incomeSource: _sourceController.text.trim(),
          defaultAllocations: _buildAllocations(),
          allocationsFollowIncome: !usesCustomAmount,
        );

    await ref.read(appSettingsProvider.notifier).completeSetup(settings);

    if (!mounted) return;
    AppToast.show(context, context.tr('setup_complete_dokido_is_ready_to_use'));
  }

  void _addCategory() {
    final categoryController = TextEditingController()
      ..addListener(_refreshSetup);
    final customController = TextEditingController()
      ..addListener(_refreshSetup);
    final customAmountController = TextEditingController()
      ..addListener(_refreshSetup);

    setState(() {
      _categoryControllers.add(categoryController);
      _customPercentageControllers.add(customController);
      _customAmountControllers.add(customAmountController);
      _selectedFormulaIndex = 0;
      _useCustomAllocation = false;
    });
  }

  void _removeCategory(int index) {
    if (_categoryControllers.length <= 1) {
      AppToast.show(
        context,
        context.tr('there_must_be_at_least_one_budget_category'),
      );
      return;
    }

    setState(() {
      final controller = _categoryControllers.removeAt(index);
      final customController = _customPercentageControllers.removeAt(index);
      final customAmountController = _customAmountControllers.removeAt(index);
      controller.removeListener(_refreshSetup);
      customController.removeListener(_refreshSetup);
      customAmountController.removeListener(_refreshSetup);
      controller.dispose();
      customController.dispose();
      customAmountController.dispose();
      _selectedFormulaIndex = 0;
      _useCustomAllocation = false;
    });
  }

  List<BudgetAllocationDraft> _buildAllocations() {
    final names = _categoryNames;
    if (names.isEmpty) return const [];

    if (_useCustomAllocation &&
        _customAllocationMode == _CustomAllocationMode.amount) {
      return _buildAmountAllocations(names);
    }

    final percentages = _useCustomAllocation
        ? _customPercentages(names.length)
        : _templatePercentages(names.length);
    if (percentages.length != names.length) return const [];
    final totalAmount = _initialIncome;
    final rows = <BudgetAllocationDraft>[];
    var usedAmount = 0;
    final totalPercentage = percentages.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final useLastRemainder = !_useCustomAllocation || totalPercentage == 100;

    for (var index = 0; index < names.length; index++) {
      final percentage = percentages[index];
      final isLast = index == names.length - 1;
      final amount = isLast && useLastRemainder
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

  List<BudgetAllocationDraft> _buildAmountAllocations(List<String> names) {
    final totalAmount = _initialIncome;
    final amounts = _customAmounts(names.length);

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

  List<int> _templatePercentages(int count) {
    final formulas = _formulaTemplates(count);
    final safeFormulaIndex = _selectedFormulaIndex >= formulas.length
        ? 0
        : _selectedFormulaIndex;
    return formulas[safeFormulaIndex].percentages;
  }

  List<int> _customPercentages(int count) {
    return [
      for (var index = 0; index < count; index++)
        int.tryParse(_customPercentageControllers[index].text.trim()) ?? 0,
    ];
  }

  List<int> _customAmounts(int count) {
    return [
      for (var index = 0; index < count; index++)
        CurrencyInputFormatter.parse(_customAmountControllers[index].text),
    ];
  }

  void _refreshSetup() {
    if (mounted) setState(() {});
  }

  bool _validateCustomPercentages() {
    final names = _categoryNames;
    if (_customAllocationMode == _CustomAllocationMode.amount) {
      return _validateCustomAmounts(names.length);
    }

    final percentages = _customPercentages(names.length);
    if (percentages.any((value) => value <= 0)) {
      AppToast.show(
        context,
        context.tr('all_percentages_must_be_greater_than_0'),
      );
      return false;
    }

    final total = percentages.fold<int>(0, (sum, value) => sum + value);
    if (total != 100) {
      AppToast.show(
        context,
        context.tr('total_percentage_must_be_exactly_100_2'),
      );
      return false;
    }

    return true;
  }

  bool _validateCustomAmounts(int count) {
    final amounts = _customAmounts(count);
    if (amounts.any((value) => value <= 0)) {
      AppToast.show(context, context.tr('all_amounts_must_be_greater_than_0'));
      return false;
    }

    final total = amounts.fold<int>(0, (sum, value) => sum + value);
    if (total > _initialIncome) {
      AppToast.show(
        context,
        context.tr('total_amount_cannot_exceed_the_opening_balance_2'),
      );
      return false;
    }

    return true;
  }

  List<_FormulaTemplate> _formulaTemplates(int count) {
    switch (count) {
      case 1:
        return const [
          _FormulaTemplate('100', [100]),
        ];
      case 2:
        return const [
          _FormulaTemplate('80/20', [80, 20]),
          _FormulaTemplate('70/30', [70, 30]),
          _FormulaTemplate('60/40', [60, 40]),
          _FormulaTemplate('50/50', [50, 50]),
        ];
      case 3:
        return const [
          _FormulaTemplate('50/30/20', [50, 30, 20]),
          _FormulaTemplate('60/20/20', [60, 20, 20]),
          _FormulaTemplate('70/20/10', [70, 20, 10]),
          _FormulaTemplate('40/30/30', [40, 30, 30]),
        ];
      case 4:
        return const [
          _FormulaTemplate('50/30/10/10', [50, 30, 10, 10]),
          _FormulaTemplate('40/30/20/10', [40, 30, 20, 10]),
          _FormulaTemplate('60/20/10/10', [60, 20, 10, 10]),
          _FormulaTemplate('25/25/25/25', [25, 25, 25, 25]),
        ];
      case 5:
        return const [
          _FormulaTemplate('50/20/10/10/10', [50, 20, 10, 10, 10]),
          _FormulaTemplate('40/20/20/10/10', [40, 20, 20, 10, 10]),
          _FormulaTemplate('30/25/20/15/10', [30, 25, 20, 15, 10]),
        ];
      default:
        return [
          _FormulaTemplate(
            context.tr('formula_priority'),
            _priorityPercentages(count),
          ),
          _FormulaTemplate(
            context.tr('formula_balanced'),
            _equalPercentages(count),
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

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onChanged,
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) async {
    final result = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minimumDate,
      lastDate: maximumDate,
    );

    if (result == null || !mounted) return;
    onChanged(result);
  }

  DateTime _clampDate(DateTime value, DateTime min, DateTime max) {
    if (value.isBefore(min)) return min;
    if (value.isAfter(max)) return max;
    return value;
  }
}

class _SetupFooter extends StatelessWidget {
  final bool canGoBack;
  final bool isSaving;
  final bool isLastStep;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  const _SetupFooter({
    required this.canGoBack,
    required this.isSaving,
    required this.isLastStep,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 52,
            child: IconButton(
              onPressed: canGoBack ? onBack : null,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onNext,
              icon: Icon(
                isLastStep
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(
                context.tr(
                  isSaving
                      ? 'saving'
                      : isLastStep
                      ? 'start'
                      : 'next',
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int stepIndex;
  final int totalSteps;
  final List<Widget> children;

  const _StepScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.stepIndex,
    required this.totalSteps,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 430,
                  minHeight: (constraints.maxHeight - 28).clamp(520, 760),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.92),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.overlay.withValues(alpha: 0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.09),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SetupIllustration(icon: icon),
                      const SizedBox(height: 22),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.overlay,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          height: 1.32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ProgressDots(
                        stepIndex: stepIndex,
                        totalSteps: totalSteps,
                      ),
                      const SizedBox(height: 24),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SetupIllustration extends StatelessWidget {
  final IconData icon;

  const _SetupIllustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 176,
        height: 156,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(176, 156),
              painter: _SetupOrbitPainter(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                accent: AppColors.mint,
              ),
            ),
            Positioned(
              top: 32,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Icon(icon, color: AppColors.primary, size: 40),
              ),
            ),
            Positioned(
              left: 26,
              bottom: 30,
              child: _MiniIllustrationTile(
                icon: Icons.check_rounded,
                color: AppColors.secondary,
              ),
            ),
            Positioned(
              right: 26,
              bottom: 34,
              child: _MiniIllustrationTile(
                icon: Icons.add_rounded,
                color: AppColors.warning,
              ),
            ),
            Positioned(
              top: 24,
              right: 42,
              child: _MiniIllustrationTile(
                icon: Icons.circle,
                color: AppColors.mint,
                small: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniIllustrationTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool small;

  const _MiniIllustrationTile({
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 24.0 : 34.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.overlay, width: 1.2),
      ),
      child: Icon(icon, color: AppColors.overlay, size: small ? 9 : 18),
    );
  }
}

class _SetupOrbitPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  final Color accent;

  const _SetupOrbitPainter({
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbitPaint = Paint()
      ..color = primary.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(
      center: center,
      width: size.width * 0.72,
      height: size.height * 0.72,
    );
    const dashCount = 22;
    for (var index = 0; index < dashCount; index++) {
      final start = (math.pi * 2 / dashCount) * index;
      canvas.drawArc(rect, start, 0.11, false, orbitPaint);
    }

    fillPaint.color = secondary.withValues(alpha: 0.28);
    canvas.drawCircle(center.translate(32, -24), 30, fillPaint);
    fillPaint.color = accent.withValues(alpha: 0.36);
    canvas.drawCircle(center.translate(-30, 18), 24, fillPaint);

    final linePaint = Paint()
      ..color = primary.withValues(alpha: 0.48)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      center.translate(-58, -18),
      center.translate(-88, -18),
      linePaint,
    );
    canvas.drawLine(
      center.translate(58, 24),
      center.translate(88, 24),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SetupOrbitPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.accent != accent;
  }
}

class _ProgressDots extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;

  const _ProgressDots({required this.stepIndex, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < totalSteps; index++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: index == stepIndex ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: index == stepIndex
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          if (index != totalSteps - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _ProfileStep extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final TextEditingController nameController;

  const _ProfileStep({
    required this.stepIndex,
    required this.totalSteps,
    required this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.person_rounded,
      title: context.tr('quick_introduction'),
      subtitle: context.tr(
        'this_name_will_be_used_in_your_profile_and_app_summaries',
      ),
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      children: [
        _FloatingOnlyTextField(
          controller: nameController,
          label: context.tr('display_name_2'),
          hintText: context.tr('write_your_name'),
          icon: Icons.badge_rounded,
        ),
      ],
    );
  }
}

class _FloatingOnlyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;

  const _FloatingOnlyTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
  });

  @override
  State<_FloatingOnlyTextField> createState() => _FloatingOnlyTextFieldState();
}

class _FloatingOnlyTextFieldState extends State<_FloatingOnlyTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(widget.icon),
      ),
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }
}

class _PreferenceStep extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final String selectedThemeId;
  final AppLanguage selectedLanguage;
  final AppCurrency selectedCurrency;
  final ValueChanged<String> onThemeChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<AppCurrency> onCurrencyChanged;

  const _PreferenceStep({
    required this.stepIndex,
    required this.totalSteps,
    required this.selectedThemeId,
    required this.selectedLanguage,
    required this.selectedCurrency,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.palette_rounded,
      title: context.tr('choose_app_style'),
      subtitle: context.tr('you_can_change_this_later_from_settings'),
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      children: [
        _SectionLabel(label: context.tr('color_theme')),
        const SizedBox(height: 10),
        for (final palette in AppThemePalettes.values) ...[
          _PaletteOptionCard(
            palette: palette,
            selected: selectedThemeId == palette.id,
            onTap: () => onThemeChanged(palette.id),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        _SectionLabel(label: context.tr('language')),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final language in AppLanguage.values) ...[
              Expanded(
                child: _ChoiceCard(
                  icon: Icons.translate_rounded,
                  label: context.tr(language.labelKey),
                  selected: selectedLanguage == language,
                  onTap: () => onLanguageChanged(language),
                ),
              ),
              if (language != AppLanguage.values.last)
                const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 18),
        _SectionLabel(label: context.tr('currency')),
        const SizedBox(height: 10),
        Column(
          children: [
            for (final currency in AppCurrency.values) ...[
              _ChoiceCard(
                icon: Icons.payments_rounded,
                label: '${currency.code} • ${context.tr(currency.labelKey)}',
                selected: selectedCurrency == currency,
                onTap: () => onCurrencyChanged(currency),
              ),
              if (currency != AppCurrency.values.last)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _PeriodStep extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const _PeriodStep({
    required this.stepIndex,
    required this.totalSteps,
    required this.startDate,
    required this.endDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.date_range_rounded,
      title: context.tr('create_your_first_period'),
      subtitle: context.tr(
        'all_money_records_will_go_into_the_period_you_choose',
      ),
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      children: [
        _DateOptionCard(
          icon: Icons.play_arrow_rounded,
          title: context.tr('start_date'),
          value: startDate == null
              ? context.tr('choose_date')
              : DateFormatter.full(startDate!),
          onTap: onPickStart,
        ),
        const SizedBox(height: 12),
        _DateOptionCard(
          icon: Icons.flag_rounded,
          title: context.tr('end_date'),
          value: endDate == null
              ? context.tr('choose_date')
              : DateFormatter.full(endDate!),
          onTap: onPickEnd,
        ),
      ],
    );
  }
}

class _BalanceStep extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final TextEditingController amountController;
  final TextEditingController sourceController;
  final DateTime incomeDate;
  final VoidCallback onPickDate;

  const _BalanceStep({
    required this.stepIndex,
    required this.totalSteps,
    required this.amountController,
    required this.sourceController,
    required this.incomeDate,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.savings_rounded,
      title: context.tr('enter_opening_balance'),
      subtitle: context.tr(
        'this_becomes_the_first_income_record_for_that_period',
      ),
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      children: [
        AmountInput(controller: amountController),
        const AppFormFieldGap(),
        _FloatingOnlyTextField(
          controller: sourceController,
          hintText: context.tr('example_main_salary_freelance_bonus'),
          label: context.tr('opening_balance_source'),
          icon: Icons.source_rounded,
        ),
        const AppFormControlGap(),
        _DateOptionCard(
          icon: Icons.event_available_rounded,
          title: context.tr('received_date'),
          value: DateFormatter.full(incomeDate),
          onTap: onPickDate,
        ),
      ],
    );
  }
}

class _CategoryStep extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _CategoryStep({
    required this.stepIndex,
    required this.totalSteps,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.account_balance_wallet_rounded,
      title: context.tr('set_up_budget_categories'),
      subtitle: context.tr('use_the_categories_you_track_most_often'),
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionLabel(label: context.tr('initial_categories')),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(context.tr('add')),
            ),
          ],
        ),
        const AppFormControlGap(),
        for (var index = 0; index < controllers.length; index++) ...[
          _CategoryField(
            controller: controllers[index],
            canDelete: controllers.length > 1,
            onDelete: () => onRemove(index),
          ),
          if (index != controllers.length - 1) const AppFormFieldGap(),
        ],
      ],
    );
  }
}

class _AllocationStep extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final List<_FormulaTemplate> formulas;
  final int selectedIndex;
  final bool useCustomAllocation;
  final _CustomAllocationMode customMode;
  final List<TextEditingController> customControllers;
  final List<TextEditingController> customAmountControllers;
  final List<BudgetAllocationDraft> allocations;
  final int totalAmount;
  final ValueChanged<int> onSelect;
  final VoidCallback onCustomSelect;
  final ValueChanged<_CustomAllocationMode> onCustomModeChanged;

  const _AllocationStep({
    required this.stepIndex,
    required this.totalSteps,
    required this.formulas,
    required this.selectedIndex,
    required this.useCustomAllocation,
    required this.customMode,
    required this.customControllers,
    required this.customAmountControllers,
    required this.allocations,
    required this.totalAmount,
    required this.onSelect,
    required this.onCustomSelect,
    required this.onCustomModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      icon: Icons.pie_chart_rounded,
      title: context.tr('choose_how_to_split_the_balance'),
      subtitle: context.tr(
        'dokido_will_calculate_category_amounts_from_your_opening_balance',
      ),
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      children: [
        _SectionLabel(label: context.tr('popular_template')),
        const SizedBox(height: 10),
        for (var index = 0; index < formulas.length; index++) ...[
          _FormulaCard(
            formula: formulas[index],
            selected: !useCustomAllocation && selectedIndex == index,
            onTap: () => onSelect(index),
          ),
          const SizedBox(height: 10),
        ],
        _CustomAllocationCard(
          selected: useCustomAllocation,
          onTap: onCustomSelect,
        ),
        if (useCustomAllocation) ...[
          const SizedBox(height: 12),
          _CustomAllocationModeSelector(
            mode: customMode,
            onChanged: onCustomModeChanged,
          ),
          if (customMode == _CustomAllocationMode.amount) ...[
            const SizedBox(height: 12),
            _RemainingCustomAmountCard(
              remainingAmount:
                  totalAmount -
                  allocations.fold<int>(
                    0,
                    (total, allocation) => total + allocation.amount,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          _SectionLabel(
            label: context.tr(
              customMode == _CustomAllocationMode.percentage
                  ? 'custom_percentage'
                  : 'custom_amount',
            ),
          ),
          const AppFormControlGap(),
          for (var index = 0; index < allocations.length; index++) ...[
            customMode == _CustomAllocationMode.percentage
                ? _CustomPercentageField(
                    name: allocations[index].name,
                    controller: customControllers[index],
                  )
                : _CustomAmountField(
                    name: allocations[index].name,
                    controller: customAmountControllers[index],
                  ),
            if (index != allocations.length - 1) const AppFormFieldGap(),
          ],
        ],
        const SizedBox(height: 8),
        _AllocationPreview(allocations: allocations),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final String displayName;
  final AppThemePalette palette;
  final AppLanguage language;
  final AppCurrency currency;
  final DateTime? startDate;
  final DateTime? endDate;
  final int initialIncome;
  final String incomeSource;
  final List<BudgetAllocationDraft> allocations;

  const _ReviewStep({
    required this.stepIndex,
    required this.totalSteps,
    required this.displayName,
    required this.palette,
    required this.language,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.initialIncome,
    required this.incomeSource,
    required this.allocations,
  });

  @override
  Widget build(BuildContext context) {
    final allocated = allocations.fold<int>(
      0,
      (total, allocation) => total + allocation.amount,
    );
    final remaining = initialIncome - allocated;

    return _StepScaffold(
      icon: Icons.fact_check_rounded,
      title: context.tr('review_before_starting'),
      subtitle: context.tr(
        'if_everything_looks_right_dokido_will_prepare_your_dashboard',
      ),
      stepIndex: stepIndex,
      totalSteps: totalSteps,
      children: [
        _ReviewCard(
          rows: [
            _ReviewRowData(context.tr('name'), displayName),
            _ReviewRowData(context.tr('theme'), context.tr(palette.nameKey)),
            _ReviewRowData(
              context.tr('language'),
              context.tr(language.labelKey),
            ),
            _ReviewRowData(
              context.tr('currency'),
              '${currency.code} • ${context.tr(currency.labelKey)}',
            ),
            _ReviewRowData(
              context.tr('period'),
              startDate == null || endDate == null
                  ? '-'
                  : DateFormatter.periodFull(startDate!, endDate!),
            ),
            _ReviewRowData(
              context.tr('opening_balance'),
              RupiahFormatter.format(initialIncome),
            ),
            _ReviewRowData(
              context.tr('balance_source'),
              incomeSource.isEmpty ? '-' : incomeSource,
            ),
            _ReviewRowData(
              context.tr('unallocated_balance_2'),
              RupiahFormatter.format(remaining),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AllocationPreview(allocations: allocations),
      ],
    );
  }
}

class _PaletteOptionCard extends StatelessWidget {
  final AppThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteOptionCard({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? palette.accent.withValues(alpha: 0.32)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? palette.primary : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Row(
              children: [
                for (final color in [
                  palette.primary,
                  palette.secondary,
                  palette.accent,
                  palette.background,
                ])
                  Container(
                    width: 20,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(palette.nameKey),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr(palette.description),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: palette.primary),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _DateOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _DateOptionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.mintSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  final TextEditingController controller;
  final bool canDelete;
  final VoidCallback onDelete;

  const _CategoryField({
    required this.controller,
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
              prefixIcon: const Icon(Icons.wallet_rounded),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: canDelete ? onDelete : null,
          icon: const Icon(Icons.delete_outline_rounded),
          color: canDelete ? AppColors.danger : AppColors.textSecondary,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.creamSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                formula.percentages.first.toString(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr(formula.name),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _CustomAllocationCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _CustomAllocationCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.creamSurface,
                borderRadius: BorderRadius.circular(14),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _CustomAllocationModeSelector extends StatelessWidget {
  final _CustomAllocationMode mode;
  final ValueChanged<_CustomAllocationMode> onChanged;

  const _CustomAllocationModeSelector({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeSegment(
              label: context.tr('percentage'),
              icon: Icons.percent_rounded,
              selected: mode == _CustomAllocationMode.percentage,
              onTap: () => onChanged(_CustomAllocationMode.percentage),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeSegment(
              label: context.tr('amount_2'),
              icon: Icons.payments_rounded,
              selected: mode == _CustomAllocationMode.amount,
              onTap: () => onChanged(_CustomAllocationMode.amount),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomPercentageField extends StatelessWidget {
  final String name;
  final TextEditingController controller;

  const _CustomPercentageField({required this.name, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: name,
        hintText: context.tr('example_50'),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.percent_rounded),
        suffixText: '%',
      ),
    );
  }
}

class _CustomAmountField extends StatelessWidget {
  final String name;
  final TextEditingController controller;

  const _CustomAmountField({required this.name, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [CurrencyInputFormatter()],
      decoration: InputDecoration(
        labelText: name,
        hintText: context.tr('example_1_000_000'),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const _CurrencyWithIconPrefix(),
        prefixIconConstraints: const BoxConstraints(minWidth: 78),
      ),
    );
  }
}

class _CurrencyWithIconPrefix extends StatelessWidget {
  const _CurrencyWithIconPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.payments_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            CurrencyFormatterPreference.current.symbol,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemainingCustomAmountCard extends StatelessWidget {
  final int remainingAmount;

  const _RemainingCustomAmountCard({required this.remainingAmount});

  @override
  Widget build(BuildContext context) {
    final isNegative = remainingAmount < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isNegative
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.mintSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNegative
              ? AppColors.danger.withValues(alpha: 0.28)
              : AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNegative ? Icons.warning_amber_rounded : Icons.savings_outlined,
            color: isNegative ? AppColors.danger : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('remaining_custom_amount'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            RupiahFormatter.format(remainingAmount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isNegative ? AppColors.danger : AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationPreview extends StatelessWidget {
  final List<BudgetAllocationDraft> allocations;

  const _AllocationPreview({required this.allocations});

  @override
  Widget build(BuildContext context) {
    if (allocations.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalAmount = allocations.fold<int>(
      0,
      (total, allocation) => total + allocation.amount,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: context.tr('allocation_preview')),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.mintSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('amount'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  RupiahFormatter.format(totalAmount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final allocation in allocations) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${allocation.name} (${_formatPercentage(allocation.percentage)}%)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  RupiahFormatter.format(allocation.amount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (allocation != allocations.last) const SizedBox(height: 8),
          ],
        ],
      ),
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

class _ReviewCard extends StatelessWidget {
  final List<_ReviewRowData> rows;

  const _ReviewCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final row in rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (row != rows.last)
              Divider(
                height: 18,
                color: AppColors.border.withValues(alpha: 0.72),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _FormulaTemplate {
  final String name;
  final List<int> percentages;

  const _FormulaTemplate(this.name, this.percentages);
}

enum _CustomAllocationMode { percentage, amount }

class _ReviewRowData {
  final String label;
  final String value;

  const _ReviewRowData(this.label, this.value);
}
