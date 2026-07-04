import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../finance/presentation/providers/recurring_notification_provider.dart';
import '../../../settings/domain/entities/app_lock_timeout.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../../domain/services/device_authentication_service.dart';
import '../providers/app_lock_provider.dart';
import 'app_lock_pin_setup_screen.dart';
import 'app_lock_pin_verification_screen.dart';

class AppLockSettingsScreen extends ConsumerWidget {
  const AppLockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('app_lock'))),
      body: settings == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SecurityStatusCard(settings: settings),
                const SizedBox(height: 14),
                if (!settings.appLockEnabled)
                  _DisabledAppLockCard(onEnable: () => _enable(context, ref))
                else ...[
                  _SecuritySettingsCard(
                    children: [
                      _SecurityOption(
                        icon: Icons.fingerprint_rounded,
                        title: context.tr('biometric_unlock'),
                        subtitle: context.tr(
                          settings.biometricUnlockEnabled
                              ? 'biometric_unlock_enabled'
                              : 'biometric_unlock_disabled',
                        ),
                        trailing: _ThemedSwitch(
                          enabled: settings.biometricUnlockEnabled,
                        ),
                        onTap: () => _toggleBiometric(context, ref, settings),
                      ),
                      _SecurityOption(
                        icon: Icons.timer_outlined,
                        title: context.tr('automatic_lock'),
                        subtitle: context.tr(settings.appLockTimeout.labelKey),
                        onTap: () => _chooseTimeout(context, ref, settings),
                      ),
                      _SecurityOption(
                        icon: Icons.password_rounded,
                        title: context.tr('change_pin'),
                        subtitle: context.tr('change_pin_description'),
                        onTap: () => _changePin(context, ref, settings),
                      ),
                      _SecurityOption(
                        icon: Icons.lock_clock_outlined,
                        title: context.tr('lock_now'),
                        subtitle: context.tr('lock_now_description'),
                        onTap: () {
                          Navigator.pop(context);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ref.read(appLockSessionProvider.notifier).lock();
                          });
                        },
                      ),
                      _SecurityOption(
                        icon: Icons.lock_open_rounded,
                        title: context.tr('disable_app_lock'),
                        subtitle: context.tr('disable_app_lock_description'),
                        color: AppColors.danger,
                        showDivider: false,
                        onTap: () => _disable(context, ref, settings),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const AppLockPinSetupScreen()),
    );
    if (pin == null || !context.mounted) return;

    await ref.read(appLockPinServiceProvider).setPin(pin);
    final current = ref.read(appSettingsProvider).asData?.value;
    if (current == null) return;
    await _saveSecuritySettings(
      ref,
      current.copyWith(
        appLockEnabled: true,
        biometricUnlockEnabled: false,
        appLockTimeoutCode: AppLockTimeout.immediately.code,
      ),
    );
    ref.read(appLockSessionProvider.notifier).configureEnabled(enabled: true);
    if (!context.mounted) return;

    AppToast.show(context, context.tr('app_lock_enabled_successfully'));
    final available = await ref
        .read(deviceAuthenticationServiceProvider)
        .hasEnrolledBiometrics();
    if (!available || !context.mounted) return;
    final useBiometric = await _showEnableBiometricSheet(context);
    if (useBiometric && context.mounted) {
      await _enableBiometric(context, ref);
    }
  }

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    if (!settings.biometricUnlockEnabled) {
      await _enableBiometric(context, ref);
      return;
    }

    if (!await _authenticateCurrent(context, ref, settings)) return;
    await _saveSecuritySettings(
      ref,
      settings.copyWith(biometricUnlockEnabled: false),
    );
    if (context.mounted) {
      AppToast.show(context, context.tr('biometric_unlock_disabled'));
    }
  }

  Future<void> _enableBiometric(BuildContext context, WidgetRef ref) async {
    final service = ref.read(deviceAuthenticationServiceProvider);
    final reason = context.tr('enable_biometric_reason');
    if (!await service.hasEnrolledBiometrics()) {
      if (context.mounted) {
        AppToast.show(context, context.tr('biometric_not_available'));
      }
      return;
    }

    final session = ref.read(appLockSessionProvider.notifier);
    session.beginAuthentication();
    final result = await service.authenticateBiometric(reason);
    session.endAuthentication();
    if (!context.mounted) return;
    if (result != DeviceAuthenticationResult.success) {
      if (result != DeviceAuthenticationResult.canceled) {
        AppToast.show(context, context.tr('authentication_failed'));
      }
      return;
    }

    final current = ref.read(appSettingsProvider).asData?.value;
    if (current == null) return;
    await _saveSecuritySettings(
      ref,
      current.copyWith(biometricUnlockEnabled: true),
    );
    if (context.mounted) {
      AppToast.show(context, context.tr('biometric_unlock_enabled'));
    }
  }

  Future<void> _changePin(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    if (!await _authenticateCurrent(context, ref, settings)) return;
    if (!context.mounted) return;
    final pin = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const AppLockPinSetupScreen(
          titleKey: 'create_new_app_lock_pin',
          descriptionKey: 'create_new_app_lock_pin_description',
        ),
      ),
    );
    if (pin == null || !context.mounted) return;
    await ref.read(appLockPinServiceProvider).setPin(pin);
    if (context.mounted) {
      AppToast.show(context, context.tr('pin_changed_successfully'));
    }
  }

  Future<void> _disable(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    if (!await _authenticateCurrent(context, ref, settings)) return;
    if (!context.mounted) return;
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: context.tr('disable_app_lock_confirmation'),
      message: context.tr('disable_app_lock_confirmation_description'),
      confirmLabel: 'disable',
      icon: Icons.lock_open_rounded,
    );
    if (!confirmed) return;

    await _saveSecuritySettings(
      ref,
      settings.copyWith(appLockEnabled: false, biometricUnlockEnabled: false),
    );
    ref.read(appLockSessionProvider.notifier).configureEnabled(enabled: false);
    await ref.read(appLockPinServiceProvider).clearPin();
    if (context.mounted) {
      AppToast.show(context, context.tr('app_lock_disabled_successfully'));
    }
  }

  Future<bool> _authenticateCurrent(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    if (settings.biometricUnlockEnabled) {
      final session = ref.read(appLockSessionProvider.notifier);
      session.beginAuthentication();
      final result = await ref
          .read(deviceAuthenticationServiceProvider)
          .authenticateBiometric(context.tr('verify_security_change_reason'));
      session.endAuthentication();
      if (result == DeviceAuthenticationResult.success) return true;
    }
    if (!context.mounted) return false;
    return await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => const AppLockPinVerificationScreen(),
          ),
        ) ??
        false;
  }

  Future<void> _chooseTimeout(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final selected = await showModalBottomSheet<AppLockTimeout>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimeoutSheet(selected: settings.appLockTimeout),
    );
    if (selected == null) return;
    await _saveSecuritySettings(
      ref,
      settings.copyWith(appLockTimeoutCode: selected.code),
    );
    if (context.mounted) {
      AppToast.show(context, context.tr('settings_updated_successfully'));
    }
  }

  Future<void> _saveSecuritySettings(
    WidgetRef ref,
    AppSettings settings,
  ) async {
    await ref.read(appSettingsProvider.notifier).save(settings);
    ref.invalidate(recurringNotificationBootstrapProvider);
  }

  Future<bool> _showEnableBiometricSheet(BuildContext context) async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => const _EnableBiometricSheet(),
        ) ??
        false;
  }
}

class _SecurityStatusCard extends StatelessWidget {
  final AppSettings settings;

  const _SecurityStatusCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final enabled = settings.appLockEnabled;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: enabled ? AppColors.mintSurface : AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: enabled ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: enabled ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(enabled ? 'app_lock_active' : 'app_lock_inactive'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(
                    enabled
                        ? 'app_lock_active_description'
                        : 'app_lock_inactive_description',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledAppLockCard extends StatelessWidget {
  final VoidCallback onEnable;

  const _DisabledAppLockCard({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return _SecuritySettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Text(
                context.tr('enable_app_lock_description'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onEnable,
                  icon: const Icon(Icons.lock_outline_rounded),
                  label: Text(context.tr('enable_app_lock')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecuritySettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SecuritySettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SecurityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? color;
  final VoidCallback onTap;
  final bool showDivider;

  const _SecurityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.color,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppColors.primary;
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: foreground, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color ?? AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _ThemedSwitch extends StatelessWidget {
  final bool enabled;

  const _ThemedSwitch({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 46,
      height: 27,
      padding: const EdgeInsets.all(3),
      alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: enabled ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Container(
        width: 21,
        height: 21,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TimeoutSheet extends StatelessWidget {
  final AppLockTimeout selected;

  const _TimeoutSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(
            title: context.tr('automatic_lock'),
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: 14),
          for (final timeout in AppLockTimeout.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TimeoutOption(
                timeout: timeout,
                selected: timeout == selected,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeoutOption extends StatelessWidget {
  final AppLockTimeout timeout;
  final bool selected;

  const _TimeoutOption({required this.timeout, required this.selected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      onTap: () => Navigator.pop(context, timeout),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintSurface : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr(timeout.labelKey),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnableBiometricSheet extends StatelessWidget {
  const _EnableBiometricSheet();

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSheetHandle(),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.mintSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('enable_biometric_unlock'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('enable_biometric_unlock_description'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('enable')),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('later')),
            ),
          ),
        ],
      ),
    );
  }
}
