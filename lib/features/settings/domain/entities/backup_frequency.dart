enum BackupFrequency {
  off('off', 'backup_frequency_off'),
  daily('daily', 'backup_frequency_daily'),
  weekly('weekly', 'backup_frequency_weekly'),
  monthly('monthly', 'backup_frequency_monthly');

  final String code;
  final String labelKey;

  const BackupFrequency(this.code, this.labelKey);

  static BackupFrequency byCode(String code) {
    return values.firstWhere(
      (frequency) => frequency.code == code,
      orElse: () => BackupFrequency.off,
    );
  }

  bool isDue({required DateTime now, DateTime? lastBackupAt}) {
    if (this == BackupFrequency.off) return false;
    if (lastBackupAt == null) return true;

    final elapsed = now.difference(lastBackupAt);
    return switch (this) {
      BackupFrequency.off => false,
      BackupFrequency.daily => elapsed >= const Duration(days: 1),
      BackupFrequency.weekly => elapsed >= const Duration(days: 7),
      BackupFrequency.monthly =>
        now.year > lastBackupAt.year ||
            (now.year == lastBackupAt.year && now.month > lastBackupAt.month),
    };
  }
}
