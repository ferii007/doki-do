import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/recurring_notification_service.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import 'finance_repository_provider.dart';

final recurringNotificationServiceProvider =
    Provider<RecurringNotificationService>((ref) {
      return RecurringNotificationService();
    });

final recurringNotificationBootstrapProvider = FutureProvider<void>((ref) {
  return syncRecurringNotifications(ref);
});

final recurringNotificationPayloadProvider =
    StreamProvider<RecurringNotificationPayload>((ref) async* {
      final service = ref.watch(recurringNotificationServiceProvider);
      await service.initialize();
      final pending = service.takePendingPayload();
      if (pending != null) yield pending;
      yield* service.payloads;
    });

Future<void> syncRecurringNotifications(Ref ref) async {
  final service = ref.read(recurringNotificationServiceProvider);
  final settings = await ref.read(appSettingsProvider.future);
  final repository = ref.read(financeRepositoryProvider);
  final templates = await repository.getTransactionTemplates();
  final occurrences = await repository.getRecurringOccurrences();
  await service.sync(
    templates: templates,
    occurrences: occurrences,
    language: settings.language,
    hideTransactionDetails: settings.appLockEnabled,
  );
}
