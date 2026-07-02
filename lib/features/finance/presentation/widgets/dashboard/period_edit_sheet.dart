import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../domain/entities/budget_period.dart';

class PeriodEditResult {
  final DateTime startDate;
  final DateTime endDate;

  const PeriodEditResult({required this.startDate, required this.endDate});
}

class PeriodEditSheet extends StatefulWidget {
  final BudgetPeriod period;
  final List<BudgetPeriod> periods;

  const PeriodEditSheet({
    super.key,
    required this.period,
    required this.periods,
  });

  @override
  State<PeriodEditSheet> createState() => _PeriodEditSheetState();
}

class _PeriodEditSheetState extends State<PeriodEditSheet> {
  late DateTime _startDate;
  DateTime? _endDate;
  late DateTime _visibleMonth;
  bool _selectingStart = true;

  @override
  void initState() {
    super.initState();
    _startDate = _dateOnly(widget.period.startDate);
    _endDate = _dateOnly(widget.period.endDate);
    _visibleMonth = DateTime(_startDate.year, _startDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final dates = _visibleDates(_visibleMonth);
    final dayNames = context.l10n.language.name == 'en'
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('edit_financial_period'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: context.tr('period_start_date'),
                    date: _startDate,
                    active: _selectingStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: context.tr('period_end_date'),
                    date: _endDate,
                    active: !_selectingStart,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() {
                          _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month - 1,
                          );
                        }),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          DateFormatter.monthYear(_visibleMonth),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() {
                          _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month + 1,
                          );
                        }),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final day in dayNames)
                        Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dates.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                    itemBuilder: (context, index) {
                      final date = dates[index];
                      if (date == null) return const SizedBox.shrink();

                      final disabled = _isDateOccupied(date);
                      final selected =
                          _isSameDate(date, _startDate) ||
                          (_endDate != null && _isSameDate(date, _endDate!));
                      final inRange =
                          _endDate != null &&
                          date.isAfter(_startDate) &&
                          date.isBefore(_endDate!);

                      return _CalendarDayCell(
                        date: date,
                        disabled: disabled,
                        selected: selected,
                        inRange: inRange,
                        onTap: () => _handleDateTap(date),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(context.tr('save_changes')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateTap(DateTime date) {
    if (_isDateOccupied(date)) return;

    if (_selectingStart) {
      setState(() {
        _startDate = date;
        _endDate = null;
        _selectingStart = false;
      });
      return;
    }

    if (!date.isAfter(_startDate)) {
      AppToast.show(
        context,
        context.tr('the_end_date_must_be_after_the_start_date'),
      );
      return;
    }

    if (_rangeOverlapsExistingPeriod(_startDate, date)) {
      AppToast.show(
        context,
        context.tr('the_selected_date_overlaps_with_an_existing_period'),
      );
      return;
    }

    setState(() {
      _endDate = date;
      _selectingStart = true;
    });
  }

  void _submit() {
    final endDate = _endDate;
    if (endDate == null) {
      AppToast.show(
        context,
        context.tr('choose_the_start_and_end_dates_first'),
      );
      return;
    }

    if (!endDate.isAfter(_startDate)) {
      AppToast.show(
        context,
        context.tr('the_end_date_must_be_after_the_start_date'),
      );
      return;
    }
    if (_rangeOverlapsExistingPeriod(_startDate, endDate)) {
      AppToast.show(
        context,
        context.tr('the_selected_date_overlaps_with_an_existing_period'),
      );
      return;
    }

    Navigator.pop(
      context,
      PeriodEditResult(startDate: _startDate, endDate: endDate),
    );
  }

  List<DateTime?> _visibleDates(DateTime visibleMonth) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final leadingEmptyCells = firstDay.weekday - 1;

    return [
      for (var i = 0; i < leadingEmptyCells; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(visibleMonth.year, visibleMonth.month, day),
    ];
  }

  bool _isDateOccupied(DateTime date) {
    final normalizedDate = _dateOnly(date);
    return widget.periods.any((period) {
      if (period.id == widget.period.id) return false;
      final start = _dateOnly(period.startDate);
      final end = _dateOnly(period.endDate);
      return !normalizedDate.isBefore(start) && !normalizedDate.isAfter(end);
    });
  }

  bool _rangeOverlapsExistingPeriod(DateTime startDate, DateTime endDate) {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);
    return widget.periods.any((period) {
      if (period.id == widget.period.id) return false;
      final periodStart = _dateOnly(period.startDate);
      final periodEnd = _dateOnly(period.endDate);
      return !end.isBefore(periodStart) && !start.isAfter(periodEnd);
    });
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool active;

  const _DateField({
    required this.label,
    required this.date,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.secondary : AppColors.border,
          width: active ? 1.8 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            date == null ? '-' : DateFormatter.full(date!),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: date == null
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final bool disabled;
  final bool selected;
  final bool inRange;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.date,
    required this.disabled,
    required this.selected,
    required this.inRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = disabled
        ? AppColors.textSecondary.withValues(alpha: 0.35)
        : selected
        ? Colors.white
        : AppColors.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: disabled ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : inRange
              ? AppColors.mintSurface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disabled
                ? AppColors.border.withValues(alpha: 0.4)
                : selected
                ? AppColors.primary
                : Colors.transparent,
          ),
        ),
        child: Text(
          '${date.day}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
