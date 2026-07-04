import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../data/backup_credential_store.dart';
import 'backup_archive.dart';

class BackupKeyMaterial {
  final int iterations;
  final List<int> salt;
  final List<int> key;

  const BackupKeyMaterial({
    required this.iterations,
    required this.salt,
    required this.key,
  });
}

class BackupArchiveException implements Exception {
  final String code;
  final Object? cause;

  const BackupArchiveException(this.code, [this.cause]);

  @override
  String toString() => 'BackupArchiveException: $code';
}

class BackupArchiveCodec {
  static const _envelopeFormat = 'dokido-backup-aes-gcm';
  static const _envelopeVersion = 1;
  static const defaultIterations = 310000;

  final BackupCredentialStore _credentialStore;
  final Cipher _cipher;
  final Random _random;
  final int _iterations;

  BackupArchiveCodec({
    required BackupCredentialStore credentialStore,
    Cipher? cipher,
    Random? random,
    int iterations = defaultIterations,
  }) : _credentialStore = credentialStore,
       _cipher = cipher ?? AesGcm.with256bits(),
       _random = random ?? Random.secure(),
       _iterations = iterations;

  Future<bool> hasStoredCredential() async {
    return await _readStoredKey() != null;
  }

  Future<void> configurePassword(String password) async {
    _validatePassword(password);
    final salt = _randomBytes(16);
    final key = await _deriveKey(password, salt, _iterations);
    await _credentialStore.write(
      jsonEncode({
        'version': 1,
        'iterations': _iterations,
        'salt': base64Encode(salt),
        'key': base64Encode(key),
      }),
    );
  }

  Future<void> clearCredential() => _credentialStore.delete();

  Future<Uint8List> encodeWithStoredCredential(BackupArchive archive) async {
    final material = await _readStoredKey();
    if (material == null) {
      throw const BackupArchiveException('backup_password_not_configured');
    }
    return _encode(archive, material);
  }

  Future<BackupArchive> decodeWithPassword(
    List<int> bytes,
    String password,
  ) async {
    _validatePassword(password);
    try {
      final envelope = _decodeEnvelope(bytes);
      final iterations = envelope['iterations'] as int;
      final salt = base64Decode(envelope['salt'] as String);
      final key = await _deriveKey(password, salt, iterations);
      return _decryptEnvelope(envelope, key);
    } on BackupArchiveException {
      rethrow;
    } on Object catch (error) {
      throw BackupArchiveException('backup_password_or_file_invalid', error);
    }
  }

  Future<BackupArchive> decodeWithStoredCredential(List<int> bytes) async {
    final material = await _readStoredKey();
    if (material == null) {
      throw const BackupArchiveException('backup_password_not_configured');
    }
    final envelope = _decodeEnvelope(bytes);
    final envelopeSalt = base64Decode(envelope['salt'] as String);
    if (!_constantTimeEquals(material.salt, envelopeSalt)) {
      throw const BackupArchiveException('backup_credential_mismatch');
    }
    return _decryptEnvelope(envelope, material.key);
  }

  Future<Uint8List> _encode(
    BackupArchive archive,
    BackupKeyMaterial material,
  ) async {
    final nonce = _randomBytes(12);
    final plaintext = utf8.encode(jsonEncode(archive.toJson()));
    final secretBox = await _cipher.encrypt(
      plaintext,
      secretKey: SecretKey(material.key),
      nonce: nonce,
      aad: _additionalData,
    );
    final envelope = {
      'format': _envelopeFormat,
      'version': _envelopeVersion,
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': material.iterations,
      'salt': base64Encode(material.salt),
      'cipher': 'aes-256-gcm',
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<BackupArchive> _decryptEnvelope(
    Map<String, dynamic> envelope,
    List<int> key,
  ) async {
    try {
      final cleartext = await _cipher.decrypt(
        SecretBox(
          base64Decode(envelope['ciphertext'] as String),
          nonce: base64Decode(envelope['nonce'] as String),
          mac: Mac(base64Decode(envelope['mac'] as String)),
        ),
        secretKey: SecretKey(key),
        aad: _additionalData,
      );
      final decoded = jsonDecode(utf8.decode(cleartext));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Backup root must be an object.');
      }
      return BackupArchive.fromJson(decoded);
    } on Object catch (error) {
      throw BackupArchiveException('backup_password_or_file_invalid', error);
    }
  }

  Map<String, dynamic> _decodeEnvelope(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['format'] != _envelopeFormat ||
          decoded['version'] != _envelopeVersion ||
          decoded['kdf'] != 'pbkdf2-hmac-sha256' ||
          decoded['cipher'] != 'aes-256-gcm' ||
          decoded['iterations'] is! int ||
          decoded['salt'] is! String ||
          decoded['nonce'] is! String ||
          decoded['ciphertext'] is! String ||
          decoded['mac'] is! String) {
        throw const FormatException('Invalid backup envelope.');
      }
      return decoded;
    } on Object catch (error) {
      throw BackupArchiveException('backup_file_invalid', error);
    }
  }

  Future<BackupKeyMaterial?> _readStoredKey() async {
    final stored = await _credentialStore.read();
    if (stored == null || stored.isEmpty) return null;
    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      if (decoded['version'] != 1) return null;
      final iterations = decoded['iterations'] as int;
      final salt = base64Decode(decoded['salt'] as String);
      final key = base64Decode(decoded['key'] as String);
      if (salt.length != 16 || key.length != 32) return null;
      return BackupKeyMaterial(iterations: iterations, salt: salt, key: key);
    } on Object {
      return null;
    }
  }

  Future<List<int>> _deriveKey(
    String password,
    List<int> salt,
    int iterations,
  ) async {
    final key = await Pbkdf2.hmacSha256(
      iterations: iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: salt);
    return key.extractBytes();
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const BackupArchiveException('backup_password_too_short');
    }
  }

  bool _constantTimeEquals(List<int> expected, List<int> actual) {
    if (expected.length != actual.length) return false;
    var difference = 0;
    for (var index = 0; index < expected.length; index++) {
      difference |= expected[index] ^ actual[index];
    }
    return difference == 0;
  }

  List<int> get _additionalData =>
      utf8.encode('DokiDo:portable-backup:v$_envelopeVersion');
}
