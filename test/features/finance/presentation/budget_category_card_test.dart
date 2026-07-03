import 'package:doki_do/core/widgets/app_inline_divider.dart';
import 'package:doki_do/features/finance/domain/entities/category_budget.dart';
import 'package:doki_do/features/finance/presentation/widgets/dashboard/budget_category_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('header dan body kategori memakai separator reusable yang sama', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetCategoryCard(
            category: const CategoryBudget(
              id: 'daily-needs',
              name: 'Kebutuhan Harian',
              allocatedAmount: 500000,
              remainingAmount: 400000,
              allocationPercent: 50,
            ),
            transactionCount: 1,
            canDelete: false,
            onTap: () {},
            onEdit: () {},
            onIncrease: () {},
            onDecrease: () {},
            onSetAmount: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Kebutuhan Harian'), findsOneWidget);
    expect(find.byType(AppInlineDivider), findsNWidgets(2));
    expect(find.text('|'), findsNothing);
  });
}
