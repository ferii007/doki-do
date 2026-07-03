import 'dart:io';

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
      final writer = SettingsLocalDatasource();
      final initialSettings = await writer.readSettings();

      await writer.saveSettings(
        initialSettings.copyWith(hideFinancialAmounts: true),
      );

      final reloadedSettings = await SettingsLocalDatasource().readSettings();

      expect(reloadedSettings.hideFinancialAmounts, isTrue);
    },
  );
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform({required this.documentsPath});

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
