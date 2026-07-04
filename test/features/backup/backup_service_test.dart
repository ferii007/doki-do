import 'dart:io';
import 'dart:math';

import 'package:doki_do/core/security/encrypted_storage.dart';
import 'package:doki_do/features/backup/data/backup_credential_store.dart';
import 'package:doki_do/features/backup/data/backup_file_gateway.dart';
import 'package:doki_do/features/backup/domain/backup_archive_codec.dart';
import 'package:doki_do/features/backup/domain/backup_service.dart';
import 'package:doki_do/features/finance/data/datasources/finance_local_datasource.dart';
import 'package:doki_do/features/notifications/data/notification_local_datasource.dart';
import 'package:doki_do/features/notifications/domain/app_notification_item.dart';
import 'package:doki_do/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  late Directory tempDirectory;
  late FinanceLocalDatasource financeDatasource;
  late SettingsLocalDatasource settingsDatasource;
  late NotificationLocalDatasource notificationDatasource;
  late MemoryBackupFileGateway fileGateway;
  late BackupService service;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('doki_do_backup_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: tempDirectory.path,
    );
    final encryptedStorage = EncryptedStorage(
      keyStore: MemoryEncryptionKeyStore(),
    );
    financeDatasource = FinanceLocalDatasource(
      encryptedStorage: encryptedStorage,
    );
    settingsDatasource = SettingsLocalDatasource(
      encryptedStorage: encryptedStorage,
    );
    notificationDatasource = NotificationLocalDatasource(
      encryptedStorage: encryptedStorage,
    );
    fileGateway = MemoryBackupFileGateway()
      ..directory = const BackupDirectory(uri: 'memory://backup', name: 'Test');
    service = BackupService(
      financeDatasource: financeDatasource,
      settingsDatasource: settingsDatasource,
      notificationDatasource: notificationDatasource,
      codec: BackupArchiveCodec(
        credentialStore: MemoryBackupCredentialStore(),
        iterations: 10,
        random: Random(1),
      ),
      fileGateway: fileGateway,
      now: () => DateTime(2026, 7, 2, 10),
    );
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('restore replaces user data but preserves App Lock settings', () async {
    final initial = await settingsDatasource.readSettings();
    await settingsDatasource.saveSettings(
      initial.copyWith(
        displayName: 'Nama Dari Backup',
        exportReportTemplateCode: 'basic',
      ),
    );
    const notificationId = 'backup-notification';
    await notificationDatasource.upsert(
      AppNotificationItem(
        id: notificationId,
        category: AppNotificationCategory.backup,
        createdAt: DateTime(2026, 7, 2, 9),
        data: const {},
      ),
    );
    await service.configurePassword('rahasia-backup');
    await service.createBackup('memory://backup');

    final afterBackup = await settingsDatasource.readSettings();
    await settingsDatasource.saveSettings(
      afterBackup.copyWith(
        displayName: 'Nama Saat Ini',
        appLockEnabled: true,
        biometricUnlockEnabled: true,
        exportReportTemplateCode: 'dashboard',
      ),
    );
    await notificationDatasource.delete(notificationId);

    final file = await service.readLatestBackup('memory://backup');
    final archive = await service.inspectBackup(file!, 'rahasia-backup');
    await service.restoreBackup(archive);

    final restored = await settingsDatasource.readSettings();
    expect(restored.displayName, 'Nama Dari Backup');
    expect(restored.appLockEnabled, isTrue);
    expect(restored.biometricUnlockEnabled, isTrue);
    expect(restored.exportReportTemplateCode, 'basic');
    expect((await notificationDatasource.getAll()).single.id, notificationId);
  });

  test('rotates the previous backup instead of accumulating files', () async {
    await service.configurePassword('rahasia-backup');
    await service.createBackup('memory://backup');
    final first = fileGateway.current;

    final settings = await settingsDatasource.readSettings();
    await settingsDatasource.saveSettings(
      settings.copyWith(displayName: 'Versi Kedua'),
    );
    await service.createBackup('memory://backup');

    expect(fileGateway.current, isNotNull);
    expect(fileGateway.previous?.bytes, first?.bytes);
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform({required this.documentsPath});

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
