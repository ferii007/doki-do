import 'package:doki_do/features/security/presentation/providers/app_lock_provider.dart';
import 'package:doki_do/features/settings/domain/entities/app_lock_timeout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('starts locked when App Lock was enabled before app startup', () {
    final notifier = container.read(appLockSessionProvider.notifier);

    notifier.initialize(enabled: true);

    expect(container.read(appLockSessionProvider).locked, isTrue);
  });

  test('locks immediately after returning from background', () {
    final notifier = container.read(appLockSessionProvider.notifier);
    notifier.initialize(enabled: true);
    notifier.unlock();

    notifier.onBackground(
      timeout: AppLockTimeout.immediately,
      now: DateTime(2026, 7, 4, 10),
    );
    notifier.onResumed(
      timeout: AppLockTimeout.immediately,
      now: DateTime(2026, 7, 4, 10, 0, 1),
    );

    expect(container.read(appLockSessionProvider).locked, isTrue);
  });

  test('does not lock on a resumed event without entering background', () {
    final notifier = container.read(appLockSessionProvider.notifier);
    notifier.initialize(enabled: true);
    notifier.unlock();

    notifier.onResumed(
      timeout: AppLockTimeout.immediately,
      now: DateTime(2026, 7, 4, 10),
    );

    expect(container.read(appLockSessionProvider).locked, isFalse);
  });

  test('honors one-minute timeout', () {
    final notifier = container.read(appLockSessionProvider.notifier);
    notifier.initialize(enabled: true);
    notifier.unlock();

    notifier.onBackground(
      timeout: AppLockTimeout.afterOneMinute,
      now: DateTime(2026, 7, 4, 10),
    );
    notifier.onResumed(
      timeout: AppLockTimeout.afterOneMinute,
      now: DateTime(2026, 7, 4, 10, 0, 40),
    );
    expect(container.read(appLockSessionProvider).locked, isFalse);

    notifier.onBackground(
      timeout: AppLockTimeout.afterOneMinute,
      now: DateTime(2026, 7, 4, 10, 1),
    );
    notifier.onResumed(
      timeout: AppLockTimeout.afterOneMinute,
      now: DateTime(2026, 7, 4, 10, 2, 1),
    );
    expect(container.read(appLockSessionProvider).locked, isTrue);
  });

  test('does not lock while system authentication is in progress', () {
    final notifier = container.read(appLockSessionProvider.notifier);
    notifier.initialize(enabled: true);
    notifier.unlock();
    notifier.beginAuthentication();

    notifier.onBackground(
      timeout: AppLockTimeout.immediately,
      now: DateTime(2026, 7, 4, 10),
    );
    notifier.onResumed(
      timeout: AppLockTimeout.immediately,
      now: DateTime(2026, 7, 4, 10, 1),
    );
    notifier.endAuthentication();

    expect(container.read(appLockSessionProvider).locked, isFalse);
  });
}
