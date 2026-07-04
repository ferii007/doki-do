import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class BackupCredentialStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> delete();
}

class PlatformBackupCredentialStore implements BackupCredentialStore {
  static const _credentialKey = 'doki_do_backup_credential_v1';

  final FlutterSecureStorage _storage;

  const PlatformBackupCredentialStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: false,
        migrateWithBackup: true,
        storageNamespace: 'doki_do_secure_storage',
      ),
    ),
  }) : _storage = storage;

  @override
  Future<String?> read() => _storage.read(key: _credentialKey);

  @override
  Future<void> write(String value) {
    return _storage.write(key: _credentialKey, value: value);
  }

  @override
  Future<void> delete() => _storage.delete(key: _credentialKey);
}

class MemoryBackupCredentialStore implements BackupCredentialStore {
  String? value;

  MemoryBackupCredentialStore([this.value]);

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> delete() async {
    value = null;
  }
}
