import 'dart:convert';
import 'dart:io';

import 'package:doki_do/core/security/encrypted_storage.dart';
import 'package:doki_do/core/storage/atomic_file_writer.dart';
import 'package:doki_do/core/storage/resilient_encrypted_file_store.dart';
import 'package:doki_do/features/finance/data/datasources/finance_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync(
      'doki_do_finance_source_test_',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: tempDirectory.path,
    );
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('migrates the old default daily-needs category name', () async {
    final file = File('${tempDirectory.path}/doki_do_finance.json');
    await file.writeAsString(
      jsonEncode({
        'current_period_id': 'period-1',
        'periods': [
          {
            'period_id': 'period-1',
            'start_date': '2026-07-01T00:00:00.000',
            'end_date': '2026-07-31T23:59:59.000',
            'total_income': 0,
            'total_allocatable': 0,
            'allocations_follow_income': false,
            'categories': [
              {
                'category_id': 'category-1',
                'category_name': 'Kebutuhan Pokok',
                'base_allocated_amount': 0,
                'allocated_amount': 0,
                'remaining_amount': 0,
              },
            ],
            'transactions': [],
            'category_adjustments': [],
          },
        ],
        'transaction_templates': [
          {
            'transaction_template_id': 'template-1',
            'title': 'Belanja',
            'amount': 100000,
            'type': 'expense',
            'preferred_category_name': 'Kebutuhan Pokok',
            'day_of_month': null,
            'created_at': '2026-07-01T00:00:00.000',
          },
        ],
      }),
    );

    final encryption = EncryptedStorage(keyStore: MemoryEncryptionKeyStore());
    final datasource = FinanceLocalDatasource(encryptedStorage: encryption);
    final periods = await datasource.getBudgetPeriods();
    final templates = await datasource.getTransactionTemplates();

    final category =
        (periods.single['categories'] as List).single as Map<String, dynamic>;
    expect(category['category_name'], 'Kebutuhan Harian');
    expect(templates.single['preferred_category_name'], 'Kebutuhan Harian');

    final migratedFile = await file.readAsString();
    final envelope = jsonDecode(migratedFile) as Map<String, dynamic>;
    expect(envelope['format'], 'dokido-aes-gcm');
    expect(migratedFile, isNot(contains('Kebutuhan Harian')));
    expect(migratedFile, isNot(contains('100000')));
    final backupContent = await AtomicFileWriter.backupFor(file).readAsString();
    expect(backupContent, contains('"format":"dokido-aes-gcm"'));
    expect(backupContent, isNot(contains('100000')));
    final decrypted = await encryption.decrypt(migratedFile, scope: 'finance');
    final migratedJson =
        jsonDecode(decrypted.plaintext) as Map<String, dynamic>;
    expect(migratedJson['schema_version'], 1);
  });

  test(
    'does not overwrite encrypted data when the key is unavailable',
    () async {
      final file = File('${tempDirectory.path}/doki_do_finance.json');
      final writer = FinanceLocalDatasource(
        encryptedStorage: EncryptedStorage(
          keyStore: MemoryEncryptionKeyStore(),
        ),
      );
      await writer.getBudgetPeriods();
      final encryptedBeforeRead = await file.readAsString();

      final readerWithWrongKey = FinanceLocalDatasource(
        encryptedStorage: EncryptedStorage(
          keyStore: MemoryEncryptionKeyStore(),
        ),
      );

      await expectLater(
        readerWithWrongKey.getBudgetPeriods(),
        throwsA(isA<StorageRecoveryException>()),
      );
      expect(await file.readAsString(), encryptedBeforeRead);
    },
  );

  test('restores the last valid backup when the primary is corrupt', () async {
    final file = File('${tempDirectory.path}/doki_do_finance.json');
    final keyStore = MemoryEncryptionKeyStore();
    final encryption = EncryptedStorage(keyStore: keyStore);
    await FinanceLocalDatasource(
      encryptedStorage: encryption,
    ).getBudgetPeriods();
    await file.writeAsString('corrupt-primary');

    final periods = await FinanceLocalDatasource(
      encryptedStorage: EncryptedStorage(keyStore: keyStore),
    ).getBudgetPeriods();

    expect(periods, isEmpty);
    final restored = await file.readAsString();
    expect(restored, isNot('corrupt-primary'));
    final decrypted = await encryption.decrypt(restored, scope: 'finance');
    expect(jsonDecode(decrypted.plaintext), isA<Map<String, dynamic>>());
  });

  test(
    'restores backup when encrypted primary fails domain validation',
    () async {
      final file = File('${tempDirectory.path}/doki_do_finance.json');
      final keyStore = MemoryEncryptionKeyStore();
      final encryption = EncryptedStorage(keyStore: keyStore);
      await FinanceLocalDatasource(
        encryptedStorage: encryption,
      ).getBudgetPeriods();
      final invalidPrimary = await encryption.encrypt(
        jsonEncode({
          'schema_version': 1,
          'current_period_id': 'missing-period',
          'periods': [
            {'period_id': 'broken'},
          ],
          'transaction_templates': [],
        }),
        scope: 'finance',
      );
      await file.writeAsString(invalidPrimary);

      final periods = await FinanceLocalDatasource(
        encryptedStorage: EncryptedStorage(keyStore: keyStore),
      ).getBudgetPeriods();

      expect(periods, isEmpty);
    },
  );

  test(
    'does not erase files when the primary and backup are corrupt',
    () async {
      final file = File('${tempDirectory.path}/doki_do_finance.json');
      final backup = AtomicFileWriter.backupFor(file);
      await file.writeAsString('corrupt-primary');
      await backup.writeAsString('corrupt-backup');

      await expectLater(
        FinanceLocalDatasource(
          encryptedStorage: EncryptedStorage(
            keyStore: MemoryEncryptionKeyStore(),
          ),
        ).getBudgetPeriods(),
        throwsA(isA<StorageRecoveryException>()),
      );

      expect(await file.readAsString(), 'corrupt-primary');
      expect(await backup.readAsString(), 'corrupt-backup');
    },
  );
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform({required this.documentsPath});

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
