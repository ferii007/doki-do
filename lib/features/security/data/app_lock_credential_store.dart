import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AppLockCredentialStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> delete();
}

class PlatformAppLockCredentialStore implements AppLockCredentialStore {
  static const _credentialKey = 'doki_do_app_lock_pin_v1';

  final FlutterSecureStorage _storage;

  const PlatformAppLockCredentialStore({
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

class MemoryAppLockCredentialStore implements AppLockCredentialStore {
  String? value;

  MemoryAppLockCredentialStore([this.value]);

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
