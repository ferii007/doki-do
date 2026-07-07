Map<String, dynamic> createEmptyFinanceData() {
  return {
    'schema_version': 4,
    'status': 'success',
    'current_period_id': null,
    'periods': <Map<String, dynamic>>[],
    'transaction_templates': <Map<String, dynamic>>[],
    'recurring_occurrences': <Map<String, dynamic>>[],
  };
}
