import 'transaction_type.dart';

class TransactionTemplate {
  final String id;
  final String title;
  final int amount;
  final TransactionType type;
  final String? preferredCategoryName;
  final int? dayOfMonth;
  final DateTime createdAt;
  final bool isActive;
  final DateTime activeFromDate;
  final DateTime? endDate;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  const TransactionTemplate({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
    required this.isActive,
    required this.activeFromDate,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    this.preferredCategoryName,
    this.dayOfMonth,
    this.endDate,
  });

  bool get isRecurring => dayOfMonth != null;

  factory TransactionTemplate.fromJson(Map<String, dynamic> json) {
    return TransactionTemplate(
      id: json['transaction_template_id'] as String,
      title: json['title'] as String,
      amount: json['amount'] as int,
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      preferredCategoryName: json['preferred_category_name'] as String?,
      dayOfMonth: json['day_of_month'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      activeFromDate: DateTime.parse(
        json['active_from_date'] as String? ?? json['created_at'] as String,
      ),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      reminderEnabled: json['reminder_enabled'] as bool? ?? true,
      reminderHour: json['reminder_hour'] as int? ?? 9,
      reminderMinute: json['reminder_minute'] as int? ?? 0,
    );
  }

  TransactionTemplate copyWith({
    String? title,
    int? amount,
    String? preferredCategoryName,
    int? dayOfMonth,
    bool? isActive,
    DateTime? activeFromDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return TransactionTemplate(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type,
      createdAt: createdAt,
      preferredCategoryName:
          preferredCategoryName ?? this.preferredCategoryName,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isActive: isActive ?? this.isActive,
      activeFromDate: activeFromDate ?? this.activeFromDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}
