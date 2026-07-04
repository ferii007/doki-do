import 'dart:convert';

import 'package:flutter/services.dart';

class BackupDirectory {
  final String uri;
  final String name;

  const BackupDirectory({required this.uri, required this.name});
}

class BackupFileContent {
  final String name;
  final Uint8List bytes;

  const BackupFileContent({required this.name, required this.bytes});
}

abstract interface class BackupFileGateway {
  Future<BackupDirectory?> chooseDirectory();

  Future<void> writeRotatingBackup({
    required String directoryUri,
    required Uint8List bytes,
  });

  Future<BackupFileContent?> readLatestBackup(String directoryUri);

  Future<BackupFileContent?> chooseBackupFile();
}

class PlatformBackupFileGateway implements BackupFileGateway {
  static const currentFileName = 'DokiDo_AutoBackup_Current.dokido';
  static const previousFileName = 'DokiDo_AutoBackup_Previous.dokido';
  static const _channel = MethodChannel('com.dokido.finance/backup_files');

  const PlatformBackupFileGateway();

  @override
  Future<BackupDirectory?> chooseDirectory() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'chooseDirectory',
    );
    if (result == null) return null;
    return BackupDirectory(
      uri: result['uri'] as String,
      name: result['name'] as String,
    );
  }

  @override
  Future<void> writeRotatingBackup({
    required String directoryUri,
    required Uint8List bytes,
  }) async {
    await _channel.invokeMethod<void>('writeRotatingBackup', {
      'directoryUri': directoryUri,
      'currentFileName': currentFileName,
      'previousFileName': previousFileName,
      'content': base64Encode(bytes),
    });
  }

  @override
  Future<BackupFileContent?> readLatestBackup(String directoryUri) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'readBackupFromDirectory',
      {'directoryUri': directoryUri, 'fileName': currentFileName},
    );
    return _decodeFile(result);
  }

  @override
  Future<BackupFileContent?> chooseBackupFile() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'chooseBackupFile',
    );
    return _decodeFile(result);
  }

  BackupFileContent? _decodeFile(Map<String, dynamic>? result) {
    if (result == null) return null;
    return BackupFileContent(
      name: result['name'] as String,
      bytes: Uint8List.fromList(base64Decode(result['content'] as String)),
    );
  }
}

class MemoryBackupFileGateway implements BackupFileGateway {
  BackupDirectory? directory;
  BackupFileContent? current;
  BackupFileContent? previous;
  BackupFileContent? pickedFile;

  @override
  Future<BackupDirectory?> chooseDirectory() async => directory;

  @override
  Future<void> writeRotatingBackup({
    required String directoryUri,
    required Uint8List bytes,
  }) async {
    previous = current;
    current = BackupFileContent(
      name: PlatformBackupFileGateway.currentFileName,
      bytes: bytes,
    );
  }

  @override
  Future<BackupFileContent?> readLatestBackup(String directoryUri) async {
    return current;
  }

  @override
  Future<BackupFileContent?> chooseBackupFile() async => pickedFile;
}
