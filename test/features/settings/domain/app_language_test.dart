import 'package:doki_do/core/app_info/app_identity.dart';
import 'package:doki_do/core/localization/app_localizations.dart';
import 'package:doki_do/features/settings/domain/entities/app_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLanguage system default', () {
    test('uses Indonesian when the system language is supported', () {
      expect(AppLanguage.fromSystemLanguageCode('id'), AppLanguage.id);
    });

    test('uses English when the system language is supported', () {
      expect(AppLanguage.fromSystemLanguageCode('en'), AppLanguage.en);
    });

    test('falls back to English for an unsupported system language', () {
      expect(AppLanguage.fromSystemLanguageCode('de'), AppLanguage.en);
    });
  });

  test('localization resolves reusable application identity tokens', () {
    final localizations = const AppLocalizations(AppLanguage.en);

    expect(localizations.tr('dokido_user'), '${AppIdentity.appName} User');
    expect(
      localizations.tr('powered_by_developer'),
      AppIdentity.developerAttribution,
    );
  });
}
