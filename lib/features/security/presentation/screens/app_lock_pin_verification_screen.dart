import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/app_lock_provider.dart';
import '../widgets/app_pin_pad.dart';

class AppLockPinVerificationScreen extends ConsumerStatefulWidget {
  const AppLockPinVerificationScreen({super.key});

  @override
  ConsumerState<AppLockPinVerificationScreen> createState() =>
      _AppLockPinVerificationScreenState();
}

class _AppLockPinVerificationScreenState
    extends ConsumerState<AppLockPinVerificationScreen> {
  String _pin = '';
  bool _verifying = false;
  bool _invalid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('verify_app_lock_pin'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.lock_person_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('verify_it_is_you'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('verify_pin_description'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 26),
              AppPinDots(filledCount: _pin.length, hasError: _invalid),
              SizedBox(
                height: 38,
                child: Center(
                  child: Text(
                    _verifying
                        ? context.tr('verifying')
                        : _invalid
                        ? context.tr('incorrect_pin')
                        : '',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _invalid
                          ? AppColors.danger
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              AppPinPad(
                enabled: !_verifying,
                onDigit: _addDigit,
                onBackspace: _removeDigit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addDigit(int digit) {
    if (_pin.length >= 6 || _verifying) return;
    setState(() {
      _pin += '$digit';
      _invalid = false;
    });
    if (_pin.length == 6) _verify();
  }

  void _removeDigit() {
    if (_pin.isEmpty || _verifying) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _invalid = false;
    });
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    final valid = await ref.read(appLockPinServiceProvider).verifyPin(_pin);
    if (!mounted) return;
    if (valid) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _pin = '';
      _verifying = false;
      _invalid = true;
    });
  }
}
