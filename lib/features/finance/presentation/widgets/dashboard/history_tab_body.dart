import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/formatters/rupiah_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_calendar.dart';
import '../../../../../core/widgets/app_inline_divider.dart';
import '../../../domain/entities/budget_period.dart';
import '../../../domain/entities/budget_snapshot.dart';
import '../../../domain/entities/category_adjustment.dart';
import '../../../domain/entities/transaction_type.dart';
import '../../providers/current_budget_provider.dart';
import '../transaction_history_card.dart';

enum _HistoryFilter { income, expense, budgetChange }

enum _HistoryDateFilter { today, thisWeek, thisMonth, lastMonth, last3Months }

class HistoryTabBody extends ConsumerStatefulWidget {
  const HistoryTabBody({super.key});

  @override
  ConsumerState<HistoryTabBody> createState() => _HistoryTabBodyState();
}

class _HistoryTabBodyState extends ConsumerState<HistoryTabBody> {
  final _searchController = TextEditingController();
  _HistoryFilter? _filter;
  _HistoryDateFilter? _dateFilter;
  DateTimeRange? _customDateRange;
  String? _periodId;
  Timer? _typingTimer;
  String _animatedSearchTerm = '';
  int _searchTermIndex = 0;
  int _searchCharacterIndex = 0;
  int _searchHoldTicks = 0;
  bool _isDeletingSearchTerm = false;
  Locale? _lastLocale;

  @override
  void initState() {
    super.initState();
    _typingTimer = Timer.periodic(
      const Duration(milliseconds: 95),
      (_) => _updateAnimatedSearchTerm(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_lastLocale != locale) {
      _lastLocale = locale;
      _animatedSearchTerm = '';
      _searchTermIndex = 0;
      _searchCharacterIndex = 0;
      _searchHoldTicks = 0;
      _isDeletingSearchTerm = false;
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshotsAsync = ref.watch(allBudgetSnapshotsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '${context.tr('search')} $_animatedSearchTerm',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.tr('clear_search'),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _HistoryFilterIconButton(
                active:
                    _filter != null ||
                    _dateFilter != null ||
                    _customDateRange != null ||
                    _periodId != null,
                onTap: () => _showActivityFilter(
                  snapshotsAsync.asData?.value
                          .map((snapshot) => snapshot.period)
                          .toList() ??
                      const [],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          snapshotsAsync.when(
            loading: () => const _HistoryLoading(),
            error: (error, _) => _HistoryEmptyState(
              icon: Icons.error_outline_rounded,
              message: error.toString(),
            ),
            data: (snapshots) {
              final entries = _buildEntries(context, snapshots);
              final visibleEntries = _applyFilters(entries);

              if (visibleEntries.isEmpty) {
                final hasActiveSearchOrFilter =
                    _searchController.text.trim().isNotEmpty ||
                    _filter != null ||
                    _dateFilter != null ||
                    _customDateRange != null ||
                    _periodId != null;
                return _HistoryEmptyState(
                  icon: hasActiveSearchOrFilter
                      ? Icons.search_off_rounded
                      : Icons.history_toggle_off_rounded,
                  message: hasActiveSearchOrFilter
                      ? context.tr('no_history_matches_the_filter')
                      : context.tr('no_activity_history_yet'),
                );
              }

              final groups = _groupEntriesByDate(visibleEntries);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: groups.map((group) {
                  return _HistoryDateGroup(
                    label: _dateGroupLabel(context, group.date),
                    entries: group.entries,
                    onEntryTap: _openEntry,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _updateAnimatedSearchTerm() {
    if (!mounted) return;
    final terms = [
      context.tr('name'),
      context.tr('note'),
      context.tr('category'),
    ];
    final target = terms[_searchTermIndex];

    if (!_isDeletingSearchTerm && _searchCharacterIndex == target.length) {
      _searchHoldTicks++;
      if (_searchHoldTicks < 11) return;
      _searchHoldTicks = 0;
      _isDeletingSearchTerm = true;
    }

    setState(() {
      if (_isDeletingSearchTerm) {
        _searchCharacterIndex--;
        _animatedSearchTerm = target.substring(0, _searchCharacterIndex);
        if (_searchCharacterIndex == 0) {
          _isDeletingSearchTerm = false;
          _searchTermIndex = (_searchTermIndex + 1) % terms.length;
        }
      } else {
        _searchCharacterIndex++;
        _animatedSearchTerm = target.substring(0, _searchCharacterIndex);
      }
    });
  }

  Future<void> _showActivityFilter(List<BudgetPeriod> periods) async {
    final result = await showModalBottomSheet<_HistoryFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivityFilterSheet(
        initialType: _filter,
        initialDate: _dateFilter,
        initialCustomDateRange: _customDateRange,
        initialPeriodId: _periodId,
        periods: periods,
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _filter = result.type;
      _dateFilter = result.date;
      _customDateRange = result.customDateRange;
      _periodId = result.periodId;
    });
  }

  List<_HistoryEntry> _buildEntries(
    BuildContext context,
    List<BudgetSnapshot> snapshots,
  ) {
    final entries = <_HistoryEntry>[];

    for (final snapshot in snapshots) {
      final periodLabel = DateFormatter.periodFull(
        snapshot.period.startDate,
        snapshot.period.endDate,
      );
      final categories = {
        for (final category in snapshot.categories) category.id: category,
      };

      for (final transaction in snapshot.transactions) {
        final isIncome = transaction.type == TransactionType.income;
        final category = transaction.categoryId == null
            ? null
            : categories[transaction.categoryId];
        entries.add(
          _HistoryEntry(
            title: transaction.title,
            subtitle: category?.name ?? periodLabel,
            searchText:
                '${transaction.title} ${category?.name ?? ''} $periodLabel',
            amount: transaction.amount,
            date: transaction.date,
            createdAt: transaction.createdAt,
            stableId: transaction.id,
            kind: isIncome ? _HistoryFilter.income : _HistoryFilter.expense,
            periodId: snapshot.period.id,
          ),
        );
      }

      for (final adjustment in snapshot.categoryAdjustments) {
        final category = categories[adjustment.categoryId];
        entries.add(
          _HistoryEntry(
            title: _adjustmentTitle(context, adjustment.type),
            subtitle: [
              if (category != null) category.name,
              adjustment.reason,
            ].where((value) => value.trim().isNotEmpty).join(' - '),
            searchText:
                '${category?.name ?? ''} ${adjustment.reason} $periodLabel',
            amount: adjustment.deltaAmount,
            date: adjustment.date,
            createdAt: adjustment.createdAt,
            stableId: adjustment.id,
            kind: _HistoryFilter.budgetChange,
            periodId: snapshot.period.id,
            categoryId: adjustment.categoryId,
          ),
        );
      }
    }

    entries.sort(_sortHistoryEntries);
    return entries;
  }

  List<_HistoryEntry> _applyFilters(List<_HistoryEntry> entries) {
    final query = _searchController.text.trim().toLowerCase();
    return entries.where((entry) {
      final matchesType = _filter == null || entry.kind == _filter;
      final matchesSearch =
          query.isEmpty || entry.searchText.toLowerCase().contains(query);
      final matchesPeriod = _periodId == null || entry.periodId == _periodId;
      return matchesType &&
          matchesSearch &&
          matchesPeriod &&
          _matchesDateFilter(entry.date);
    }).toList();
  }

  bool _matchesDateFilter(DateTime date) {
    final customRange = _customDateRange;
    if (customRange != null) {
      final entryDate = DateTime(date.year, date.month, date.day);
      final start = DateTime(
        customRange.start.year,
        customRange.start.month,
        customRange.start.day,
      );
      final end = DateTime(
        customRange.end.year,
        customRange.end.month,
        customRange.end.day,
      );
      return !entryDate.isBefore(start) && !entryDate.isAfter(end);
    }

    final filter = _dateFilter;
    if (filter == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    switch (filter) {
      case _HistoryDateFilter.today:
        return entryDate == today;
      case _HistoryDateFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return !entryDate.isBefore(weekStart) && !entryDate.isAfter(today);
      case _HistoryDateFilter.thisMonth:
        return entryDate.year == today.year && entryDate.month == today.month;
      case _HistoryDateFilter.lastMonth:
        final lastMonth = DateTime(today.year, today.month - 1);
        return entryDate.year == lastMonth.year &&
            entryDate.month == lastMonth.month;
      case _HistoryDateFilter.last3Months:
        final periodStart = DateTime(today.year, today.month - 2);
        return !entryDate.isBefore(periodStart) && !entryDate.isAfter(today);
    }
  }

  List<_HistoryDateGroupData> _groupEntriesByDate(List<_HistoryEntry> entries) {
    final groups = <DateTime, List<_HistoryEntry>>{};
    for (final entry in entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      groups.putIfAbsent(date, () => []).add(entry);
    }
    return groups.entries
        .map(
          (group) =>
              _HistoryDateGroupData(date: group.key, entries: group.value),
        )
        .toList();
  }

  int _sortHistoryEntries(_HistoryEntry first, _HistoryEntry second) {
    final byTransactionDate = second.date.compareTo(first.date);
    if (byTransactionDate != 0) return byTransactionDate;

    final byCreatedAt = second.createdAt.compareTo(first.createdAt);
    if (byCreatedAt != 0) return byCreatedAt;

    return second.stableId.compareTo(first.stableId);
  }

  String _dateGroupLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return context.tr('today');
    if (date == today.subtract(const Duration(days: 1))) {
      return context.tr('yesterday');
    }
    return DateFormatter.full(date);
  }

  void _openEntry(_HistoryEntry entry) {
    if (entry.categoryId != null) {
      Navigator.pushNamed(
        context,
        AppRouter.categoryDetail,
        arguments: entry.categoryId,
      );
      return;
    }

    final route = entry.kind == _HistoryFilter.income
        ? AppRouter.incomeDetail
        : AppRouter.expenseDetail;
    Navigator.pushNamed(context, route, arguments: entry.periodId);
  }

  String _adjustmentTitle(BuildContext context, CategoryAdjustmentType type) {
    switch (type) {
      case CategoryAdjustmentType.increase:
        return context.tr('budget_increased');
      case CategoryAdjustmentType.decrease:
        return context.tr('budget_decreased');
      case CategoryAdjustmentType.setAmount:
        return context.tr('budget_set');
    }
  }
}

class _HistoryFilterIconButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _HistoryFilterIconButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
            if (active)
              Positioned(
                right: 11,
                top: 10,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityFilterSheet extends StatefulWidget {
  final _HistoryFilter? initialType;
  final _HistoryDateFilter? initialDate;
  final DateTimeRange? initialCustomDateRange;
  final String? initialPeriodId;
  final List<BudgetPeriod> periods;

  const _ActivityFilterSheet({
    required this.initialType,
    required this.initialDate,
    required this.initialCustomDateRange,
    required this.initialPeriodId,
    required this.periods,
  });

  @override
  State<_ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<_ActivityFilterSheet> {
  _HistoryFilter? _type;
  _HistoryDateFilter? _date;
  DateTimeRange? _customDateRange;
  String? _periodId;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _date = widget.initialDate;
    _customDateRange = widget.initialCustomDateRange;
    _periodId = widget.initialPeriodId;
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(
              title: context.tr('activity_filter'),
              icon: Icons.tune_rounded,
            ),
            const SizedBox(height: 24),
            _FilterSectionTitle(label: context.tr('activity_type')),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.72),
                ),
              ),
              child: Column(
                children: _HistoryFilter.values.map((type) {
                  return _ActivityTypeChoice(
                    type: type,
                    label: _historyFilterLabel(context, type),
                    selected: _type == type,
                    onTap: () => setState(() {
                      _type = _type == type ? null : type;
                    }),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),
            _FilterSectionTitle(label: context.tr('date')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _HistoryDateFilter.values.map((date) {
                return _DateFilterChoice(
                  label: _historyDateFilterLabel(context, date),
                  selected: _date == date,
                  onTap: () => setState(() {
                    _date = _date == date ? null : date;
                    _customDateRange = null;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            _CustomDateRangeChoice(
              range: _customDateRange,
              onTap: _pickCustomDateRange,
              onClear: () => setState(() => _customDateRange = null),
            ),
            if (widget.periods.isNotEmpty) ...[
              const SizedBox(height: 22),
              _FilterSectionTitle(label: context.tr('filter_by_period')),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.72),
                  ),
                ),
                child: Column(
                  children: widget.periods.map((period) {
                    return _FilterListChoice(
                      icon: Icons.calendar_view_month_rounded,
                      label: DateFormatter.periodFull(
                        period.startDate,
                        period.endDate,
                      ),
                      selected: _periodId == period.id,
                      onTap: () => setState(() {
                        _periodId = _periodId == period.id ? null : period.id;
                      }),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                _FilterResetButton(
                  label: context.tr('reset'),
                  onTap: () {
                    setState(() {
                      _type = null;
                      _date = null;
                      _customDateRange = null;
                      _periodId = null;
                    });
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _FilterActionButton(
                    label: context.tr('apply_filter'),
                    onTap: () => Navigator.pop(
                      context,
                      _HistoryFilterSelection(
                        type: _type,
                        date: _date,
                        customDateRange: _customDateRange,
                        periodId: _periodId,
                      ),
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

  Future<void> _pickCustomDateRange() async {
    final dates = [
      for (final period in widget.periods) period.startDate,
      for (final period in widget.periods) period.endDate,
    ]..sort();
    final result = await showAppDateRangePicker(
      context: context,
      initialStart: _customDateRange?.start,
      initialEnd: _customDateRange?.end,
      firstDate: dates.isEmpty ? null : dates.first,
      lastDate: dates.isEmpty ? null : dates.last,
      title: context.tr('custom_date_range'),
    );
    if (result == null || !mounted) return;
    setState(() {
      _customDateRange = result;
      _date = null;
    });
  }
}

class _FilterSectionTitle extends StatelessWidget {
  final String label;

  const _FilterSectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ActivityTypeChoice extends StatelessWidget {
  final _HistoryFilter type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityTypeChoice({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            if (type == _HistoryFilter.budgetChange)
              Icon(
                Icons.swap_horiz_rounded,
                size: 19,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              )
            else
              TransactionTypeIcon(
                isIncome: type == _HistoryFilter.income,
                size: 28,
              ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFilterChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DateFilterChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CustomDateRangeChoice extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _CustomDateRangeChoice({
    required this.range,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final selected = range != null;
    final label = selected
        ? DateFormatter.periodFull(range!.start, range!.end)
        : context.tr('custom_date_range');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 19,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: context.tr('clear_date_range'),
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            else
              const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _FilterListChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterListChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterResetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterResetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restart_alt_rounded,
              size: 19,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HistoryDateGroup extends StatelessWidget {
  final String label;
  final List<_HistoryEntry> entries;
  final ValueChanged<_HistoryEntry> onEntryTap;

  const _HistoryDateGroup({
    required this.label,
    required this.entries,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _HistoryCard(entry: entry, onTap: () => onEntryTap(entry));
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _HistoryEntry entry;
  final VoidCallback onTap;

  const _HistoryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPositive =
        entry.kind == _HistoryFilter.income ||
        (entry.kind == _HistoryFilter.budgetChange && entry.amount >= 0);
    final color = isPositive ? AppColors.primary : AppColors.danger;
    final prefix = isPositive ? '+' : '-';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TransactionTypeIcon(isIncome: isPositive),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$prefix${RupiahFormatter.format(entry.amount.abs())}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (entry.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    if (entry.kind == _HistoryFilter.budgetChange)
                      Text(
                        entry.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      _HistoryTransactionType(
                        typeLabel: _historyFilterLabel(context, entry.kind),
                        contextLabel: entry.subtitle,
                        color: color,
                      ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.full(entry.date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
    );
  }
}

class _HistoryTransactionType extends StatelessWidget {
  final String typeLabel;
  final String contextLabel;
  final Color color;

  const _HistoryTransactionType({
    required this.typeLabel,
    required this.contextLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800);
    return Row(
      children: [
        Text(typeLabel, style: style?.copyWith(color: color)),
        const AppInlineDivider(height: 14, horizontalMargin: 7),
        Expanded(
          child: Text(
            contextLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 104,
        decoration: BoxDecoration(
          color: AppColors.mintSurface.withValues(alpha: 0.64),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _HistoryEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry {
  final String title;
  final String subtitle;
  final String searchText;
  final int amount;
  final DateTime date;
  final DateTime createdAt;
  final String stableId;
  final _HistoryFilter kind;
  final String? periodId;
  final String? categoryId;

  const _HistoryEntry({
    required this.title,
    required this.subtitle,
    required this.searchText,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.stableId,
    required this.kind,
    this.periodId,
    this.categoryId,
  });
}

class _HistoryDateGroupData {
  final DateTime date;
  final List<_HistoryEntry> entries;

  const _HistoryDateGroupData({required this.date, required this.entries});
}

class _HistoryFilterSelection {
  final _HistoryFilter? type;
  final _HistoryDateFilter? date;
  final DateTimeRange? customDateRange;
  final String? periodId;

  const _HistoryFilterSelection({
    required this.type,
    required this.date,
    required this.customDateRange,
    required this.periodId,
  });
}

String _historyFilterLabel(BuildContext context, _HistoryFilter filter) {
  switch (filter) {
    case _HistoryFilter.income:
      return context.tr('income');
    case _HistoryFilter.expense:
      return context.tr('expense');
    case _HistoryFilter.budgetChange:
      return context.tr('budget_changes');
  }
}

String _historyDateFilterLabel(
  BuildContext context,
  _HistoryDateFilter filter,
) {
  switch (filter) {
    case _HistoryDateFilter.today:
      return context.tr('today');
    case _HistoryDateFilter.thisWeek:
      return context.tr('this_week');
    case _HistoryDateFilter.thisMonth:
      return context.tr('this_month');
    case _HistoryDateFilter.lastMonth:
      return context.tr('last_month');
    case _HistoryDateFilter.last3Months:
      return context.tr('last_3_months');
  }
}
