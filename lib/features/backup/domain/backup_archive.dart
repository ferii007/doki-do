class BackupArchive {
  static const format = 'dokido-backup';
  static const version = 1;

  final DateTime createdAt;
  final Map<String, dynamic> finance;
  final Map<String, dynamic> settings;

  const BackupArchive({
    required this.createdAt,
    required this.finance,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'version': version,
      'created_at': createdAt.toUtc().toIso8601String(),
      'finance': finance,
      'settings': settings,
    };
  }

  factory BackupArchive.fromJson(Map<String, dynamic> json) {
    if (json['format'] != format || json['version'] != version) {
      throw const FormatException('Unsupported DokiDo backup format.');
    }
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    final finance = json['finance'];
    final settings = json['settings'];
    if (createdAt == null ||
        finance is! Map<String, dynamic> ||
        settings is! Map<String, dynamic>) {
      throw const FormatException('DokiDo backup content is incomplete.');
    }
    return BackupArchive(
      createdAt: createdAt.toLocal(),
      finance: finance,
      settings: settings,
    );
  }

  int get periodCount => (finance['periods'] as List? ?? const []).length;

  int get transactionCount {
    final periods = (finance['periods'] as List? ?? const []);
    return periods.whereType<Map<String, dynamic>>().fold(
      0,
      (count, period) =>
          count + (period['transactions'] as List? ?? const []).length,
    );
  }

  int get categoryCount {
    final periods = (finance['periods'] as List? ?? const []);
    return periods.whereType<Map<String, dynamic>>().fold(
      0,
      (count, period) =>
          count + (period['categories'] as List? ?? const []).length,
    );
  }
}
