import 'dart:async';
import 'dart:io';

import '../security/encrypted_storage.dart';
import 'atomic_file_writer.dart';

class ResilientStorageContent {
  final String plaintext;
  final bool wasEncrypted;
  final bool recoveredFromBackup;

  const ResilientStorageContent({
    required this.plaintext,
    required this.wasEncrypted,
    required this.recoveredFromBackup,
  });
}

class StorageRecoveryException implements Exception {
  final String message;
  final Object primaryError;
  final Object? backupError;

  const StorageRecoveryException({
    required this.message,
    required this.primaryError,
    this.backupError,
  });

  @override
  String toString() => 'StorageRecoveryException: $message';
}

class ResilientEncryptedFileStore {
  final EncryptedStorage _encryptedStorage;

  const ResilientEncryptedFileStore({
    required EncryptedStorage encryptedStorage,
  }) : _encryptedStorage = encryptedStorage;

  Future<ResilientStorageContent?> read(
    File file, {
    required String scope,
    FutureOr<void> Function(String plaintext)? validate,
  }) async {
    await AtomicFileWriter.recover(file);
    if (!await file.exists()) return null;

    try {
      final content = await _decryptFile(file, scope: scope);
      await validate?.call(content.plaintext);
      return ResilientStorageContent(
        plaintext: content.plaintext,
        wasEncrypted: content.wasEncrypted,
        recoveredFromBackup: false,
      );
    } on Object catch (primaryError) {
      final backup = AtomicFileWriter.backupFor(file);
      if (!await backup.exists()) {
        throw StorageRecoveryException(
          message:
              'The primary storage file is unreadable and no backup exists.',
          primaryError: primaryError,
        );
      }

      try {
        final backupContent = await _decryptFile(backup, scope: scope);
        await validate?.call(backupContent.plaintext);
        await AtomicFileWriter.restoreBackup(file);
        return ResilientStorageContent(
          plaintext: backupContent.plaintext,
          wasEncrypted: backupContent.wasEncrypted,
          recoveredFromBackup: true,
        );
      } on Object catch (backupError) {
        throw StorageRecoveryException(
          message: 'The primary and backup storage files are unreadable.',
          primaryError: primaryError,
          backupError: backupError,
        );
      }
    }
  }

  Future<void> write(
    File file,
    String plaintext, {
    required String scope,
    bool preserveExistingAsBackup = true,
  }) async {
    final encrypted = await _encryptedStorage.encrypt(plaintext, scope: scope);
    await AtomicFileWriter.writeString(
      file,
      encrypted,
      preserveExistingAsBackup: preserveExistingAsBackup,
    );
  }

  Future<DecryptedStorageContent> _decryptFile(
    File file, {
    required String scope,
  }) async {
    return _encryptedStorage.decrypt(await file.readAsString(), scope: scope);
  }
}
