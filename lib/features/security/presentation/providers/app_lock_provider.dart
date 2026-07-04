import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/domain/entities/app_lock_timeout.dart';
import '../../data/app_lock_credential_store.dart';
import '../../domain/services/app_lock_pin_service.dart';
import '../../domain/services/device_authentication_service.dart';

final appLockCredentialStoreProvider = Provider<AppLockCredentialStore>((ref) {
  return const PlatformAppLockCredentialStore();
});

final appLockPinServiceProvider = Provider<AppLockPinService>((ref) {
  return AppLockPinService(store: ref.watch(appLockCredentialStoreProvider));
});

final deviceAuthenticationServiceProvider =
    Provider<DeviceAuthenticationService>((ref) {
      return DeviceAuthenticationService();
    });

final appLockSessionProvider =
    NotifierProvider<AppLockSessionNotifier, AppLockSession>(
      AppLockSessionNotifier.new,
    );

class AppLockSession {
  final bool initialized;
  final bool enabled;
  final bool locked;
  final bool obscured;
  final bool authenticationInProgress;
  final DateTime? backgroundedAt;

  const AppLockSession({
    required this.initialized,
    required this.enabled,
    required this.locked,
    required this.obscured,
    required this.authenticationInProgress,
    required this.backgroundedAt,
  });

  const AppLockSession.initial()
    : initialized = false,
      enabled = false,
      locked = false,
      obscured = false,
      authenticationInProgress = false,
      backgroundedAt = null;

  AppLockSession copyWith({
    bool? initialized,
    bool? enabled,
    bool? locked,
    bool? obscured,
    bool? authenticationInProgress,
    DateTime? backgroundedAt,
    bool clearBackgroundedAt = false,
  }) {
    return AppLockSession(
      initialized: initialized ?? this.initialized,
      enabled: enabled ?? this.enabled,
      locked: locked ?? this.locked,
      obscured: obscured ?? this.obscured,
      authenticationInProgress:
          authenticationInProgress ?? this.authenticationInProgress,
      backgroundedAt: clearBackgroundedAt
          ? null
          : backgroundedAt ?? this.backgroundedAt,
    );
  }
}

class AppLockSessionNotifier extends Notifier<AppLockSession> {
  @override
  AppLockSession build() => const AppLockSession.initial();

  void initialize({required bool enabled}) {
    if (state.initialized) return;
    state = state.copyWith(
      initialized: true,
      enabled: enabled,
      locked: enabled,
      obscured: false,
      clearBackgroundedAt: true,
    );
  }

  void configureEnabled({required bool enabled, bool lockNow = false}) {
    state = state.copyWith(
      initialized: true,
      enabled: enabled,
      locked: enabled && (lockNow || state.locked),
      obscured: false,
      authenticationInProgress: false,
      clearBackgroundedAt: true,
    );
  }

  void onBackground({required AppLockTimeout timeout, DateTime? now}) {
    if (!state.enabled || state.authenticationInProgress) return;
    state = state.copyWith(
      locked: state.locked || timeout == AppLockTimeout.immediately,
      obscured: true,
      backgroundedAt: now ?? DateTime.now(),
    );
  }

  void onResumed({required AppLockTimeout timeout, DateTime? now}) {
    if (!state.enabled) return;
    if (state.authenticationInProgress) {
      state = state.copyWith(obscured: false);
      return;
    }
    if (state.backgroundedAt == null) {
      state = state.copyWith(obscured: false);
      return;
    }

    final resumedAt = now ?? DateTime.now();
    final elapsed = resumedAt.difference(state.backgroundedAt!);
    final timeoutReached =
        timeout == AppLockTimeout.immediately || elapsed >= timeout.duration;
    state = state.copyWith(
      locked: state.locked || timeoutReached,
      obscured: false,
      clearBackgroundedAt: true,
    );
  }

  void beginAuthentication() {
    state = state.copyWith(authenticationInProgress: true, obscured: false);
  }

  void endAuthentication({bool unlock = false}) {
    state = state.copyWith(
      authenticationInProgress: false,
      locked: unlock ? false : state.locked,
      obscured: false,
      clearBackgroundedAt: unlock,
    );
  }

  void unlock() {
    state = state.copyWith(
      locked: false,
      obscured: false,
      authenticationInProgress: false,
      clearBackgroundedAt: true,
    );
  }

  void lock() {
    if (!state.enabled) return;
    state = state.copyWith(
      locked: true,
      obscured: false,
      clearBackgroundedAt: true,
    );
  }
}
