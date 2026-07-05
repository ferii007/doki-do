enum ReportScope {
  selectedPeriods(labelKey: 'selected_financial_periods'),
  dateRange(labelKey: 'date_range'),
  allPeriods(labelKey: 'all_financial_periods');

  final String labelKey;

  const ReportScope({required this.labelKey});
}
