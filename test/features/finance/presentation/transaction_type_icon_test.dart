import 'package:doki_do/features/finance/presentation/widgets/transaction_history_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('expense icon is the inverse of the income icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TransactionTypeIcon(isIncome: false)),
      ),
    );

    expect(find.byIcon(Icons.credit_card_outlined), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
  });
}
