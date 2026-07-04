import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/security/encrypted_storage.dart';
import '../../../core/storage/async_write_queue.dart';
import '../../../core/storage/resilient_encrypted_file_store.dart';
import '../domain/app_notification_item.dart';

class NotificationLocalDatasource {
  static const _schemaVersion = 1;
  static const _storageFileName = 'doki_do_notifications.json';
  static const _encryptionScope = 'notifications';
  static const _maxNotifications = 200;
  static const _maxDismissedIds = 500;

  final ResilientEncryptedFileStore _fileStore;
  final _writeQueue = AsyncWriteQueue();
  Map<String, dynamic>? _database;

  NotificationLocalDatasource({EncryptedStorage? encryptedStorage})
    : _fileStore = ResilientEncryptedFileStore(
        encryptedStorage: encryptedStorage ?? EncryptedStorage.instance,
      );

  Future<List<AppNotificationItem>> getAll() async {
    final database = await _readDatabase();
    final items =
        (database['notifications'] as List)
            .cast<Map<String, dynamic>>()
            .map(AppNotificationItem.fromJson)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<Map<String, dynamic>> exportBackupData() async {
    final database = await _readDatabase();
    return jsonDecode(jsonEncode(database)) as Map<String, dynamic>;
  }

  Future<void> restoreBackupData(Map<String, dynamic> backupData) async {
    final copy = jsonDecode(jsonEncode(backupData)) as Map<String, dynamic>;
    _validateStoredJson(jsonEncode(copy));
    _database = copy;
    await _saveDatabase();
  }

  Future<bool> upsert(AppNotificationItem item) async {
    final database = await _readDatabase();
    final dismissedIds = (database['dismissed_ids'] as List).cast<String>();
    if (dismissedIds.contains(item.id)) return false;

    final notifications = (database['notifications'] as List)
        .cast<Map<String, dynamic>>();
    final index = notifications.indexWhere(
      (record) => record['notification_id'] == item.id,
    );
    if (index >= 0) {
      final existing = AppNotificationItem.fromJson(notifications[index]);
      notifications[index] = AppNotificationItem(
        id: existing.id,
        category: item.category,
        data: item.data,
        createdAt: existing.createdAt,
        readAt: existing.readAt,
      ).toJson();
      await _saveDatabase();
      return false;
    }

    notifications.add(item.toJson());
    notifications.sort((a, b) {
      return (b['created_at'] as String).compareTo(a['created_at'] as String);
    });
    if (notifications.length > _maxNotifications) {
      notifications.removeRange(_maxNotifications, notifications.length);
    }
    await _saveDatabase();
    return true;
  }

  Future<void> markRead(String id, DateTime readAt) async {
    final database = await _readDatabase();
    final notifications = (database['notifications'] as List)
        .cast<Map<String, dynamic>>();
    final index = notifications.indexWhere(
      (record) => record['notification_id'] == id,
    );
    if (index < 0 || notifications[index]['read_at'] != null) return;
    notifications[index]['read_at'] = readAt.toIso8601String();
    await _saveDatabase();
  }

  Future<void> markAllRead(DateTime readAt) async {
    final database = await _readDatabase();
    var changed = false;
    for (final notification
        in (database['notifications'] as List).cast<Map<String, dynamic>>()) {
      if (notification['read_at'] == null) {
        notification['read_at'] = readAt.toIso8601String();
        changed = true;
      }
    }
    if (changed) await _saveDatabase();
  }

  Future<void> delete(String id) async {
    final database = await _readDatabase();
    final notifications = (database['notifications'] as List)
        .cast<Map<String, dynamic>>();
    notifications.removeWhere(
      (notification) => notification['notification_id'] == id,
    );
    final dismissedIds = (database['dismissed_ids'] as List).cast<String>();
    if (!dismissedIds.contains(id)) dismissedIds.add(id);
    if (dismissedIds.length > _maxDismissedIds) {
      dismissedIds.removeRange(0, dismissedIds.length - _maxDismissedIds);
    }
    await _saveDatabase();
  }

  Future<Map<String, dynamic>> _readDatabase() async {
    if (_database != null) return _database!;
    final file = await _storageFile();
    final stored = await _fileStore.read(
      file,
      scope: _encryptionScope,
      validate: _validateStoredJson,
    );
    if (stored == null) {
      _database = _emptyDatabase();
      await _saveDatabase();
      return _database!;
    }
    _database = jsonDecode(stored.plaintext) as Map<String, dynamic>;
    return _database!;
  }

  void _validateStoredJson(String plaintext) {
    final decoded = jsonDecode(plaintext);
    if (decoded is! Map<String, dynamic> ||
        decoded['schema_version'] != _schemaVersion ||
        decoded['notifications'] is! List ||
        decoded['dismissed_ids'] is! List) {
      throw const FormatException('Notification storage is invalid.');
    }
    for (final item in (decoded['notifications'] as List)) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Notification record is invalid.');
      }
      AppNotificationItem.fromJson(item);
    }
    if (!(decoded['dismissed_ids'] as List).every((item) => item is String)) {
      throw const FormatException('Dismissed notification IDs are invalid.');
    }
  }

  Future<void> _saveDatabase() async {
    final database = _database ?? _emptyDatabase();
    _validateStoredJson(jsonEncode(database));
    final file = await _storageFile();
    await _writeQueue.run(
      () => _fileStore.write(
        file,
        const JsonEncoder.withIndent('  ').convert(database),
        scope: _encryptionScope,
      ),
    );
  }

  Future<File> _storageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_storageFileName');
  }

  Map<String, dynamic> _emptyDatabase() {
    return {
      'schema_version': _schemaVersion,
      'notifications': <Map<String, dynamic>>[],
      'dismissed_ids': <String>[],
    };
  }
}
