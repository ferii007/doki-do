enum AppNotificationCategory {
  recurring('recurring'),
  budget('budget'),
  backup('backup'),
  period('period');

  final String code;

  const AppNotificationCategory(this.code);

  static AppNotificationCategory byCode(String code) {
    return values.firstWhere(
      (category) => category.code == code,
      orElse: () => AppNotificationCategory.period,
    );
  }
}

class AppNotificationItem {
  final String id;
  final AppNotificationCategory category;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotificationItem({
    required this.id,
    required this.category,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  AppNotificationItem copyWith({Map<String, dynamic>? data, DateTime? readAt}) {
    return AppNotificationItem(
      id: id,
      category: category,
      data: data ?? this.data,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': id,
      'category': category.code,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final id = json['notification_id'];
    final category = json['category'];
    final data = json['data'];
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    final readAtValue = json['read_at'] as String?;
    final readAt = readAtValue == null ? null : DateTime.tryParse(readAtValue);
    if (id is! String ||
        id.isEmpty ||
        category is! String ||
        data is! Map<String, dynamic> ||
        createdAt == null ||
        (readAtValue != null && readAt == null)) {
      throw const FormatException('Notification record is invalid.');
    }
    return AppNotificationItem(
      id: id,
      category: AppNotificationCategory.byCode(category),
      data: data,
      createdAt: createdAt,
      readAt: readAt,
    );
  }
}
