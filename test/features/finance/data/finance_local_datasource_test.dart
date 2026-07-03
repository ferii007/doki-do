import 'dart:convert';
import 'dart:io';

import 'package:doki_do/features/finance/data/datasources/finance_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'doki_do_finance_source_test_',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: tempDirectory.path,
    );
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('migrates the old default daily-needs category name', () async {
    final file = File('${tempDirectory.path}/doki_do_finance.json');
    await file.writeAsString(
      jsonEncode({
        'current_period_id': 'period-1',
        'periods': [
          {
            'period_id': 'period-1',
            'start_date': '2026-07-01T00:00:00.000',
            'end_date': '2026-07-31T23:59:59.000',
            'total_income': 0,
            'total_allocatable': 0,
            'allocations_follow_income': false,
            'categories': [
              {
                'category_id': 'category-1',
                'category_name': 'Kebutuhan Pokok',
                'base_allocated_amount': 0,
                'allocated_amount': 0,
                'remaining_amount': 0,
              },
            ],
            'transactions': [],
            'category_adjustments': [],
          },
        ],
        'transaction_templates': [
          {
            'transaction_template_id': 'template-1',
            'title': 'Belanja',
            'amount': 100000,
            'type': 'expense',
            'preferred_category_name': 'Kebutuhan Pokok',
            'day_of_month': null,
            'created_at': '2026-07-01T00:00:00.000',
          },
        ],
      }),
    );

    final datasource = FinanceLocalDatasource();
    final periods = await datasource.getBudgetPeriods();
    final templates = await datasource.getTransactionTemplates();

    final category =
        (periods.single['categories'] as List).single as Map<String, dynamic>;
    expect(category['category_name'], 'Kebutuhan Harian');
    expect(templates.single['preferred_category_name'], 'Kebutuhan Harian');
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform({required this.documentsPath});

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
