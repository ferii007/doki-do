import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/app_pin_pad.dart';

class AppLockPinSetupScreen extends StatelessWidget {
  final String titleKey;
  final String descriptionKey;

  const AppLockPinSetupScreen({
    super.key,
    this.titleKey = 'create_app_lock_pin',
    this.descriptionKey = 'create_app_lock_pin_description',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('app_lock'))),
      body: SafeArea(
        child: AppLockPinSetupPanel(
          titleKey: titleKey,
          descriptionKey: descriptionKey,
          onComplete: (pin) => Navigator.pop(context, pin),
        ),
      ),
    );
  }
}

class AppLockPinSetupPanel extends StatefulWidget {
  final String titleKey;
  final String descriptionKey;
  final ValueChanged<String> onComplete;
  final VoidCallback? onCancel;

  const AppLockPinSetupPanel({
    super.key,
    required this.titleKey,
    required this.descriptionKey,
    required this.onComplete,
    this.onCancel,
  });

  @override
  State<AppLockPinSetupPanel> createState() => _AppLockPinSetupPanelState();
}

class _AppLockPinSetupPanelState extends State<AppLockPinSetupPanel> {
  String _pin = '';
  String? _firstPin;
  String? _errorKey;

  bool get _confirming => _firstPin != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
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
              _confirming ? Icons.verified_user_outlined : Icons.pin_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr(_confirming ? 'confirm_app_lock_pin' : widget.titleKey),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              _confirming
                  ? 'confirm_app_lock_pin_description'
                  : widget.descriptionKey,
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          AppPinDots(filledCount: _pin.length, hasError: _errorKey != null),
          SizedBox(
            height: 32,
            child: _errorKey == null
                ? null
                : Center(
                    child: Text(
                      context.tr(_errorKey!),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
          ),
          const Spacer(),
          AppPinPad(onDigit: _addDigit, onBackspace: _removeDigit),
          if (widget.onCancel != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: widget.onCancel,
              child: Text(context.tr('cancel')),
            ),
          ],
        ],
      ),
    );
  }

  void _addDigit(int digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += '$digit';
      _errorKey = null;
    });
    if (_pin.length == 6) _submitStep();
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorKey = null;
    });
  }

  void _submitStep() {
    if (_firstPin == null) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() {
          _firstPin = _pin;
          _pin = '';
        });
      });
      return;
    }

    if (_pin != _firstPin) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() {
          _pin = '';
          _errorKey = 'pin_does_not_match';
        });
      });
      return;
    }
    widget.onComplete(_pin);
  }
}
