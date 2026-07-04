import 'package:doki_do/core/localization/app_localizations.dart';
import 'package:doki_do/features/security/presentation/screens/app_lock_pin_setup_screen.dart';
import 'package:doki_do/features/settings/domain/entities/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires matching six-digit PIN entries', (tester) async {
    String? completedPin;
    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AppLocalizationsScope(
          localizations: const AppLocalizations(AppLanguage.id),
          child: Scaffold(
            body: AppLockPinSetupPanel(
              titleKey: 'create_app_lock_pin',
              descriptionKey: 'create_app_lock_pin_description',
              onComplete: (pin) => completedPin = pin,
            ),
          ),
        ),
      ),
    );

    for (var repetition = 0; repetition < 2; repetition++) {
      for (final digit in ['1', '2', '3', '4', '5', '6']) {
        await tester.tap(find.text(digit));
      }
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(completedPin, '123456');
    expect(tester.takeException(), isNull);
  });
}
