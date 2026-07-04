import 'dart:io';

import 'package:doki_do/core/security/encrypted_storage.dart';
import 'package:doki_do/features/finance/domain/entities/budget_period.dart';
import 'package:doki_do/features/finance/domain/entities/budget_snapshot.dart';
import 'package:doki_do/features/finance/domain/entities/category_budget.dart';
import 'package:doki_do/features/finance/domain/entities/recurring_due_item.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_template.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_type.dart';
import 'package:doki_do/features/notifications/data/notification_local_datasource.dart';
import 'package:doki_do/features/notifications/domain/app_notification_item.dart';
import 'package:doki_do/features/notifications/presentation/providers/notification_inbox_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  late Directory tempDirectory;
  late ProviderContainer container;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'doki_do_notification_provider_test_',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: tempDirectory.path,
    );
    final datasource = NotificationLocalDatasource(
      encryptedStorage: EncryptedStorage(keyStore: MemoryEncryptionKeyStore()),
    );
    container = ProviderContainer(
      overrides: [
        notificationLocalDatasourceProvider.overrideWithValue(datasource),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test(
    'generates recurring, budget, and ending-period notifications',
    () async {
      await container.read(notificationInboxProvider.future);
      final notifier = container.read(notificationInboxProvider.notifier);
      final now = DateTime(2026, 7, 28, 10);
      final snapshot = BudgetSnapshot(
        period: BudgetPeriod(
          id: 'period-1',
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
          totalIncome: 1000000,
          totalAllocatable: 180000,
          allocationsFollowIncome: false,
        ),
        categories: const [
          CategoryBudget(
            id: 'category-1',
            name: 'Kebutuhan Harian',
            allocatedAmount: 1000000,
            remainingAmount: 180000,
          ),
        ],
        transactions: const [],
        categoryAdjustments: const [],
      );
      final dueItem = RecurringDueItem(
        template: TransactionTemplate(
          id: 'template-1',
          title: 'Internet Rumah',
          amount: 300000,
          type: TransactionType.expense,
          createdAt: DateTime(2026, 1, 1),
          activeFromDate: DateTime(2026, 1, 1),
          isActive: true,
          reminderEnabled: true,
          reminderHour: 9,
          reminderMinute: 0,
          dayOfMonth: 28,
          preferredCategoryName: 'Kebutuhan Harian',
        ),
        dueDate: DateTime(2026, 7, 28),
        isOverdue: false,
      );

      final firstCreated = await notifier.synchronize(
        snapshot: snapshot,
        dueItems: [dueItem],
        now: now,
      );
      final secondCreated = await notifier.synchronize(
        snapshot: snapshot,
        dueItems: [dueItem],
        now: now,
      );
      final items = container.read(notificationInboxProvider).requireValue;

      expect(firstCreated, hasLength(3));
      expect(secondCreated, isEmpty);
      expect(items.map((item) => item.category).toSet(), {
        AppNotificationCategory.recurring,
        AppNotificationCategory.budget,
        AppNotificationCategory.period,
      });
    },
  );
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform({required this.documentsPath});

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
