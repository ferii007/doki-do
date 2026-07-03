import 'package:doki_do/core/storage/resilient_encrypted_file_store.dart';
import 'package:doki_do/core/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a safe recovery message without offering data reset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ErrorView(
            error: StorageRecoveryException(
              message: 'unreadable',
              primaryError: FormatException('primary'),
              backupError: FormatException('backup'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Data Tidak Dapat Dipulihkan'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
}
