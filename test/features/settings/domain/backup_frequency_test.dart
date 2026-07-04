import 'package:doki_do/features/settings/domain/entities/backup_frequency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily backup is due after one day', () {
    expect(
      BackupFrequency.daily.isDue(
        now: DateTime(2026, 7, 2, 10),
        lastBackupAt: DateTime(2026, 7, 1, 10),
      ),
      isTrue,
    );
  });

  test('monthly backup follows calendar month instead of thirty days', () {
    expect(
      BackupFrequency.monthly.isDue(
        now: DateTime(2026, 8, 1),
        lastBackupAt: DateTime(2026, 7, 31),
      ),
      isTrue,
    );
  });

  test('disabled backup is never due', () {
    expect(BackupFrequency.off.isDue(now: DateTime(2026, 7, 2)), isFalse);
  });
}
