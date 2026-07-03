import 'dart:convert';

import 'package:doki_do/core/security/encrypted_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encrypts and decrypts content with authenticated AES-GCM', () async {
    final storage = EncryptedStorage(keyStore: MemoryEncryptionKeyStore());
    const plaintext = '{"amount":1000000}';

    final encrypted = await storage.encrypt(plaintext, scope: 'finance');
    final decrypted = await storage.decrypt(encrypted, scope: 'finance');

    expect(encrypted, isNot(contains('1000000')));
    expect(decrypted.plaintext, plaintext);
    expect(decrypted.wasEncrypted, isTrue);
  });

  test('recognizes legacy plaintext for one-time migration', () async {
    final storage = EncryptedStorage(keyStore: MemoryEncryptionKeyStore());
    const plaintext = '{"periods":[]}';

    final decoded = await storage.decrypt(plaintext, scope: 'finance');

    expect(decoded.plaintext, plaintext);
    expect(decoded.wasEncrypted, isFalse);
  });

  test(
    'rejects modified ciphertext instead of returning corrupt data',
    () async {
      final storage = EncryptedStorage(keyStore: MemoryEncryptionKeyStore());
      final encrypted = await storage.encrypt(
        '{"amount":1000000}',
        scope: 'finance',
      );
      final envelope = jsonDecode(encrypted) as Map<String, dynamic>;
      final ciphertext = envelope['ciphertext'] as String;
      envelope['ciphertext'] =
          '${ciphertext.substring(0, ciphertext.length - 2)}AA';

      expect(
        () => storage.decrypt(jsonEncode(envelope), scope: 'finance'),
        throwsA(isA<EncryptedStorageException>()),
      );
    },
  );

  test('binds ciphertext to its storage scope', () async {
    final storage = EncryptedStorage(keyStore: MemoryEncryptionKeyStore());
    final encrypted = await storage.encrypt(
      '{"amount":1000000}',
      scope: 'finance',
    );

    expect(
      () => storage.decrypt(encrypted, scope: 'settings'),
      throwsA(isA<EncryptedStorageException>()),
    );
  });
}
