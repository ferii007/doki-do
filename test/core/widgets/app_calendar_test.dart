import 'package:doki_do/core/widgets/app_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'tahun dan bulan dapat dipilih tanpa menekan panah berulang kali',
    (tester) async {
      DateTime? selectedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCalendar(
              initialVisibleMonth: DateTime(2026, 7),
              onDateTap: (date) => selectedDate = date,
            ),
          ),
        ),
      );

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-years')), findsOneWidget);

      await tester.tap(find.text('2023'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-months')), findsOneWidget);

      await tester.tap(find.text('Feb'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-days')), findsOneWidget);

      await tester.tap(find.text('15'));
      await tester.pump();
      expect(selectedDate, DateTime(2023, 2, 15));
    },
  );

  testWidgets('navigasi kalender berhenti pada batas tanggal', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCalendar(
            initialVisibleMonth: DateTime(2023, 2),
            firstDate: DateTime(2023, 2, 1),
            lastDate: DateTime(2023, 2, 28),
            onDateTap: (_) {},
          ),
        ),
      ),
    );

    final previousButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_left_rounded),
    );
    final nextButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
    );

    expect(previousButton.onPressed, isNull);
    expect(nextButton.onPressed, isNull);
  });
}
