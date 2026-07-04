import 'dart:convert';
import 'dart:io';

import 'package:doki_do/core/security/encrypted_storage.dart';
import 'package:doki_do/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'doki_do_settings_test_',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: tempDirectory.path,
    );
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test(
    'financial privacy remains enabled after settings are reloaded',
    () async {
      final keyStore = MemoryEncryptionKeyStore();
      final writer = SettingsLocalDatasource(
        encryptedStorage: EncryptedStorage(keyStore: keyStore),
      );
      final initialSettings = await writer.readSettings();

      await writer.saveSettings(
        initialSettings.copyWith(hideFinancialAmounts: true),
      );

      final reloadedSettings = await SettingsLocalDatasource(
        encryptedStorage: EncryptedStorage(keyStore: keyStore),
      ).readSettings();

      expect(reloadedSettings.hideFinancialAmounts, isTrue);
      final storedContent = await File(
        '${tempDirectory.path}/doki_do_settings.json',
      ).readAsString();
      expect(storedContent, contains('"format":"dokido-aes-gcm"'));
      expect(storedContent, isNot(contains('hide_financial_amounts')));
    },
  );

  test(
    'migrates legacy plaintext settings without losing preferences',
    () async {
      final file = File('${tempDirectory.path}/doki_do_settings.json');
      await file.writeAsString(
        jsonEncode({
          'has_completed_setup': true,
          'display_name': 'Feri',
          'email': 'feri@dokido.local',
          'user_type': 'flexible_financial_period_user',
          'theme_id': 'teal_balance',
          'language_code': 'en',
          'currency_code': 'USD',
          'hide_financial_amounts': true,
        }),
      );
      final storage = EncryptedStorage(keyStore: MemoryEncryptionKeyStore());

      final settings = await SettingsLocalDatasource(
        encryptedStorage: storage,
      ).readSettings();

      expect(settings.displayName, 'Feri');
      expect(settings.languageCode, 'en');
      expect(settings.currencyCode, 'USD');
      expect(settings.hideFinancialAmounts, isTrue);

      final migratedContent = await file.readAsString();
      expect(migratedContent, contains('"format":"dokido-aes-gcm"'));
      expect(migratedContent, isNot(contains('feri@dokido.local')));
      final decrypted = await storage.decrypt(
        migratedContent,
        scope: 'settings',
      );
      final migratedJson =
          jsonDecode(decrypted.plaintext) as Map<String, dynamic>;
      expect(migratedJson['schema_version'], 2);
      expect(migratedJson['notification_permission_prompt_dismissed'], isFalse);
    },
  );

  test('persists permanent notification prompt dismissal', () async {
    final keyStore = MemoryEncryptionKeyStore();
    final writer = SettingsLocalDatasource(
      encryptedStorage: EncryptedStorage(keyStore: keyStore),
    );
    final settings = await writer.readSettings();
    await writer.saveSettings(
      settings.copyWith(notificationPermissionPromptDismissed: true),
    );

    final reloaded = await SettingsLocalDatasource(
      encryptedStorage: EncryptedStorage(keyStore: keyStore),
    ).readSettings();

    expect(reloaded.notificationPermissionPromptDismissed, isTrue);
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform({required this.documentsPath});

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
