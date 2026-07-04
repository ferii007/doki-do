import 'package:doki_do/core/localization/app_localizations.dart';
import 'package:doki_do/features/finance/presentation/widgets/dashboard/notification_permission_sheet.dart';
import 'package:doki_do/features/settings/domain/entities/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exposes settings and permanent dismissal actions', (
    tester,
  ) async {
    var openedSettings = false;
    var dismissedForever = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AppLocalizationsScope(
          localizations: const AppLocalizations(AppLanguage.id),
          child: Scaffold(
            body: NotificationPermissionSheet(
              onOpenSettings: () => openedSettings = true,
              onDismissForever: () => dismissedForever = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Pergi Ke Pengaturan'));
    expect(openedSettings, isTrue);

    await tester.tap(find.text('Lain Kali'));
    expect(dismissedForever, isTrue);
  });
}
