import 'package:doki_do/core/widgets/app_inline_divider.dart';
import 'package:doki_do/features/finance/domain/entities/budget_period.dart';
import 'package:doki_do/features/finance/domain/entities/budget_snapshot.dart';
import 'package:doki_do/features/finance/domain/entities/category_budget.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_item.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_type.dart';
import 'package:doki_do/features/finance/presentation/providers/current_budget_provider.dart';
import 'package:doki_do/features/finance/presentation/widgets/dashboard/history_tab_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders inside a vertical scroll view without flex errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allBudgetSnapshotsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          home: Scaffold(body: ListView(children: const [HistoryTabBody()])),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the activity filter sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allBudgetSnapshotsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          home: Scaffold(body: ListView(children: const [HistoryTabBody()])),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Filter Aktivitas'), findsOneWidget);
    expect(find.text('Jenis Aktivitas'), findsOneWidget);
    expect(find.text('Tanggal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity filter exposes custom range and financial periods', (
    tester,
  ) async {
    final snapshot = BudgetSnapshot(
      period: BudgetPeriod(
        id: 'period-2023-02',
        startDate: DateTime(2023, 2, 1),
        endDate: DateTime(2023, 2, 28),
        totalIncome: 0,
        totalAllocatable: 0,
        allocationsFollowIncome: false,
      ),
      categories: const [],
      transactions: const [],
      categoryAdjustments: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allBudgetSnapshotsProvider.overrideWith((ref) async => [snapshot]),
        ],
        child: MaterialApp(
          home: Scaffold(body: ListView(children: const [HistoryTabBody()])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Rentang Tanggal Kustom'), findsOneWidget);
    expect(find.text('Filter Berdasarkan Periode'), findsOneWidget);
    expect(find.text('1 Februari 2023 - 28 Februari 2023'), findsOneWidget);

    await tester.tap(find.text('Rentang Tanggal Kustom'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar-days')), findsOneWidget);
    expect(find.text('Rentang Tanggal Kustom'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history shows transaction type with category or period', (
    tester,
  ) async {
    final snapshot = BudgetSnapshot(
      period: BudgetPeriod(
        id: 'period-july',
        startDate: DateTime(2026, 7, 2),
        endDate: DateTime(2026, 8, 1),
        totalIncome: 1000000,
        totalAllocatable: 900000,
        allocationsFollowIncome: true,
      ),
      categories: const [
        CategoryBudget(
          id: 'daily-needs',
          name: 'Kebutuhan Harian',
          allocatedAmount: 500000,
          remainingAmount: 400000,
        ),
      ],
      transactions: [
        TransactionItem(
          id: 'income-1',
          title: 'Proyek',
          amount: 1000000,
          date: DateTime(2026, 7, 2),
          type: TransactionType.income,
        ),
        TransactionItem(
          id: 'expense-1',
          categoryId: 'daily-needs',
          title: 'Belanja',
          amount: 100000,
          date: DateTime(2026, 7, 2),
          type: TransactionType.expense,
        ),
      ],
      categoryAdjustments: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allBudgetSnapshotsProvider.overrideWith((ref) async => [snapshot]),
        ],
        child: MaterialApp(
          home: Scaffold(body: ListView(children: const [HistoryTabBody()])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Uang Keluar'), findsOneWidget);
    expect(find.text('Kebutuhan Harian'), findsOneWidget);
    expect(find.text('Uang Masuk'), findsOneWidget);
    expect(find.text('2 Juli 2026 - 1 Agustus 2026'), findsOneWidget);
    expect(find.byType(AppInlineDivider), findsNWidgets(2));
    expect(find.text('|'), findsNothing);
  });
}
