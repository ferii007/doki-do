import '../../../core/localization/app_localizations.dart';
import '../../settings/domain/entities/app_currency.dart';
import '../domain/app_notification_item.dart';

class NotificationTextResolver {
  final AppLocalizations localizations;
  final AppCurrency currency;

  const NotificationTextResolver({
    required this.localizations,
    required this.currency,
  });

  String title(AppNotificationItem item) {
    return switch (item.category) {
      AppNotificationCategory.recurring => localizations.trf(
        'notification_recurring_title',
        {'title': item.data['title'] as String? ?? ''},
      ),
      AppNotificationCategory.budget => localizations.tr(
        (item.data['usage_percent'] as int? ?? 0) >= 100
            ? 'notification_budget_exceeded_title'
            : 'notification_budget_warning_title',
      ),
      AppNotificationCategory.backup => localizations.tr(
        'notification_backup_failed_title',
      ),
      AppNotificationCategory.period => localizations.tr(
        'notification_period_ending_title',
      ),
    };
  }

  String body(AppNotificationItem item) {
    return switch (item.category) {
      AppNotificationCategory.recurring => _recurringBody(item),
      AppNotificationCategory.budget => localizations.trf(
        (item.data['usage_percent'] as int? ?? 0) >= 100
            ? 'notification_budget_exceeded_body'
            : 'notification_budget_warning_body',
        {
          'category': item.data['category_name'] as String? ?? '',
          'percent': item.data['usage_percent'] as int? ?? 0,
        },
      ),
      AppNotificationCategory.backup => localizations.tr(
        'notification_backup_failed_body',
      ),
      AppNotificationCategory.period => _periodBody(item),
    };
  }

  String actionLabel(AppNotificationItem item) {
    return switch (item.category) {
      AppNotificationCategory.recurring => localizations.tr('record_now'),
      AppNotificationCategory.budget => localizations.tr('view_budget'),
      AppNotificationCategory.backup => localizations.tr('fix'),
      AppNotificationCategory.period => localizations.tr('view_period'),
    };
  }

  String _recurringBody(AppNotificationItem item) {
    final category = item.data['category_name'] as String?;
    final key = category == null || category.isEmpty
        ? 'notification_recurring_body'
        : 'notification_recurring_category_body';
    return localizations.trf(key, {
      'amount': currency.format(item.data['amount'] as int? ?? 0),
      'date': _date(
        DateTime.tryParse(item.data['due_date'] as String? ?? '') ??
            item.createdAt,
      ),
      'category': category ?? '',
    });
  }

  String _date(DateTime date) {
    return '${date.day} '
        '${localizations.tr('month_long_${date.month}')} ${date.year}';
  }

  String _periodBody(AppNotificationItem item) {
    final days = item.data['days_remaining'] as int? ?? 0;
    final start =
        DateTime.tryParse(item.data['start_date'] as String? ?? '') ??
        item.createdAt;
    final end =
        DateTime.tryParse(item.data['end_date'] as String? ?? '') ??
        item.createdAt;
    final key = days == 0
        ? 'notification_period_ending_today_body'
        : days == 1
        ? 'notification_period_ending_one_day_body'
        : 'notification_period_ending_many_days_body';
    return localizations.trf(key, {
      'period': '${_date(start)} - ${_date(end)}',
      'days': days,
    });
  }
}
