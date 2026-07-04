import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../providers/app_lock_provider.dart';
import '../screens/app_lock_screen.dart';

class AppLockGate extends ConsumerWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).asData?.value;
    final session = ref.watch(appLockSessionProvider);
    if (settings == null) return child;
    final appLockEnabled = settings.appLockEnabled;

    if (!session.initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(appLockSessionProvider.notifier)
            .initialize(enabled: appLockEnabled);
      });
    } else if (session.enabled != appLockEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(appLockSessionProvider.notifier)
            .configureEnabled(enabled: appLockEnabled);
      });
    }

    final shouldObscure = appLockEnabled && session.obscured;
    final shouldLock =
        appLockEnabled && (!session.initialized || session.locked);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (shouldObscure) const _AppPrivacyCover(),
        if (shouldLock)
          AppLockScreen(biometricEnabled: settings.biometricUnlockEnabled),
      ],
    );
  }
}

class _AppPrivacyCover extends StatelessWidget {
  const _AppPrivacyCover();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Image.asset(
          'assets/images/dokido_logo.png',
          width: 150,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
