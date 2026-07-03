import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/security/encrypted_storage.dart';
import '../../../../core/storage/async_write_queue.dart';
import '../../../../core/storage/resilient_encrypted_file_store.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';

class SettingsLocalDatasource {
  static const _schemaVersion = 1;
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
