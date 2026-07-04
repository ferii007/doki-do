import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/settings_local_datasource.dart';
import '../../domain/entities/app_settings.dart';

final settingsLocalDatasourceProvider = Provider<SettingsLocalDatasource>((
  ref,
) {
  return SettingsLocalDatasource();
});

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
    );

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.read(settingsLocalDatasourceProvider).readSettings();
  }

  Future<void> save(AppSettings settings) async {
    state = AsyncData(settings);
    await ref.read(settingsLocalDatasourceProvider).saveSettings(settings);
  }

  Future<void> completeSetup(AppSettings settings) async {
    await save(settings.copyWith(hasCompletedSetup: true));
  }

  Future<void> toggleFinancialPrivacy() async {
    final settings = state.asData?.value;
    if (settings == null) return;
    await save(
      settings.copyWith(hideFinancialAmounts: !settings.hideFinancialAmounts),
    );
  }

  Future<void> dismissNotificationPermissionPrompt() async {
    final settings = state.asData?.value;
    if (settings == null || settings.notificationPermissionPromptDismissed) {
      return;
    }
    await save(settings.copyWith(notificationPermissionPromptDismissed: true));
  }
}
