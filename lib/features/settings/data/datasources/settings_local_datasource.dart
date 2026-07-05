import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/app_info/app_identity.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/security/encrypted_storage.dart';
import '../../../../core/storage/async_write_queue.dart';
import '../../../../core/storage/resilient_encrypted_file_store.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';

class SettingsLocalDatasource {
  static const _schemaVersion = 6;
  static const _storageFileName = 'doki_do_settings.json';
  static const _encryptionScope = 'settings';

  final ResilientEncryptedFileStore _fileStore;
  final _writeQueue = AsyncWriteQueue();
  AppSettings? _cache;

  SettingsLocalDatasource({EncryptedStorage? encryptedStorage})
    : _fileStore = ResilientEncryptedFileStore(
        encryptedStorage: encryptedStorage ?? EncryptedStorage.instance,
      );

  Future<AppSettings> readSettings() async {
    if (_cache != null) return _cache!;

    final file = await _storageFile();
    final stored = await _fileStore.read(
      file,
      scope: _encryptionScope,
      validate: _validateStoredJson,
    );
    if (stored == null) {
      _cache = AppSettings.defaults();
      await saveSettings(_cache!);
      return _cache!;
    }

    final decoded = jsonDecode(stored.plaintext) as Map<String, dynamic>;
    _migrateSettings(decoded);
    final userType = decoded['user_type'];
    if (userType is String &&
        AppLanguage.values.any(
          (language) =>
              userType ==
              AppLocalizations(language).tr('flexible_financial_period_user'),
        )) {
      decoded['user_type'] = 'flexible_financial_period_user';
    }
    _cache = AppSettings.fromJson(decoded);
    await _saveSettings(_cache!, preserveExistingAsBackup: stored.wasEncrypted);
    return _cache!;
  }

  void _validateStoredJson(String plaintext) {
    final decoded = jsonDecode(plaintext);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Settings storage root must be an object.');
    }
    _migrateSettings(decoded);
    AppSettings.fromJson(decoded);
  }

  void _migrateSettings(Map<String, dynamic> settings) {
    var version = settings['schema_version'] as int? ?? 0;
    if (version > _schemaVersion) {
      throw FormatException(
        'Settings schema version $version is newer than supported version '
        '$_schemaVersion.',
      );
    }

    while (version < _schemaVersion) {
      switch (version) {
        case 0:
          settings['schema_version'] = 1;
          version = 1;
        case 1:
          settings['notification_permission_prompt_dismissed'] ??= false;
          settings['schema_version'] = 2;
          version = 2;
        case 2:
          settings['app_lock_enabled'] ??= false;
          settings['biometric_unlock_enabled'] ??= false;
          settings['app_lock_timeout'] ??= 'immediately';
          settings['schema_version'] = 3;
          version = 3;
        case 3:
          settings['backup_frequency'] ??= 'off';
          settings['schema_version'] = 4;
          version = 4;
        case 4:
          settings['export_report_template'] ??= 'dashboard';
          settings['schema_version'] = 5;
          version = 5;
        case 5:
          if (settings['email'] == AppIdentity.legacyDeveloperEmail) {
            settings['email'] = AppIdentity.developerEmail;
          }
          settings['schema_version'] = 6;
          version = 6;
        default:
          throw FormatException(
            'No settings migration exists from schema version $version.',
          );
      }
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    _cache = settings;
    await _saveSettings(settings);
  }

  Future<Map<String, dynamic>> exportBackupData() async {
    final settings = await readSettings();
    return {
      'has_completed_setup': settings.hasCompletedSetup,
      'display_name': settings.displayName,
      'email': settings.email,
      'user_type': settings.userType,
      'theme_id': settings.themeId,
      'language_code': settings.languageCode,
      'currency_code': settings.currencyCode,
      'hide_financial_amounts': settings.hideFinancialAmounts,
      'export_report_template': settings.exportReportTemplateCode,
    };
  }

  Future<AppSettings> restoreBackupData(Map<String, dynamic> backupData) async {
    final current = await readSettings();
    final restored = current.copyWith(
      hasCompletedSetup:
          backupData['has_completed_setup'] as bool? ??
          current.hasCompletedSetup,
      displayName: backupData['display_name'] as String? ?? current.displayName,
      email: backupData['email'] as String? ?? current.email,
      userType: backupData['user_type'] as String? ?? current.userType,
      themeId: backupData['theme_id'] as String? ?? current.themeId,
      languageCode:
          backupData['language_code'] as String? ?? current.languageCode,
      currencyCode:
          backupData['currency_code'] as String? ?? current.currencyCode,
      hideFinancialAmounts:
          backupData['hide_financial_amounts'] as bool? ??
          current.hideFinancialAmounts,
      exportReportTemplateCode:
          backupData['export_report_template'] as String? ??
          current.exportReportTemplateCode,
    );
    await saveSettings(restored);
    return restored;
  }

  Future<void> _saveSettings(
    AppSettings settings, {
    bool preserveExistingAsBackup = true,
  }) async {
    final file = await _storageFile();
    const encoder = JsonEncoder.withIndent('  ');
    final json = settings.toJson()..['schema_version'] = _schemaVersion;
    final plaintext = encoder.convert(json);
    await _writeQueue.run(
      () => _fileStore.write(
        file,
        plaintext,
        scope: _encryptionScope,
        preserveExistingAsBackup: preserveExistingAsBackup,
      ),
    );
  }

  Future<File> _storageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_storageFileName');
  }
}
