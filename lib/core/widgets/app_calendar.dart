import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../formatters/date_formatter.dart';
import '../localization/app_localizations.dart';
import 'app_bottom_sheet.dart';

typedef AppDateDisabled = bool Function(DateTime date);

class AppCalendar extends StatefulWidget {
  final DateTime initialVisibleMonth;
  final DateTime? selectedStart;
  final DateTime? selectedEnd;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final AppDateDisabled? isDateDisabled;
  final ValueChanged<DateTime> onDateTap;

  const AppCalendar({
    super.key,
    required this.initialVisibleMonth,
    required this.onDateTap,
    this.selectedStart,
    this.selectedEnd,
    this.firstDate,
    this.lastDate,
    this.isDateDisabled,
  });

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

enum _CalendarView { days, months, years }

class _AppCalendarState extends State<AppCalendar> {
  late DateTime _visibleMonth;
  final ScrollController _yearScrollController = ScrollController();
  bool _yearScrollPending = false;
  _CalendarView _view = _CalendarView.days;

  int get _firstYear => widget.firstDate?.year ?? 1900;
  int get _lastYear => widget.lastDate?.year ?? 2100;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.initialVisibleMonth.year,
      widget.initialVisibleMonth.month,
    );
  }

  @override
  void didUpdateWidget(AppCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialVisibleMonth != widget.initialVisibleMonth) {
      _visibleMonth = DateTime(
        widget.initialVisibleMonth.year,
        widget.initialVisibleMonth.month,
      );
    }
  }

  @override
  void dispose() {
    _yearScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: switch (_view) {
              _CalendarView.days => _buildDays(context),
              _CalendarView.months => _buildMonths(context),
              _CalendarView.years => _buildYears(context),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: _canGoPrevious ? _goPrevious : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeaderButton(
                label: DateFormatter.monthName(_visibleMonth.month),
                active: _view == _CalendarView.months,
                showDropdownIndicator: true,
                onTap: () => setState(() {
                  _view = _view == _CalendarView.months
                      ? _CalendarView.days
                      : _CalendarView.months;
                }),
              ),
              const SizedBox(width: 4),
              _HeaderButton(
                label: '${_visibleMonth.year}',
                active: _view == _CalendarView.years,
                showDropdownIndicator: true,
                onTap: _toggleYearView,
              ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: _canGoNext ? _goNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _buildDays(BuildContext context) {
    final dayNames = [
      for (final key in const [
        'weekday_mon',
        'weekday_tue',
        'weekday_wed',
        'weekday_thu',
        'weekday_fri',
        'weekday_sat',
        'weekday_sun',
      ])
        context.tr(key),
    ];
    final dates = _visibleDates(_visibleMonth);

    return Column(
      key: const ValueKey('calendar-days'),
      children: [
        Row(
          children: [
            for (final day in dayNames)
              Expanded(
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = (constraints.maxWidth - 36) / 7;
            final cellHeight = cellWidth.clamp(38.0, 48.0);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dates.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: cellWidth / cellHeight,
              ),
              itemBuilder: (context, index) {
                final date = dates[index];
                if (date == null) return const SizedBox.shrink();
                final disabled = _isDisabled(date);
                final selected =
                    _isSameDate(date, widget.selectedStart) ||
                    _isSameDate(date, widget.selectedEnd);
                final inRange =
                    widget.selectedStart != null &&
                    widget.selectedEnd != null &&
                    date.isAfter(_dateOnly(widget.selectedStart!)) &&
                    date.isBefore(_dateOnly(widget.selectedEnd!));

                return _CalendarDayCell(
                  date: date,
                  disabled: disabled,
                  selected: selected,
                  inRange: inRange,
                  onTap: () => widget.onDateTap(date),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildMonths(BuildContext context) {
    return GridView.builder(
      key: const ValueKey('calendar-months'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.35,
      ),
      itemBuilder: (context, index) {
        final month = index + 1;
        final selected = month == _visibleMonth.month;
        final enabled = _monthHasSelectableDate(_visibleMonth.year, month);
        return _CalendarChoice(
          label: DateFormatter.monthName(month, short: true),
          selected: selected,
          enabled: enabled,
          onTap: () => setState(() {
            _visibleMonth = DateTime(_visibleMonth.year, month);
            _view = _CalendarView.days;
          }),
        );
      },
    );
  }

  Widget _buildYears(BuildContext context) {
    final years = [for (var year = _firstYear; year <= _lastYear; year++) year];
    return SizedBox(
      key: const ValueKey('calendar-years'),
      height: 224,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_yearScrollPending) {
            _yearScrollPending = false;
            final cellWidth = (constraints.maxWidth - 16) / 3;
            final rowExtent = (cellWidth / 2.35) + 8;
            final selectedRow = ((_visibleMonth.year - _firstYear) / 3).floor();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_yearScrollController.hasClients) return;
              final target = ((selectedRow - 2) * rowExtent).clamp(
                0.0,
                _yearScrollController.position.maxScrollExtent,
              );
              _yearScrollController.jumpTo(target);
            });
          }
          return GridView.count(
            controller: _yearScrollController,
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.35,
            children: [
              for (final year in years)
                _CalendarChoice(
                  label: '$year',
                  selected: year == _visibleMonth.year,
                  enabled: true,
                  onTap: () => setState(() {
                    _visibleMonth = DateTime(year, _visibleMonth.month);
                    _view = _CalendarView.months;
                  }),
                ),
            ],
          );
        },
      ),
    );
  }

  void _toggleYearView() {
    setState(() {
      _view = _view == _CalendarView.years
          ? _CalendarView.days
          : _CalendarView.years;
      _yearScrollPending = _view == _CalendarView.years;
    });
  }

  void _goPrevious() {
    setState(() {
      if (_view == _CalendarView.years) {
        _visibleMonth = DateTime(
          (_visibleMonth.year - 12).clamp(_firstYear, _lastYear),
          _visibleMonth.month,
        );
      } else if (_view == _CalendarView.months) {
        _visibleMonth = DateTime(_visibleMonth.year - 1, _visibleMonth.month);
      } else {
        _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
      }
    });
  }

  void _goNext() {
    setState(() {
      if (_view == _CalendarView.years) {
        _visibleMonth = DateTime(
          (_visibleMonth.year + 12).clamp(_firstYear, _lastYear),
          _visibleMonth.month,
        );
      } else if (_view == _CalendarView.months) {
        _visibleMonth = DateTime(_visibleMonth.year + 1, _visibleMonth.month);
      } else {
        _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      }
    });
  }

  bool get _canGoPrevious {
    if (_view == _CalendarView.days) {
      final firstMonth = widget.firstDate == null
          ? DateTime(_firstYear)
          : DateTime(widget.firstDate!.year, widget.firstDate!.month);
      return _visibleMonth.isAfter(firstMonth);
    }
    return _visibleMonth.year > _firstYear;
  }

  bool get _canGoNext {
    if (_view == _CalendarView.days) {
      final lastMonth = widget.lastDate == null
          ? DateTime(_lastYear, 12)
          : DateTime(widget.lastDate!.year, widget.lastDate!.month);
      return _visibleMonth.isBefore(lastMonth);
    }
    return _visibleMonth.year < _lastYear;
  }

  bool _monthHasSelectableDate(int year, int month) {
    final monthStart = DateTime(year, month);
    final monthEnd = DateTime(year, month + 1, 0);
    final first = widget.firstDate == null
        ? null
        : _dateOnly(widget.firstDate!);
    final last = widget.lastDate == null ? null : _dateOnly(widget.lastDate!);
    if (first != null && monthEnd.isBefore(first)) return false;
    if (last != null && monthStart.isAfter(last)) return false;
    return true;
  }

  bool _isDisabled(DateTime date) {
    final value = _dateOnly(date);
    final first = widget.firstDate == null
        ? null
        : _dateOnly(widget.firstDate!);
    final last = widget.lastDate == null ? null : _dateOnly(widget.lastDate!);
    if (first != null && value.isBefore(first)) return true;
    if (last != null && value.isAfter(last)) return true;
    return widget.isDateDisabled?.call(value) ?? false;
  }

  List<DateTime?> _visibleDates(DateTime visibleMonth) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    return [
      for (var i = 0; i < firstDay.weekday - 1; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(visibleMonth.year, visibleMonth.month, day),
    ];
  }
}

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AppSingleDatePickerSheet(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
    ),
  );
}

Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  DateTime? initialStart,
  DateTime? initialEnd,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AppDateRangePickerSheet(
      initialStart: initialStart,
      initialEnd: initialEnd,
      firstDate: firstDate,
      lastDate: lastDate,
      title: title,
    ),
  );
}

class _AppSingleDatePickerSheet extends StatelessWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? title;

  const _AppSingleDatePickerSheet({
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(
            title: title ?? context.tr('choose_date'),
            icon: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 14),
          AppCalendar(
            initialVisibleMonth: initialDate,
            selectedStart: initialDate,
            firstDate: firstDate,
            lastDate: lastDate,
            onDateTap: (date) => Navigator.pop(context, date),
          ),
        ],
      ),
    );
  }
}

class _AppDateRangePickerSheet extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? title;

  const _AppDateRangePickerSheet({
    this.initialStart,
    this.initialEnd,
    this.firstDate,
    this.lastDate,
    this.title,
  });

  @override
  State<_AppDateRangePickerSheet> createState() =>
      _AppDateRangePickerSheetState();
}

class _AppDateRangePickerSheetState extends State<_AppDateRangePickerSheet> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  @override
  Widget build(BuildContext context) {
    final visibleDate = _start ?? DateTime.now();
    return AppSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(
            title: widget.title ?? context.tr('choose_date_range'),
            icon: Icons.date_range_rounded,
          ),
          const SizedBox(height: 14),
          AppCalendar(
            initialVisibleMonth: visibleDate,
            selectedStart: _start,
            selectedEnd: _end,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            onDateTap: _selectDate,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _start != null && _end != null
                  ? () => Navigator.pop(
                      context,
                      DateTimeRange(start: _start!, end: _end!),
                    )
                  : null,
              child: Text(context.tr('apply')),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (_start == null || _end != null || date.isBefore(_start!)) {
        _start = date;
        _end = null;
      } else {
        _end = date;
      }
    });
  }
}

class _HeaderButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool showDropdownIndicator;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.label,
    required this.active,
    this.showDropdownIndicator = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: active ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (showDropdownIndicator) ...[
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: active ? 0.5 : 0,
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _CalendarChoice({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : enabled
              ? AppColors.surface
              : AppColors.border.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected
                ? Colors.white
                : enabled
                ? AppColors.textPrimary
                : AppColors.textSecondary.withValues(alpha: 0.4),
            fontWeight: FontWeight.w800,
          ),
        ),
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
    final background = disabled
        ? AppColors.border.withValues(alpha: 0.22)
        : selected
        ? AppColors.primary
        : inRange
        ? AppColors.secondary.withValues(alpha: 0.22)
        : AppColors.surface;
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : inRange
                ? AppColors.secondary
                : AppColors.border,
          ),
        ),
        child: Text(
          '${date.day}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: disabled
                ? AppColors.textSecondary.withValues(alpha: 0.38)
                : selected
                ? Colors.white
                : AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDate(DateTime date, DateTime? other) {
  return other != null &&
      date.year == other.year &&
      date.month == other.month &&
      date.day == other.day;
}
