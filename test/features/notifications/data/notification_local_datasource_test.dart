import 'dart:io';

import 'package:doki_do/core/security/encrypted_storage.dart';
import 'package:doki_do/features/notifications/data/notification_local_datasource.dart';
import 'package:doki_do/features/notifications/domain/app_notification_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  late Directory tempDirectory;
  late NotificationLocalDatasource datasource;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'doki_do_notification_test_',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: tempDirectory.path,
    );
    datasource = NotificationLocalDatasource(
      encryptedStorage: EncryptedStorage(keyStore: MemoryEncryptionKeyStore()),
    );
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('stores notifications encrypted and preserves read state', () async {
    final item = _notification('budget:period:category:80');

    expect(await datasource.upsert(item), isTrue);
    await datasource.markRead(item.id, DateTime(2026, 7, 2, 10));

    final items = await datasource.getAll();
    expect(items, hasLength(1));
    expect(items.single.isRead, isTrue);

    final raw = await File(
      '${tempDirectory.path}/doki_do_notifications.json',
    ).readAsString();
    expect(raw, contains('"format":"dokido-aes-gcm"'));
    expect(raw, isNot(contains(item.id)));
  });

  test('dismissed generated notification does not reappear', () async {
    final item = _notification('period:test:ending');
    await datasource.upsert(item);
    await datasource.delete(item.id);

    expect(await datasource.upsert(item), isFalse);
    expect(await datasource.getAll(), isEmpty);
  });

  test('upsert updates data without resetting read state', () async {
    final item = _notification('budget:period:category:80');
    await datasource.upsert(item);
    await datasource.markRead(item.id, DateTime(2026, 7, 2, 10));
    await datasource.upsert(
      AppNotificationItem(
        id: item.id,
        category: item.category,
        createdAt: DateTime(2026, 7, 3),
        data: const {'usage_percent': 94},
      ),
    );

    final stored = (await datasource.getAll()).single;
    expect(stored.data['usage_percent'], 94);
    expect(stored.isRead, isTrue);
    expect(stored.createdAt, item.createdAt);
  });
}

AppNotificationItem _notification(String id) {
  return AppNotificationItem(
    id: id,
    category: AppNotificationCategory.budget,
    createdAt: DateTime(2026, 7, 2, 9),
    data: const {
      'period_id': 'period',
      'category_id': 'category',
      'category_name': 'Kebutuhan Harian',
      'usage_percent': 82,
    },
  );
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform({required this.documentsPath});

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
