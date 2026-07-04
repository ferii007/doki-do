import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../finance/domain/entities/budget_snapshot.dart';
import '../../../finance/domain/entities/recurring_due_item.dart';
import '../../../finance/domain/entities/transaction_type.dart';
import '../../../finance/presentation/providers/current_budget_provider.dart';
import '../../../finance/presentation/providers/recurring_notification_provider.dart';
import '../../../finance/presentation/providers/transaction_template_provider.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../../data/notification_local_datasource.dart';
import '../../domain/app_notification_item.dart';
import '../notification_text_resolver.dart';

final notificationLocalDatasourceProvider =
    Provider<NotificationLocalDatasource>((ref) {
      return NotificationLocalDatasource();
    });

final notificationInboxProvider =
    AsyncNotifierProvider<NotificationInboxNotifier, List<AppNotificationItem>>(
      NotificationInboxNotifier.new,
    );

final unreadNotificationCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationInboxProvider).asData?.value ?? const [];
  return items.where((item) => !item.isRead).length;
});

final notificationInboxBootstrapProvider = FutureProvider<void>((ref) async {
  final snapshot = await ref.watch(currentBudgetProvider.future);
  final dueItems = await ref.watch(recurringDueItemsProvider.future);
  final created = await ref
      .read(notificationInboxProvider.notifier)
      .synchronize(snapshot: snapshot, dueItems: dueItems);
  if (created.isEmpty) return;

  final settings = await ref.watch(appSettingsProvider.future);
  final resolver = NotificationTextResolver(
    localizations: AppLocalizations(settings.language),
    currency: settings.currency,
  );
  final notificationService = ref.read(recurringNotificationServiceProvider);
  for (final item in created) {
    if (item.category == AppNotificationCategory.recurring) continue;
    try {
      await notificationService.showInboxNotification(
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
    } on Object catch (error, stackTrace) {
      await reportNotificationInboxError(error, stackTrace);
    }
  }
});

class NotificationInboxNotifier
    extends AsyncNotifier<List<AppNotificationItem>> {
  @override
  Future<List<AppNotificationItem>> build() {
    return ref.read(notificationLocalDatasourceProvider).getAll();
  }

  Future<List<AppNotificationItem>> synchronize({
    required BudgetSnapshot? snapshot,
    required List<RecurringDueItem> dueItems,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final generated = <AppNotificationItem>[
      for (final dueItem in dueItems) _fromRecurring(dueItem),
      if (snapshot != null) ..._fromBudget(snapshot, current),
      if (snapshot != null) ..._fromPeriod(snapshot, current),
    ];
    final created = <AppNotificationItem>[];
    final datasource = ref.read(notificationLocalDatasourceProvider);
    for (final item in generated) {
      if (await datasource.upsert(item)) created.add(item);
    }
    state = AsyncData(await datasource.getAll());
    return created;
  }

  Future<bool> add(AppNotificationItem item) async {
    final datasource = ref.read(notificationLocalDatasourceProvider);
    final created = await datasource.upsert(item);
    state = AsyncData(await datasource.getAll());
    return created;
  }

  Future<void> markRead(String id) async {
    final datasource = ref.read(notificationLocalDatasourceProvider);
    await datasource.markRead(id, DateTime.now());
    state = AsyncData(await datasource.getAll());
  }

  Future<void> markAllRead() async {
    final datasource = ref.read(notificationLocalDatasourceProvider);
    await datasource.markAllRead(DateTime.now());
    state = AsyncData(await datasource.getAll());
  }

  Future<void> delete(String id) async {
    final datasource = ref.read(notificationLocalDatasourceProvider);
    await datasource.delete(id);
    state = AsyncData(await datasource.getAll());
  }

  AppNotificationItem _fromRecurring(RecurringDueItem item) {
    final month = item.dueDate.month.toString().padLeft(2, '0');
    return AppNotificationItem(
      id: 'recurring:${item.template.id}:${item.dueDate.year}-$month',
      category: AppNotificationCategory.recurring,
      createdAt: DateTime(
        item.dueDate.year,
        item.dueDate.month,
        item.dueDate.day,
        item.template.reminderHour,
        item.template.reminderMinute,
      ),
      data: {
        'template_id': item.template.id,
        'title': item.template.title,
        'amount': item.template.amount,
        'transaction_type': item.template.type == TransactionType.income
            ? 'income'
            : 'expense',
        'category_name': item.template.preferredCategoryName,
        'due_date': item.dueDate.toIso8601String(),
        'is_overdue': item.isOverdue,
      },
    );
  }

  Iterable<AppNotificationItem> _fromBudget(
    BudgetSnapshot snapshot,
    DateTime now,
  ) sync* {
    for (final category in snapshot.categories) {
      if (category.allocatedAmount <= 0) continue;
      final spent = category.allocatedAmount - category.remainingAmount;
      final usage = ((spent / category.allocatedAmount) * 100).round();
      if (usage < 80) continue;
      final threshold = usage >= 100 ? 100 : 80;
      yield AppNotificationItem(
        id:
            'budget:${snapshot.period.id}:${category.id}:'
            '$threshold',
        category: AppNotificationCategory.budget,
        createdAt: now,
        data: {
          'period_id': snapshot.period.id,
          'category_id': category.id,
          'category_name': category.name,
          'usage_percent': usage,
        },
      );
    }
  }

  Iterable<AppNotificationItem> _fromPeriod(
    BudgetSnapshot snapshot,
    DateTime now,
  ) sync* {
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
      snapshot.period.endDate.year,
      snapshot.period.endDate.month,
      snapshot.period.endDate.day,
    );
    final days = end.difference(today).inDays;
    if (days < 0 || days > 3) return;
    yield AppNotificationItem(
      id: 'period:${snapshot.period.id}:ending',
      category: AppNotificationCategory.period,
      createdAt: now,
      data: {
        'period_id': snapshot.period.id,
        'start_date': snapshot.period.startDate.toIso8601String(),
        'end_date': snapshot.period.endDate.toIso8601String(),
        'days_remaining': days,
      },
    );
  }
}

Future<void> reportNotificationInboxError(
  Object error,
  StackTrace stackTrace,
) async {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'DokiDo notification inbox',
    ),
  );
}
