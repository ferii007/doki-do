import 'package:doki_do/features/export/data/report_save_gateway.dart';
import 'package:doki_do/features/export/data/report_share_gateway.dart';
import 'package:doki_do/features/export/presentation/providers/report_export_provider.dart';
import 'package:doki_do/features/export/presentation/screens/export_report_screen.dart';
import 'package:doki_do/features/finance/domain/entities/budget_period.dart';
import 'package:doki_do/features/finance/domain/entities/budget_snapshot.dart';
import 'package:doki_do/features/finance/domain/entities/category_budget.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_item.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_type.dart';
import 'package:doki_do/features/finance/presentation/providers/current_budget_provider.dart';
import 'package:doki_do/features/settings/domain/entities/app_settings.dart';
import 'package:doki_do/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saves and shares selected periods through their gateways', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = MemoryReportShareGateway();
    final saveGateway = MemoryReportSaveGateway();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allBudgetSnapshotsProvider.overrideWith(
            (ref) async => [_snapshot(), _secondSnapshot()],
          ),
          appSettingsProvider.overrideWith(_FakeSettingsNotifier.new),
          reportShareGatewayProvider.overrideWithValue(gateway),
          reportSaveGatewayProvider.overrideWithValue(saveGateway),
        ],
        child: const MaterialApp(home: ExportReportScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Template Ekspor Aktif'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Pilih Periode'), findsOneWidget);
    expect(find.text('Rentang Tanggal'), findsOneWidget);
    expect(find.text('Semua Periode'), findsOneWidget);
    expect(find.text('1 Periode Dipilih'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);

    await tester.tap(find.text('1 Periode Dipilih'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 Juli 2026 - 1 Agustus 2026'));
    await tester.pump();
    await tester.tap(find.text('Gunakan 2 Periode'));
    await tester.pumpAndSettle();

    expect(find.text('2 Periode Dipilih'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Simpan Ke Perangkat'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Simpan Ke Perangkat'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(saveGateway.lastSaved, isNotNull);
    expect(saveGateway.lastSaved!.fileName, endsWith('_Dashboard.pdf'));

    await tester.tap(find.text('Bagikan Laporan'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(gateway.lastShared, isNotNull);
    expect(gateway.lastShared!.fileName, endsWith('_Dashboard.pdf'));
    await tester.pump(const Duration(seconds: 3));
  });
}

class _FakeSettingsNotifier extends AppSettingsNotifier {
  @override
  Future<AppSettings> build() async {
    return AppSettings.defaults().copyWith(
      hasCompletedSetup: true,
      displayName: 'Feri',
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    state = AsyncData(settings);
  }
}

BudgetSnapshot _snapshot() {
  return BudgetSnapshot(
    period: BudgetPeriod(
      id: 'period-july',
      startDate: DateTime(2026, 7, 2),
      endDate: DateTime(2026, 8, 1),
      totalIncome: 1000000,
      totalAllocatable: 800000,
      allocationsFollowIncome: true,
    ),
    categories: const [
      CategoryBudget(
        id: 'daily',
        name: 'Kebutuhan Harian',
        allocatedAmount: 800000,
        remainingAmount: 700000,
        allocationPercent: 80,
      ),
    ],
    transactions: [
      TransactionItem(
        id: 'income-1',
        title: 'Saldo Awal',
        amount: 1000000,
        date: DateTime(2026, 7, 2),
        type: TransactionType.income,
      ),
      TransactionItem(
        id: 'expense-1',
        categoryId: 'daily',
        title: 'Belanja',
        amount: 100000,
        date: DateTime(2026, 7, 3),
        type: TransactionType.expense,
      ),
    ],
    categoryAdjustments: const [],
  );
}

BudgetSnapshot _secondSnapshot() {
  return BudgetSnapshot(
    period: BudgetPeriod(
      id: 'period-august',
      startDate: DateTime(2026, 8, 2),
      endDate: DateTime(2026, 9, 1),
      totalIncome: 1500000,
      totalAllocatable: 1000000,
      allocationsFollowIncome: true,
    ),
    categories: const [
      CategoryBudget(
        id: 'daily-august',
        name: 'Kebutuhan Harian',
        allocatedAmount: 1000000,
        remainingAmount: 1000000,
        allocationPercent: 66.67,
      ),
    ],
    transactions: [
      TransactionItem(
        id: 'income-august',
        title: 'Saldo Awal',
        amount: 1500000,
        date: DateTime(2026, 8, 2),
        type: TransactionType.income,
      ),
    ],
    categoryAdjustments: const [],
  );
}
