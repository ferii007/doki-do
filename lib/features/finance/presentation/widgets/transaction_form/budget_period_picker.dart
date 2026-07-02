import 'package:flutter/material.dart';

import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../domain/entities/budget_period.dart';
import 'themed_dropdown_field.dart';

class BudgetPeriodPicker extends StatelessWidget {
  final List<BudgetPeriod> periods;
  final String? selectedPeriodId;
  final ValueChanged<String?> onChanged;
  final String label;

  const BudgetPeriodPicker({
    super.key,
    required this.periods,
    required this.selectedPeriodId,
    required this.onChanged,
    this.label = 'financial_period',
  });

  @override
  Widget build(BuildContext context) {
    final value =
        selectedPeriodId ?? (periods.isEmpty ? null : periods.first.id);

    return ThemedDropdownField<String>(
      label: context.tr(label),
      value: value,
      options: periods
          .map(
            (period) => ThemedDropdownOption<String>(
              value: period.id,
              title: DateFormatter.periodFull(period.startDate, period.endDate),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
