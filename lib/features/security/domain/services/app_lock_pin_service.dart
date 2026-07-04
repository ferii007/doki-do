import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../../data/app_lock_credential_store.dart';

class AppLockPinService {
  static const pinLength = 6;

  final AppLockCredentialStore _store;
  final int _iterations;
  final Random _random;

  AppLockPinService({
    required AppLockCredentialStore store,
    int iterations = 210000,
    Random? random,
  }) : _store = store,
       _iterations = iterations,
       _random = random ?? Random.secure();

  Future<bool> hasPin() async {
    final stored = await _store.read();
    return stored != null && stored.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    if (!_isValidPin(pin)) {
      throw const FormatException(
        'App Lock PIN must contain exactly 6 digits.',
      );
    }

    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final hash = await _derive(pin, salt, _iterations);
    await _store.write(
      jsonEncode({
        'version': 1,
        'iterations': _iterations,
        'salt': base64Encode(salt),
        'hash': base64Encode(hash),
      }),
    );
  }

  Future<bool> verifyPin(String pin) async {
    if (!_isValidPin(pin)) return false;
    final stored = await _store.read();
    if (stored == null) return false;

    try {
      final record = jsonDecode(stored) as Map<String, dynamic>;
      if (record['version'] != 1) return false;
      final iterations = record['iterations'] as int;
      final salt = base64Decode(record['salt'] as String);
      final expected = base64Decode(record['hash'] as String);
      final actual = await _derive(pin, salt, iterations);
      return _constantTimeEquals(expected, actual);
    } on Object {
      return false;
    }
  }

  Future<void> clearPin() => _store.delete();

  Future<List<int>> _derive(String pin, List<int> salt, int iterations) async {
    final key = await Pbkdf2.hmacSha256(
      iterations: iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: pin, nonce: salt);
    return key.extractBytes();
  }

  bool _isValidPin(String pin) {
    return pin.length == pinLength && RegExp(r'^\d{6}$').hasMatch(pin);
  }

  bool _constantTimeEquals(List<int> expected, List<int> actual) {
    if (expected.length != actual.length) return false;
    var difference = 0;
    for (var index = 0; index < expected.length; index++) {
      difference |= expected[index] ^ actual[index];
    }
    return difference == 0;
  }
}
