import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_calendar.dart';
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
    return AppSheetSurface(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(
              title: context.tr('edit_financial_period'),
              icon: Icons.edit_calendar_outlined,
            ),
            const SizedBox(height: 16),
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
            AppCalendar(
              initialVisibleMonth: _visibleMonth,
              selectedStart: _startDate,
              selectedEnd: _endDate,
              isDateDisabled: _isDateOccupied,
              onDateTap: _handleDateTap,
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
        color: AppColors.background,
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
