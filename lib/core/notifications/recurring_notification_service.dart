import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/finance/domain/entities/transaction_template.dart';
import '../../features/finance/domain/services/monthly_recurrence_calculator.dart';
import '../../features/settings/domain/entities/app_language.dart';
import '../localization/app_localizations.dart';

class RecurringNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  RecurringNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);

    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return false;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? true;
  }

  Future<void> sync({
    required List<TransactionTemplate> templates,
    required AppLanguage language,
    DateTime? now,
  }) async {
    await initialize();
    if (kIsWeb) return;

    await _plugin.cancelAllPendingNotifications();
    final current = now ?? DateTime.now();
    final localizations = AppLocalizations(language);
    final candidates = <_ScheduledRecurringNotification>[];

    for (final template in templates) {
      if (!template.isRecurring ||
          !template.isActive ||
          !template.reminderEnabled) {
        continue;
      }
      candidates.addAll(_notificationCandidates(template, current));
    }

    candidates.sort((a, b) => a.scheduled.compareTo(b.scheduled));
    for (final candidate in candidates.take(48)) {
      await _plugin.zonedSchedule(
        _notificationId(candidate.template.id, candidate.dueDate),
        localizations.tr('recurring_notification_title'),
        localizations.trf('recurring_notification_body', {
          'title': candidate.template.title,
        }),
        tz.TZDateTime.from(candidate.scheduled, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'recurring_transactions',
            localizations.tr('recurring_notification_channel'),
            channelDescription: localizations.tr(
              'recurring_notification_channel_description',
            ),
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload:
            'recurring:${candidate.template.id}:'
            '${candidate.dueDate.toIso8601String()}',
      );
    }
  }

  List<_ScheduledRecurringNotification> _notificationCandidates(
    TransactionTemplate template,
    DateTime now,
  ) {
    final preferredDay = template.dayOfMonth;
    if (preferredDay == null) return const [];

    final candidates = <_ScheduledRecurringNotification>[];
    var month = DateTime(now.year, now.month);
    for (var index = 0; index < 24; index++) {
      final dueDate = MonthlyRecurrenceCalculator.dueDateForMonth(
        year: month.year,
        month: month.month,
        preferredDay: preferredDay,
      );
      final scheduled = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        template.reminderHour,
        template.reminderMinute,
      );
      final withinActiveRange =
          !dueDate.isBefore(_dateOnly(template.activeFromDate)) &&
          (template.endDate == null ||
              !dueDate.isAfter(_dateOnly(template.endDate!)));

      if (withinActiveRange && scheduled.isAfter(now)) {
        candidates.add(
          _ScheduledRecurringNotification(
            template: template,
            dueDate: dueDate,
            scheduled: scheduled,
          ),
        );
      }

      if (template.endDate != null &&
          month.isAfter(
            DateTime(template.endDate!.year, template.endDate!.month),
          )) {
        break;
      }
      month = DateTime(month.year, month.month + 1);
    }
    return candidates;
  }

  int _notificationId(String templateId, DateTime dueDate) {
    final value = '$templateId:${dueDate.year}:${dueDate.month}';
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _ScheduledRecurringNotification {
  final TransactionTemplate template;
  final DateTime dueDate;
  final DateTime scheduled;

  const _ScheduledRecurringNotification({
    required this.template,
    required this.dueDate,
    required this.scheduled,
  });
}
