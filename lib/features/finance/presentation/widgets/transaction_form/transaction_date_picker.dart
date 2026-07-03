import 'package:flutter/material.dart';

import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_calendar.dart';

class TransactionDatePicker extends StatelessWidget {
  final DateTime date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  const TransactionDatePicker({
    super.key,
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.tr('date')),
      subtitle: Text(DateFormatter.full(date)),
      trailing: const Icon(Icons.calendar_today_outlined),
      onTap: () async {
        final initialDate = _clampDate(date, firstDate, lastDate);
        final selected = await showAppDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );

        if (selected != null) onChanged(selected);
      },
    );
  }

  DateTime _clampDate(DateTime value, DateTime min, DateTime max) {
    if (value.isBefore(min)) return min;
    if (value.isAfter(max)) return max;
    return value;
  }
}
