import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/app_info/app_identity.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../finance/presentation/providers/current_budget_provider.dart';
import '../../../finance/presentation/providers/finance_repository_provider.dart';
import '../../../finance/presentation/providers/recurring_notification_provider.dart';
import '../../../finance/presentation/providers/selected_period_provider.dart';
import '../../../finance/presentation/providers/transaction_template_provider.dart';
import '../../../notifications/domain/app_notification_item.dart';
import '../../../notifications/presentation/notification_text_resolver.dart';
import '../../../notifications/presentation/providers/notification_inbox_provider.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../../data/backup_credential_store.dart';
import '../../data/backup_file_gateway.dart';
import '../../domain/backup_archive.dart';
import '../../domain/backup_archive_codec.dart';
import '../../domain/backup_service.dart';

final backupCredentialStoreProvider = Provider<BackupCredentialStore>((ref) {
  return const PlatformBackupCredentialStore();
});

final backupArchiveCodecProvider = Provider<BackupArchiveCodec>((ref) {
  return BackupArchiveCodec(
    credentialStore: ref.watch(backupCredentialStoreProvider),
  );
});

final backupFileGatewayProvider = Provider<BackupFileGateway>((ref) {
  return const PlatformBackupFileGateway();
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    financeDatasource: ref.watch(financeLocalDatasourceProvider),
    settingsDatasource: ref.watch(settingsLocalDatasourceProvider),
    notificationDatasource: ref.watch(notificationLocalDatasourceProvider),
    codec: ref.watch(backupArchiveCodecProvider),
    fileGateway: ref.watch(backupFileGatewayProvider),
  );
});

class BackupState {
  final bool hasPassword;
  final bool isRunning;

  const BackupState({required this.hasPassword, this.isRunning = false});

  BackupState copyWith({bool? hasPassword, bool? isRunning}) {
    return BackupState(
      hasPassword: hasPassword ?? this.hasPassword,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

final backupControllerProvider =
    AsyncNotifierProvider<BackupController, BackupState>(BackupController.new);

final automaticBackupBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(appSettingsProvider.future);
  await ref.watch(backupControllerProvider.future);
  await ref.read(backupControllerProvider.notifier).runAutoBackupIfDue();
});

class BackupController extends AsyncNotifier<BackupState> {
  bool _autoBackupRunning = false;

  @override
  Future<BackupState> build() async {
    return BackupState(
      hasPassword: await ref.read(backupServiceProvider).hasPassword(),
    );
  }

  Future<void> configurePassword(String password) async {
    await ref.read(backupServiceProvider).configurePassword(password);
    state = AsyncData(
      (state.asData?.value ?? const BackupState(hasPassword: false)).copyWith(
        hasPassword: true,
      ),
    );
  }

  Future<void> chooseDirectory() async {
    final directory = await ref.read(backupServiceProvider).chooseDirectory();
    if (directory == null) return;
    final settings = ref.read(appSettingsProvider).asData?.value;
    if (settings == null) return;
    await ref
        .read(appSettingsProvider.notifier)
        .save(
          settings.copyWith(
            backupFolderUri: directory.uri,
            backupFolderName: directory.name,
          ),
        );
  }

  Future<BackupArchive> backupNow() async {
    final currentState =
        state.asData?.value ?? const BackupState(hasPassword: false);
    state = AsyncData(currentState.copyWith(isRunning: true));
    try {
      final settings = _requireSettings();
      final folderUri = settings.backupFolderUri;
      if (folderUri == null || folderUri.isEmpty) {
        throw const BackupArchiveException('backup_folder_not_configured');
      }
      final archive = await ref
          .read(backupServiceProvider)
          .createBackup(folderUri);
      await ref
          .read(appSettingsProvider.notifier)
          .save(
            settings.copyWith(
              lastBackupAt: archive.createdAt.toIso8601String(),
            ),
          );
      return archive;
    } finally {
      state = AsyncData(currentState.copyWith(isRunning: false));
    }
  }

  Future<BackupFileContent?> chooseBackupFile() {
    return ref.read(backupServiceProvider).chooseBackupFile();
  }

  Future<BackupFileContent?> readLatestBackup() {
    final folderUri = _requireSettings().backupFolderUri;
    if (folderUri == null || folderUri.isEmpty) {
      throw const BackupArchiveException('backup_folder_not_configured');
    }
    return ref.read(backupServiceProvider).readLatestBackup(folderUri);
  }

  Future<BackupArchive> inspectBackup(BackupFileContent file, String password) {
    return ref.read(backupServiceProvider).inspectBackup(file, password);
  }

  Future<void> restoreBackup(BackupArchive archive) async {
    final currentState =
        state.asData?.value ?? const BackupState(hasPassword: false);
    state = AsyncData(currentState.copyWith(isRunning: true));
    try {
      await ref.read(backupServiceProvider).restoreBackup(archive);
      await ref.read(appSettingsProvider.notifier).reload();
      _invalidateFinance();
    } finally {
      state = AsyncData(currentState.copyWith(isRunning: false));
    }
  }

  Future<void> runAutoBackupIfDue() async {
    if (_autoBackupRunning) return;
    final settings = ref.read(appSettingsProvider).asData?.value;
    final backupState = state.asData?.value;
    if (settings == null ||
        backupState == null ||
        !backupState.hasPassword ||
        settings.backupFolderUri == null ||
        !settings.backupFrequency.isDue(
          now: DateTime.now(),
          lastBackupAt: settings.lastBackupDateTime,
        )) {
      return;
    }

    _autoBackupRunning = true;
    try {
      await backupNow();
    } on Object catch (error, stackTrace) {
      try {
        await _recordAutomaticBackupFailure(settings);
      } on Object catch (notificationError, notificationStackTrace) {
        await reportNotificationInboxError(
          notificationError,
          notificationStackTrace,
        );
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: '${AppIdentity.appName} automatic backup',
        ),
      );
    } finally {
      _autoBackupRunning = false;
    }
  }

  Future<void> _recordAutomaticBackupFailure(AppSettings settings) async {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final item = AppNotificationItem(
      id: 'backup-failed:${now.year}-$month-$day',
      category: AppNotificationCategory.backup,
      createdAt: now,
      data: {'folder_name': settings.backupFolderName},
    );
    final created = await ref
        .read(notificationInboxProvider.notifier)
        .add(item);
    if (!created) return;

    final resolver = NotificationTextResolver(
      localizations: AppLocalizations(settings.language),
      currency: settings.currency,
    );
    await ref
        .read(recurringNotificationServiceProvider)
        .showInboxNotification(
          notificationId: item.id,
          title: settings.appLockEnabled
              ? AppLocalizations(
                  settings.language,
                ).tr('private_notification_title')
              : resolver.title(item),
          body: settings.appLockEnabled
              ? AppLocalizations(
                  settings.language,
                ).tr('private_notification_body')
              : resolver.body(item),
          language: settings.language,
        );
  }

  AppSettings _requireSettings() {
    final settings = ref.read(appSettingsProvider).asData?.value;
    if (settings == null) {
      throw const BackupArchiveException('backup_settings_unavailable');
    }
    return settings;
  }

  void _invalidateFinance() {
    ref.read(selectedPeriodIdProvider.notifier).select(null);
    ref.invalidate(budgetPeriodsProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(allBudgetSnapshotsProvider);
    ref.invalidate(transactionTemplatesProvider);
    ref.invalidate(recurringOccurrencesProvider);
    ref.invalidate(recurringDueItemsProvider);
    ref.invalidate(recurringNotificationBootstrapProvider);
    ref.invalidate(notificationInboxProvider);
    ref.invalidate(notificationInboxBootstrapProvider);
  }
}
