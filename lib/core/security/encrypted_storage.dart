import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_info/app_identity.dart';

abstract interface class EncryptionKeyStore {
  Future<String?> read();

  Future<void> write(String value);
}

class PlatformEncryptionKeyStore implements EncryptionKeyStore {
  static const _masterKeyName = 'doki_do_storage_master_key_v1';

  final FlutterSecureStorage _storage;

  const PlatformEncryptionKeyStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: false,
        migrateWithBackup: true,
        storageNamespace: 'doki_do_secure_storage',
      ),
    ),
  }) : _storage = storage;

  @override
  Future<String?> read() => _storage.read(key: _masterKeyName);

  @override
  Future<void> write(String value) {
    return _storage.write(key: _masterKeyName, value: value);
  }
}

class MemoryEncryptionKeyStore implements EncryptionKeyStore {
  String? value;

  MemoryEncryptionKeyStore([this.value]);

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}

class DecryptedStorageContent {
  final String plaintext;
  final bool wasEncrypted;

  const DecryptedStorageContent({
    required this.plaintext,
    required this.wasEncrypted,
  });
}

class EncryptedStorageException implements Exception {
  final String message;
  final Object? cause;

  const EncryptedStorageException(this.message, [this.cause]);

  @override
  String toString() => 'EncryptedStorageException: $message';
}

class EncryptedStorage {
  static const _format = 'dokido-aes-gcm';
  static const _version = 1;

  static final instance = EncryptedStorage(
    keyStore: const PlatformEncryptionKeyStore(),
  );

  final EncryptionKeyStore _keyStore;
  final Cipher _cipher;
  Future<SecretKey>? _masterKeyFuture;

  EncryptedStorage({required EncryptionKeyStore keyStore, Cipher? cipher})
    : _keyStore = keyStore,
      _cipher = cipher ?? AesGcm.with256bits();

  Future<String> encrypt(String plaintext, {required String scope}) async {
    final key = await _masterKey();
    final box = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      aad: _additionalData(scope),
    );
    return jsonEncode({
      'format': _format,
      'version': _version,
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  Future<DecryptedStorageContent> decrypt(
    String storedContent, {
    required String scope,
  }) async {
    final envelope = _encryptedEnvelope(storedContent);
    if (envelope == null) {
      return DecryptedStorageContent(
        plaintext: storedContent,
        wasEncrypted: false,
      );
    }

    try {
      final version = envelope['version'];
      if (version != _version) {
        throw EncryptedStorageException(
          'Unsupported encrypted storage version: $version.',
        );
      }
      final box = SecretBox(
        base64Decode(_requiredString(envelope, 'ciphertext')),
        nonce: base64Decode(_requiredString(envelope, 'nonce')),
        mac: Mac(base64Decode(_requiredString(envelope, 'mac'))),
      );
      final clearText = await _cipher.decrypt(
        box,
        secretKey: await _masterKey(),
        aad: _additionalData(scope),
      );
      return DecryptedStorageContent(
        plaintext: utf8.decode(clearText),
        wasEncrypted: true,
      );
    } on EncryptedStorageException {
      rethrow;
    } on Object catch (error) {
      throw EncryptedStorageException(
        'Encrypted data could not be authenticated or decrypted.',
        error,
      );
    }
  }

  Future<SecretKey> _masterKey() {
    return _masterKeyFuture ??= _loadOrCreateMasterKey();
  }

  Future<SecretKey> _loadOrCreateMasterKey() async {
    final storedKey = await _keyStore.read();
    if (storedKey != null) {
      try {
        final bytes = base64Decode(storedKey);
        if (bytes.length != 32) {
          throw const FormatException('Invalid AES-256 key length.');
        }
        return SecretKey(bytes);
      } on FormatException catch (error) {
        throw EncryptedStorageException(
          'The stored encryption key is invalid.',
          error,
        );
      }
    }

    final key = await _cipher.newSecretKey();
    final bytes = await key.extractBytes();
    await _keyStore.write(base64Encode(bytes));
    return key;
  }

  Map<String, dynamic>? _encryptedEnvelope(String content) {
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic> || decoded['format'] != _format) {
      return null;
    }
    return decoded;
  }

  String _requiredString(Map<String, dynamic> envelope, String key) {
    final value = envelope[key];
    if (value is! String || value.isEmpty) {
      throw EncryptedStorageException(
        'Encrypted storage field "$key" is missing.',
      );
    }
    return value;
  }

  List<int> _additionalData(String scope) {
    return utf8.encode('${AppIdentity.storageProtocolId}:$scope:v$_version');
  }
}
