import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/formatters/rupiah_formatter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/budget_period.dart';
import '../../domain/entities/budget_snapshot.dart';
import '../../domain/entities/category_budget.dart';
import '../../domain/entities/recurring_due_item.dart';
import '../../domain/entities/transaction_type.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../providers/current_budget_provider.dart';
import '../providers/selected_period_provider.dart';
import '../providers/transaction_action_provider.dart';
import '../providers/transaction_template_provider.dart';
import '../widgets/dashboard/budget_category_grid.dart';
import '../widgets/dashboard/category_adjustment_sheet.dart';
import '../widgets/dashboard/category_edit_sheet.dart';
import '../widgets/dashboard/history_tab_body.dart';
import '../widgets/dashboard/period_selector_sheet.dart';
import '../widgets/dashboard/period_edit_sheet.dart';
import '../widgets/dashboard/period_statistics_chart.dart';
import '../widgets/dashboard/period_summary_card.dart';
// ProfileTabBody tetap tersedia untuk diaktifkan kembali setelah tab Profil
// dikembalikan ke footer.
// import '../widgets/dashboard/profile_tab_body.dart';
import '../widgets/dashboard/quick_action_sheet.dart';
import '../widgets/dashboard/settings_tab_body.dart';
import '../widgets/transaction_type_icon.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(currentBudgetProvider);
    final periodsAsync = ref.watch(budgetPeriodsProvider);
    final selectedPeriodId = ref.watch(selectedPeriodIdProvider);
    final isSaving = ref.watch(transactionActionProvider);
    final settings = ref.watch(appSettingsProvider).asData?.value;
    FinancialPrivacyPreference.hideAmounts =
        settings?.hideFinancialAmounts ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_selectedIndex) {
          2 => context.tr('activity_history'),
          3 => context.tr('settings'),
          _ => 'DokiDo',
        }),
        // actions: [
        //   IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        //   IconButton(
        //     onPressed: () {},
        //     icon: const Icon(Icons.notifications_none),
        //   ),
        // ],
      ),
      body: budgetAsync.when(
        loading: () => _DashboardLoadingView(selectedIndex: _selectedIndex),
        error: (error, _) => ErrorView(error: error),
        data: (snapshot) {
          if (snapshot == null) {
            return RefreshIndicator(
              onRefresh: () => ref.refresh(currentBudgetProvider.future),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (_selectedIndex == 0)
                    _EmptyPeriodTab(
                      title: context.tr('no_financial_period_yet'),
                      message: context.tr(
                        'create_your_first_period_so_income_expenses_and_budget_categories_can_be',
                      ),
                      onActionTap: () =>
                          Navigator.pushNamed(context, AppRouter.addPeriod),
                    )
                  else if (_selectedIndex == 1)
                    _EmptyPeriodTab(
                      title: context.tr('budget_cannot_be_created_yet'),
                      message: context.tr(
                        'add_a_financial_period_first_then_organize_budget_categories_for_that_pe',
                      ),
                      onActionTap: () =>
                          Navigator.pushNamed(context, AppRouter.addPeriod),
                    )
                  else if (_selectedIndex == 2)
                    const HistoryTabBody()
                  else
                    const SettingsTabBody(),
                ],
              ),
            );
          }

          final showPeriodHero = _selectedIndex <= 1;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(currentBudgetProvider.future),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (showPeriodHero)
                  PeriodSummaryCard(
                    period: snapshot.period,
                    totalExpense: snapshot.totalExpense,
                    amountsHidden: settings?.hideFinancialAmounts ?? false,
                    onPrivacyToggle: () {
                      ref
                          .read(appSettingsProvider.notifier)
                          .toggleFinancialPrivacy();
                    },
                    onPeriodTap: () {
                      periodsAsync.whenData((periods) {
                        _showPeriodSelector(
                          context: context,
                          periods: periods,
                          selectedPeriodId:
                              selectedPeriodId ?? snapshot.period.id,
                          isAdding: isSaving,
                        );
                      });
                    },
                    onIncomeTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.incomeDetail,
                        arguments: snapshot.period.id,
                      );
                    },
                    onExpenseTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.expenseDetail,
                        arguments: snapshot.period.id,
                      );
                    },
                  ),
                if (_selectedIndex == 0) ...[
                  _DashboardTabBody(currentSnapshot: snapshot),
                ] else if (_selectedIndex == 1) ...[
                  _BudgetTabBody(
                    snapshot: snapshot,
                    onAddTap: () {
                      _showQuickActionSheet();
                    },
                    onCategoryTap: (category) {
                      Navigator.pushNamed(
                        context,
                        AppRouter.categoryDetail,
                        arguments: category.id,
                      );
                    },
                    onCategoryEdit: _showCategoryEditSheet,
                    onCategoryIncrease: (category) =>
                        _showCategoryAdjustmentSheet(
                          category,
                          CategoryAdjustmentAction.increase,
                        ),
                    onCategoryDecrease: (category) =>
                        _showCategoryAdjustmentSheet(
                          category,
                          CategoryAdjustmentAction.decrease,
                        ),
                    onCategorySetAmount: (category) =>
                        _showCategoryAdjustmentSheet(
                          category,
                          CategoryAdjustmentAction.setAmount,
                        ),
                    onCategoryDelete: _deleteCategory,
                    onCategoryDeleteBlocked: (_) {
                      AppToast.show(
                        context,
                        context.tr(
                          'this_budget_category_cannot_be_deleted_because_it_already_has_history',
                        ),
                      );
                    },
                  ),
                ] else ...[
                  if (_selectedIndex == 2)
                    const HistoryTabBody()
                  else
                    const SettingsTabBody(),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _DashboardFooter(
        selectedIndex: _selectedIndex,
        onChanged: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  void _showQuickActionSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const QuickActionSheet(),
    );
  }

  Future<void> _showCategoryEditSheet(CategoryBudget category) async {
    final snapshot = await ref.read(currentBudgetProvider.future);
    if (!mounted) return;
    if (snapshot == null) {
      AppToast.show(context, context.tr('create_a_financial_period_first'));
      return;
    }

    final result = await showModalBottomSheet<CategoryEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryEditSheet(category: category),
    );
    if (result == null || !mounted) return;

    await ref
        .read(transactionActionProvider.notifier)
        .updateCategory(
          periodId: snapshot.period.id,
          categoryId: category.id,
          name: result.name,
        );
    if (!mounted) return;
    AppToast.show(context, context.tr('budget_category_updated_successfully'));
  }

  Future<void> _showCategoryAdjustmentSheet(
    CategoryBudget category,
    CategoryAdjustmentAction action,
  ) async {
    final snapshot = await ref.read(currentBudgetProvider.future);
    if (!mounted) return;
    if (snapshot == null) {
      AppToast.show(context, context.tr('create_a_financial_period_first'));
      return;
    }

    final result = await showModalBottomSheet<CategoryAdjustmentResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryAdjustmentSheet(
        category: category,
        categories: snapshot.categories,
        action: action,
      ),
    );
    if (result == null || !mounted) return;

    try {
      await ref
          .read(transactionActionProvider.notifier)
          .adjustCategoryBudget(
            periodId: snapshot.period.id,
            categoryId: category.id,
            action: result.action,
            amount: result.amount,
            reason: result.reason,
            date: DateTime.now(),
            relatedCategoryId: result.relatedCategoryId,
          );
      if (!mounted) return;
      AppToast.show(context, context.tr('budget_adjusted_successfully'));
    } on StateError catch (error) {
      if (!mounted) return;
      AppToast.show(context, context.tr(error.message));
    }
  }

  Future<void> _deleteCategory(CategoryBudget category) async {
    final snapshot = await ref.read(currentBudgetProvider.future);
    if (!mounted) return;
    if (snapshot == null) {
      AppToast.show(context, context.tr('create_a_financial_period_first'));
      return;
    }

    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: context.tr('delete_budget_category'),
      message: context.l10n.budgetDeleteMessage(category.name),
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(transactionActionProvider.notifier)
        .deleteCategory(periodId: snapshot.period.id, categoryId: category.id);
    if (!mounted) return;
    AppToast.show(context, context.tr('budget_category_deleted_successfully'));
  }

  Future<void> _showPeriodSelector({
    required BuildContext context,
    required List<BudgetPeriod> periods,
    required String selectedPeriodId,
    required bool isAdding,
  }) async {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => PeriodSelectorSheet(
        periods: periods,
        selectedPeriodId: selectedPeriodId,
        isAdding: isAdding,
        onSelect: (periodId) {
          ref.read(selectedPeriodIdProvider.notifier).select(periodId);
          Navigator.pop(context);
        },
        onEditPeriod: (period) async {
          Navigator.pop(context);
          await _showPeriodEditSheet(periods, period);
        },
        onDeletePeriod: (period) async {
          Navigator.pop(context);
          await _deletePeriod(period);
        },
        onAddPeriod: () async {
          Navigator.pop(context);
          await Navigator.pushNamed(context, AppRouter.addPeriod);
        },
      ),
    );
  }

  Future<void> _showPeriodEditSheet(
    List<BudgetPeriod> periods,
    BudgetPeriod period,
  ) async {
    final result = await showModalBottomSheet<PeriodEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PeriodEditSheet(period: period, periods: periods),
    );
    if (result == null || !mounted) return;

    try {
      await ref
          .read(transactionActionProvider.notifier)
          .updateBudgetPeriod(
            periodId: period.id,
            startDate: result.startDate,
            endDate: result.endDate,
          );
      if (!mounted) return;
      AppToast.show(
        context,
        context.tr('financial_period_updated_successfully'),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      AppToast.show(context, context.tr(error.message));
    }
  }

  Future<void> _deletePeriod(BudgetPeriod period) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: context.tr('delete_financial_period'),
      message: context.l10n.periodDeleteMessage(
        DateFormatter.periodFull(period.startDate, period.endDate),
      ),
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(transactionActionProvider.notifier)
        .deleteBudgetPeriod(period.id);
    if (!mounted) return;
    AppToast.show(context, context.tr('financial_period_deleted_successfully'));
  }
}

class _EmptyPeriodTab extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onActionTap;

  const _EmptyPeriodTab({
    required this.title,
    required this.message,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.warmGradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.date_range_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onActionTap,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('create_financial_period')),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoadingView extends StatelessWidget {
  final int selectedIndex;

  const _DashboardLoadingView({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    if (selectedIndex >= 2) {
      return const LoadingView();
    }

    final showDashboardCharts = selectedIndex == 0;
    return _DashboardSkeletonPulse(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroSkeleton(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDashboardCharts) ...[
                  _ChartSkeleton(),
                  const SizedBox(height: 28),
                  _ChartSkeleton(shorter: true),
                  const SizedBox(height: 28),
                  _SummarySkeleton(),
                ] else ...[
                  Row(
                    children: const [
                      Expanded(child: _SkeletonBox(height: 30)),
                      SizedBox(width: 12),
                      _SkeletonBox(width: 104, height: 44),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _SkeletonBox(height: 134),
                  const SizedBox(height: 12),
                  const _SkeletonBox(height: 134),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonBox(width: 210, height: 24, light: true),
          SizedBox(height: 12),
          _SkeletonBox(width: 250, height: 20, light: true),
          SizedBox(height: 20),
          _SkeletonBox(height: 96, borderRadius: 16, light: true),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SkeletonBox(height: 84, borderRadius: 16, light: true),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SkeletonBox(height: 84, borderRadius: 16, light: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  final bool shorter;

  const _ChartSkeleton({this.shorter = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _SkeletonBox(width: 4, height: 48, borderRadius: 99),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 170, height: 22),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 118, height: 14),
                  ],
                ),
              ),
              SizedBox(width: 10),
              _SkeletonBox(width: 42, height: 42, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 22),
          _SkeletonBox(height: shorter ? 170 : 210, borderRadius: 14),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
      ),
      child: Column(
        children: const [
          Row(
            children: [
              _SkeletonBox(width: 42, height: 42, borderRadius: 14),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBox(height: 22)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 66, borderRadius: 14)),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBox(height: 66, borderRadius: 14)),
            ],
          ),
          SizedBox(height: 12),
          _SkeletonBox(height: 42, borderRadius: 12),
          SizedBox(height: 10),
          _SkeletonBox(height: 42, borderRadius: 12),
        ],
      ),
    );
  }
}

class _DashboardSkeletonPulse extends StatefulWidget {
  final Widget child;

  const _DashboardSkeletonPulse({required this.child});

  @override
  State<_DashboardSkeletonPulse> createState() =>
      _DashboardSkeletonPulseState();
}

class _DashboardSkeletonPulseState extends State<_DashboardSkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.48,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool light;

  const _SkeletonBox({
    this.width,
    this.height,
    this.borderRadius = 10,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.24)
            : AppColors.mintSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: light
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.border.withValues(alpha: 0.44),
        ),
      ),
    );
  }
}

class _DashboardFooter extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _DashboardFooter({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlay.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _FooterIconButton(
              selected: selectedIndex == 0,
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              onTap: () => onChanged(0),
            ),
            _FooterIconButton(
              selected: selectedIndex == 1,
              icon: Icons.account_balance_wallet_outlined,
              selectedIcon: Icons.account_balance_wallet,
              onTap: () => onChanged(1),
            ),
            // ProfileTabBody tetap disimpan, tetapi akses dari footer
            // dinonaktifkan sementara untuk memberi tempat pada Riwayat.
            _FooterIconButton(
              selected: selectedIndex == 2,
              icon: Icons.history_rounded,
              selectedIcon: Icons.history_rounded,
              onTap: () => onChanged(2),
            ),
            _FooterIconButton(
              selected: selectedIndex == 3,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              onTap: () => onChanged(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterIconButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;

  const _FooterIconButton({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(selected ? selectedIcon : icon),
      color: selected ? AppColors.primary : AppColors.textSecondary,
      style: IconButton.styleFrom(
        backgroundColor: selected
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        fixedSize: const Size(54, 44),
      ),
    );
  }
}

class _DashboardTabBody extends ConsumerWidget {
  final BudgetSnapshot currentSnapshot;

  const _DashboardTabBody({required this.currentSnapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = ref.watch(allBudgetSnapshotsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: snapshotsAsync.when(
        loading: () => const LoadingView(padding: EdgeInsets.zero),
        error: (error, _) => ErrorView(error: error),
        data: (snapshots) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RecurringDueSection(),
            PeriodStatisticsChart(snapshots: snapshots),
            const SizedBox(height: 28),
            ExpenseStatisticsChart(snapshot: currentSnapshot),
            const SizedBox(height: 28),
            _PeriodSummaryInsightCard(snapshot: currentSnapshot),
          ],
        ),
      ),
    );
  }
}

class _PeriodSummaryInsightCard extends StatelessWidget {
  final BudgetSnapshot snapshot;

  const _PeriodSummaryInsightCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final totalIncome = snapshot.period.totalIncome;
    final totalExpense = snapshot.totalExpense;
    final remaining = totalIncome - totalExpense;
    final categoryExpenses = _categoryExpenseTotals();
    final topExpenseCategory = _topExpenseCategory(categoryExpenses);
    final negativeCategories = snapshot.categories
        .where((category) => category.remainingAmount < 0)
        .toList();
    final comfortableCategories =
        snapshot.categories
            .where((category) => category.remainingAmount > 0)
            .toList()
          ..sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
    final daysLeft = _daysLeft(snapshot.period.endDate);
    final isEndingSoon = daysLeft >= 0 && daysLeft <= 3;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.cream.withValues(alpha: 0.42),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.14),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.fact_check_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('period_summary'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isEndingSoon
                            ? context.trf('period_ends_in_days', {
                                'days': daysLeft,
                              })
                            : DateFormatter.periodFull(
                                snapshot.period.startDate,
                                snapshot.period.endDate,
                              ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryInsightMetric(
                        label: context.tr('income'),
                        amount: totalIncome,
                        color: AppColors.secondary,
                        leading: const TransactionTypeIcon(
                          isIncome: true,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryInsightMetric(
                        label: context.tr('expense'),
                        amount: totalExpense,
                        color: AppColors.danger,
                        leading: const TransactionTypeIcon(
                          isIncome: false,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _SummaryInsightRow(
                  icon: Icons.savings_outlined,
                  label: context.tr('remaining_money'),
                  value: RupiahFormatter.format(remaining),
                  color: remaining < 0 ? AppColors.danger : AppColors.primary,
                ),
                _SummaryInsightRow(
                  icon: Icons.local_fire_department_rounded,
                  label: context.tr('highest_spending_category'),
                  value: topExpenseCategory == null
                      ? context.tr('no_expenses_yet')
                      : '${topExpenseCategory.category.name} • ${RupiahFormatter.format(topExpenseCategory.amount)}',
                  color: AppColors.warning,
                ),
                _SummaryInsightRow(
                  icon: Icons.warning_amber_rounded,
                  label: context.tr('categories_need_attention'),
                  value: negativeCategories.isEmpty
                      ? context.tr('none')
                      : '${negativeCategories.length} ${context.tr('category').toLowerCase()}',
                  color: negativeCategories.isEmpty
                      ? AppColors.secondary
                      : AppColors.danger,
                ),
                _SummaryInsightRow(
                  icon: Icons.verified_rounded,
                  label: context.tr('most_flexible_category'),
                  value: comfortableCategories.isEmpty
                      ? context.tr('none')
                      : '${comfortableCategories.first.name} • ${RupiahFormatter.format(comfortableCategories.first.remainingAmount)}',
                  color: AppColors.secondary,
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _categoryExpenseTotals() {
    final totals = <String, int>{};
    for (final transaction in snapshot.transactions) {
      if (transaction.type != TransactionType.expense) continue;
      final categoryId = transaction.categoryId;
      if (categoryId == null) continue;
      totals.update(
        categoryId,
        (amount) => amount + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return totals;
  }

  _CategoryExpenseSummary? _topExpenseCategory(Map<String, int> totals) {
    _CategoryExpenseSummary? top;
    for (final category in snapshot.categories) {
      final amount = totals[category.id] ?? 0;
      if (amount <= 0) continue;
      if (top == null || amount > top.amount) {
        top = _CategoryExpenseSummary(category: category, amount: amount);
      }
    }
    return top;
  }

  int _daysLeft(DateTime endDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);
    return endOnly.difference(todayOnly).inDays;
  }
}

class _CategoryExpenseSummary {
  final CategoryBudget category;
  final int amount;

  const _CategoryExpenseSummary({required this.category, required this.amount});
}

class _SummaryInsightMetric extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final Widget leading;

  const _SummaryInsightMetric({
    required this.label,
    required this.amount,
    required this.color,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  RupiahFormatter.format(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryInsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showDivider;

  const _SummaryInsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.62)),
      ],
    );
  }
}

class _RecurringDueSection extends ConsumerWidget {
  const _RecurringDueSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueItemsAsync = ref.watch(recurringDueItemsProvider);

    return dueItemsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final hasOverdue = items.any((item) => item.isOverdue);

        return Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  hasOverdue
                      ? 'transactions_waiting_to_be_recorded'
                      : 'needs_to_be_recorded_today',
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecurringDueCard(item: item),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecurringDueCard extends ConsumerWidget {
  final RecurringDueItem item;

  const _RecurringDueCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final template = item.template;
    final color = template.type == TransactionType.income
        ? AppColors.secondary
        : AppColors.danger;
    final route = template.type == TransactionType.income
        ? AppRouter.addIncome
        : AppRouter.addExpense;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(
        context,
        route,
        arguments: RecurringTransactionDraft(
          template: template,
          dueDate: item.dueDate,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.78)),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlay.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            TransactionTypeIcon(
              isIncome: template.type == TransactionType.income,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      item.isOverdue
                          ? context.tr('overdue')
                          : context.tr('due_today'),
                      DateFormatter.full(item.dueDate),
                      template.preferredCategoryName ??
                          (template.type == TransactionType.income
                              ? context.tr('income')
                              : context.tr('expense')),
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  RupiahFormatter.format(template.amount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: () => _skip(context, ref),
                  child: Text(
                    context.tr('skip_this_time'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(transactionTemplateActionProvider.notifier)
          .skip(templateId: item.template.id, dueDate: item.dueDate);
      if (!context.mounted) return;
      AppToast.show(context, context.tr('recurring_occurrence_skipped'));
    } on StateError catch (error) {
      if (!context.mounted) return;
      AppToast.show(context, context.tr(error.message.toString()));
    }
  }
}

class _BudgetTabBody extends StatelessWidget {
  final BudgetSnapshot snapshot;
  final VoidCallback onAddTap;
  final ValueChanged<CategoryBudget> onCategoryTap;
  final ValueChanged<CategoryBudget> onCategoryEdit;
  final ValueChanged<CategoryBudget> onCategoryIncrease;
  final ValueChanged<CategoryBudget> onCategoryDecrease;
  final ValueChanged<CategoryBudget> onCategorySetAmount;
  final ValueChanged<CategoryBudget> onCategoryDelete;
  final ValueChanged<CategoryBudget> onCategoryDeleteBlocked;

  const _BudgetTabBody({
    required this.snapshot,
    required this.onAddTap,
    required this.onCategoryTap,
    required this.onCategoryEdit,
    required this.onCategoryIncrease,
    required this.onCategoryDecrease,
    required this.onCategorySetAmount,
    required this.onCategoryDelete,
    required this.onCategoryDeleteBlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      context.tr('budget_categories'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _BudgetModeChip(
                      allocationsFollowIncome:
                          snapshot.period.allocationsFollowIncome,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onAddTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(context.tr('add')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BudgetCategoryGrid(
            categories: snapshot.categories,
            transactions: snapshot.transactions,
            onCategoryTap: onCategoryTap,
            onCategoryEdit: onCategoryEdit,
            onCategoryIncrease: onCategoryIncrease,
            onCategoryDecrease: onCategoryDecrease,
            onCategorySetAmount: onCategorySetAmount,
            onCategoryDelete: onCategoryDelete,
            onCategoryDeleteBlocked: onCategoryDeleteBlocked,
            canDeleteCategory: (category) =>
                !snapshot.transactions.any(
                  (transaction) => transaction.categoryId == category.id,
                ) &&
                !snapshot.categoryAdjustments.any(
                  (adjustment) =>
                      adjustment.categoryId == category.id ||
                      adjustment.relatedCategoryId == category.id,
                ),
          ),
        ],
      ),
    );
  }
}

class _BudgetModeChip extends StatelessWidget {
  final bool allocationsFollowIncome;

  const _BudgetModeChip({required this.allocationsFollowIncome});

  @override
  Widget build(BuildContext context) {
    final color = allocationsFollowIncome
        ? AppColors.primary
        : AppColors.textSecondary;
    final icon = allocationsFollowIncome
        ? Icons.sync_alt_rounded
        : Icons.lock_outline_rounded;
    final label = allocationsFollowIncome
        ? context.tr('follows_income_2')
        : context.tr('fixed_amount');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
