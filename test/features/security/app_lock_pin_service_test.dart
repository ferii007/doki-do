import 'dart:math';

import 'package:doki_do/features/security/data/app_lock_credential_store.dart';
import 'package:doki_do/features/security/domain/services/app_lock_pin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores a salted hash and verifies only the matching PIN', () async {
    final store = MemoryAppLockCredentialStore();
    final service = AppLockPinService(
      store: store,
      iterations: 100,
      random: Random(7),
    );

    await service.setPin('123456');

    expect(store.value, isNotNull);
    expect(store.value, isNot(contains('123456')));
    expect(await service.hasPin(), isTrue);
    expect(await service.verifyPin('123456'), isTrue);
    expect(await service.verifyPin('654321'), isFalse);
  });

  test('rejects invalid PIN formats and malformed credentials', () async {
    final store = MemoryAppLockCredentialStore();
    final service = AppLockPinService(store: store, iterations: 10);

    await expectLater(service.setPin('12345'), throwsFormatException);
    await expectLater(service.setPin('abcdef'), throwsFormatException);

    store.value = 'not-json';
    expect(await service.verifyPin('123456'), isFalse);
  });

  test('clears the stored PIN', () async {
    final store = MemoryAppLockCredentialStore();
    final service = AppLockPinService(store: store, iterations: 10);
    await service.setPin('123456');

    await service.clearPin();

    expect(await service.hasPin(), isFalse);
    expect(await service.verifyPin('123456'), isFalse);
  });
}
