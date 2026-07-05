import 'package:doki_do/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stacks newest toast on top and keeps at most three', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    AppToast.show(context, 'Toast pertama');
    await tester.pump();
    expect(find.text('Toast pertama'), findsOneWidget);

    AppToast.show(context, 'Toast kedua');
    AppToast.show(context, 'Toast ketiga');
    await tester.pump();

    expect(find.text('Toast pertama'), findsOneWidget);
    expect(find.text('Toast kedua'), findsOneWidget);
    expect(find.text('Toast ketiga'), findsOneWidget);

    final thirdY = tester.getTopLeft(find.text('Toast ketiga')).dy;
    final secondY = tester.getTopLeft(find.text('Toast kedua')).dy;
    final firstY = tester.getTopLeft(find.text('Toast pertama')).dy;
    expect(thirdY, lessThan(secondY));
    expect(secondY, lessThan(firstY));

    AppToast.show(context, 'Toast keempat');
    await tester.pump();

    expect(find.text('Toast pertama'), findsOneWidget);
    expect(find.text('Toast kedua'), findsOneWidget);
    expect(find.text('Toast ketiga'), findsOneWidget);
    expect(find.text('Toast keempat'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.getTopLeft(find.text('Toast pertama')).dy,
      greaterThan(firstY),
    );
    await tester.pump(const Duration(milliseconds: 140));
    expect(find.text('Toast pertama'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });
}
