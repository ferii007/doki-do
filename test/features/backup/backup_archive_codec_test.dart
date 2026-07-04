import 'dart:convert';
import 'dart:math';

import 'package:doki_do/features/backup/data/backup_credential_store.dart';
import 'package:doki_do/features/backup/domain/backup_archive.dart';
import 'package:doki_do/features/backup/domain/backup_archive_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryBackupCredentialStore credentialStore;
  late BackupArchiveCodec codec;

  setUp(() {
    credentialStore = MemoryBackupCredentialStore();
    codec = BackupArchiveCodec(
      credentialStore: credentialStore,
      iterations: 10,
      random: Random(1),
    );
  });

  test(
    'round-trips an encrypted backup with the configured password',
    () async {
      await codec.configurePassword('rahasia-backup');
      final archive = BackupArchive(
        createdAt: DateTime(2026, 7, 2, 10, 30),
        finance: {'schema_version': 2, 'periods': <Map<String, dynamic>>[]},
        settings: {'display_name': 'Feri'},
      );

      final encoded = await codec.encodeWithStoredCredential(archive);
      final decoded = await codec.decodeWithPassword(encoded, 'rahasia-backup');

      expect(utf8.decode(encoded), isNot(contains('Feri')));
      expect(decoded.settings['display_name'], 'Feri');
      expect(decoded.createdAt, archive.createdAt);
    },
  );

  test('rejects an incorrect password', () async {
    await codec.configurePassword('rahasia-backup');
    final encoded = await codec.encodeWithStoredCredential(
      BackupArchive(
        createdAt: DateTime(2026, 7, 2),
        finance: const {'periods': []},
        settings: const {},
      ),
    );

    expect(
      () => codec.decodeWithPassword(encoded, 'password-salah'),
      throwsA(
        isA<BackupArchiveException>().having(
          (error) => error.code,
          'code',
          'backup_password_or_file_invalid',
        ),
      ),
    );
  });

  test('rejects a modified encrypted payload', () async {
    await codec.configurePassword('rahasia-backup');
    final encoded = await codec.encodeWithStoredCredential(
      BackupArchive(
        createdAt: DateTime(2026, 7, 2),
        finance: const {'periods': []},
        settings: const {},
      ),
    );
    final envelope = jsonDecode(utf8.decode(encoded)) as Map<String, dynamic>;
    final ciphertext = envelope['ciphertext'] as String;
    envelope['ciphertext'] =
        '${ciphertext.substring(0, ciphertext.length - 2)}AA';
    final modified = utf8.encode(jsonEncode(envelope));

    expect(
      () => codec.decodeWithPassword(modified, 'rahasia-backup'),
      throwsA(isA<BackupArchiveException>()),
    );
  });
}
