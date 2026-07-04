import 'package:local_auth/local_auth.dart';

enum DeviceAuthenticationResult {
  success,
  canceled,
  unavailable,
  locked,
  failed,
}

class DeviceAuthenticationService {
  final LocalAuthentication _authentication;

  DeviceAuthenticationService({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  Future<bool> hasEnrolledBiometrics() async {
    try {
      final supported = await _authentication.canCheckBiometrics;
      if (!supported) return false;
      return (await _authentication.getAvailableBiometrics()).isNotEmpty;
    } on LocalAuthException {
      return false;
    }
  }

  Future<bool> isDeviceAuthenticationAvailable() async {
    try {
      return await _authentication.isDeviceSupported();
    } on LocalAuthException {
      return false;
    }
  }

  Future<DeviceAuthenticationResult> authenticateBiometric(
    String localizedReason,
  ) {
    return _authenticate(localizedReason: localizedReason, biometricOnly: true);
  }

  Future<DeviceAuthenticationResult> authenticateDevice(
    String localizedReason,
  ) {
    return _authenticate(
      localizedReason: localizedReason,
      biometricOnly: false,
    );
  }

  Future<DeviceAuthenticationResult> _authenticate({
    required String localizedReason,
    required bool biometricOnly,
  }) async {
    try {
      final authenticated = await _authentication.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
      );
      return authenticated
          ? DeviceAuthenticationResult.success
          : DeviceAuthenticationResult.failed;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          DeviceAuthenticationResult.canceled,
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable ||
        LocalAuthExceptionCode.uiUnavailable =>
          DeviceAuthenticationResult.unavailable,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          DeviceAuthenticationResult.locked,
        _ => DeviceAuthenticationResult.failed,
      };
    }
  }
}
