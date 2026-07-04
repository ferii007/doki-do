import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/services/device_authentication_service.dart';
import '../providers/app_lock_provider.dart';
import '../widgets/app_pin_pad.dart';
import 'app_lock_pin_setup_screen.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  final bool biometricEnabled;

  const AppLockScreen({super.key, required this.biometricEnabled});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _pin = '';
  String? _errorKey;
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  bool _verifying = false;
  bool _resettingPin = false;
  bool _automaticBiometricAttempted = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_automaticBiometricAttempted) {
          _automaticBiometricAttempted = true;
          _authenticateBiometric();
        }
      });
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_resettingPin) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: AppLockPinSetupPanel(
            titleKey: 'create_new_app_lock_pin',
            descriptionKey: 'recovered_pin_description',
            onComplete: _saveRecoveredPin,
          ),
        ),
      );
    }

    final canInput = !_verifying && _cooldownSeconds == 0;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('unlock_dokido'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('enter_app_lock_pin'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              AppPinDots(filledCount: _pin.length, hasError: _errorKey != null),
              SizedBox(
                height: 38,
                child: Center(
                  child: _verifying
                      ? Text(
                          context.tr('verifying'),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                        )
                      : Text(
                          _cooldownSeconds > 0
                              ? context.trf('try_again_in_seconds', {
                                  'seconds': _cooldownSeconds,
                                })
                              : _errorKey == null
                              ? ''
                              : context.tr(_errorKey!),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                ),
              ),
              const Spacer(),
              AppPinPad(
                enabled: canInput,
                onDigit: _addDigit,
                onBackspace: _removeDigit,
                onBiometric: widget.biometricEnabled
                    ? _authenticateBiometric
                    : null,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _verifying ? null : _recoverPin,
                child: Text(context.tr('forgot_pin')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addDigit(int digit) {
    if (_pin.length >= 6 || _cooldownSeconds > 0 || _verifying) return;
    setState(() {
      _pin += '$digit';
      _errorKey = null;
    });
    if (_pin.length == 6) _verifyPin();
  }

  void _removeDigit() {
    if (_pin.isEmpty || _verifying) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorKey = null;
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _verifying = true);
    final valid = await ref.read(appLockPinServiceProvider).verifyPin(_pin);
    if (!mounted) return;
    if (valid) {
      ref.read(appLockSessionProvider.notifier).unlock();
      return;
    }

    _failedAttempts++;
    setState(() {
      _verifying = false;
      _pin = '';
      _errorKey = 'incorrect_pin';
    });
    if (_failedAttempts >= 5) _startCooldown();
  }

  void _startCooldown() {
    final tier = ((_failedAttempts - 5) ~/ 2).clamp(0, 4);
    final seconds = min(30 * pow(2, tier).toInt(), 300);
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _authenticateBiometric() async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _errorKey = null;
    });
    final session = ref.read(appLockSessionProvider.notifier);
    session.beginAuthentication();
    final result = await ref
        .read(deviceAuthenticationServiceProvider)
        .authenticateBiometric(context.tr('biometric_unlock_reason'));
    if (!mounted) return;
    final success = result == DeviceAuthenticationResult.success;
    session.endAuthentication(unlock: success);
    if (success) return;

    setState(() {
      _verifying = false;
      if (result != DeviceAuthenticationResult.canceled) {
        _errorKey = _deviceAuthErrorKey(result);
      }
    });
  }

  Future<void> _recoverPin() async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _errorKey = null;
    });
    final session = ref.read(appLockSessionProvider.notifier);
    session.beginAuthentication();
    final result = await ref
        .read(deviceAuthenticationServiceProvider)
        .authenticateDevice(context.tr('recover_pin_reason'));
    if (!mounted) return;
    session.endAuthentication();

    if (result == DeviceAuthenticationResult.success) {
      setState(() {
        _verifying = false;
        _resettingPin = true;
      });
      return;
    }
    setState(() {
      _verifying = false;
      if (result != DeviceAuthenticationResult.canceled) {
        _errorKey = _deviceAuthErrorKey(result);
      }
    });
  }

  Future<void> _saveRecoveredPin(String pin) async {
    await ref.read(appLockPinServiceProvider).setPin(pin);
    if (!mounted) return;
    ref.read(appLockSessionProvider.notifier).unlock();
  }

  String _deviceAuthErrorKey(DeviceAuthenticationResult result) {
    return switch (result) {
      DeviceAuthenticationResult.unavailable => 'device_auth_unavailable',
      DeviceAuthenticationResult.locked => 'device_auth_locked',
      _ => 'authentication_failed',
    };
  }
}
