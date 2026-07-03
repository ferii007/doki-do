import 'package:doki_do/core/formatters/rupiah_formatter.dart';
import 'package:doki_do/features/finance/domain/entities/budget_period.dart';
import 'package:doki_do/features/finance/presentation/widgets/dashboard/period_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    FinancialPrivacyPreference.hideAmounts = false;
  });

  testWidgets('hero masks amounts and exposes the privacy toggle', (
    tester,
  ) async {
    var toggleCount = 0;
    FinancialPrivacyPreference.hideAmounts = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodSummaryCard(
            period: BudgetPeriod(
              id: 'period-july',
              startDate: DateTime(2026, 7, 2),
              endDate: DateTime(2026, 8, 1),
              totalIncome: 1000000,
              totalAllocatable: 1000000,
              allocationsFollowIncome: true,
            ),
            totalExpense: 250000,
            amountsHidden: true,
            onPrivacyToggle: () => toggleCount++,
          ),
        ),
      ),
    );

    expect(find.text('Rp ••••••'), findsNWidgets(3));
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    expect(toggleCount, 1);
  });
}
