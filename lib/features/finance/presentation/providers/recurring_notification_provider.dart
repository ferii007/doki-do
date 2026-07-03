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

Future<void> syncRecurringNotifications(Ref ref) async {
  final service = ref.read(recurringNotificationServiceProvider);
  final settings = await ref.read(appSettingsProvider.future);
  final templates = await ref
      .read(financeRepositoryProvider)
      .getTransactionTemplates();
  await service.sync(templates: templates, language: settings.language);
}
