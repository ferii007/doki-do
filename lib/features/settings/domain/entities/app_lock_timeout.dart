enum AppLockTimeout {
  immediately(
    code: 'immediately',
    labelKey: 'lock_immediately',
    duration: Duration.zero,
  ),
  afterOneMinute(
    code: 'after_1_minute',
    labelKey: 'lock_after_1_minute',
    duration: Duration(minutes: 1),
  ),
  afterThirtyMinutes(
    code: 'after_30_minutes',
    labelKey: 'lock_after_30_minutes',
    duration: Duration(minutes: 30),
  );

  final String code;
  final String labelKey;
  final Duration duration;

  const AppLockTimeout({
    required this.code,
    required this.labelKey,
    required this.duration,
  });

  static AppLockTimeout byCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => AppLockTimeout.immediately,
    );
  }
}
