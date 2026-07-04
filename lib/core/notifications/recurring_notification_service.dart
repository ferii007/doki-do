import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/finance/domain/entities/recurring_occurrence.dart';
import '../../features/finance/domain/entities/transaction_template.dart';
import '../../features/finance/domain/services/recurring_notification_planner.dart';
import '../../features/settings/domain/entities/app_language.dart';
import '../localization/app_localizations.dart';

class RecurringNotificationService {
  static const _settingsChannel = MethodChannel(
    'com.dokido.finance/notification_settings',
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final _payloadController =
      StreamController<RecurringNotificationPayload>.broadcast();
  bool _initialized = false;
  bool _launchPayloadRead = false;
  Future<void>? _initialization;
  RecurringNotificationPayload? _pendingPayload;

  RecurringNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    final inProgress = _initialization;
    if (inProgress != null) {
      await inProgress;
      return;
    }

    final initialization = _initialize();
    _initialization = initialization;
    try {
      await initialization;
    } finally {
      _initialization = null;
    }
  }

  Future<void> _initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _publishPayload(response.payload);
      },
    );

    tz_data.initializeTimeZones();
    await _publishLaunchPayload();
    _initialized = true;
  }

  Future<void> _refreshLocalTimezone() async {
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
  }

  Future<void> _publishLaunchPayload() async {
    if (_launchPayloadRead) return;
    _launchPayloadRead = true;
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _publishPayload(launchDetails?.notificationResponse?.payload);
    }
  }

  Stream<RecurringNotificationPayload> get payloads =>
      _payloadController.stream;

  RecurringNotificationPayload? takePendingPayload() {
    final payload = _pendingPayload;
    _pendingPayload = null;
    return payload;
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

  Future<bool> areNotificationsEnabled() async {
    await initialize();
    if (kIsWeb) return false;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return (await ios.checkPermissions())?.isEnabled ?? false;
    }
    return true;
  }

  Future<bool> openNotificationSettings() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await requestPermission();
      if (granted) return true;
    }
    try {
      await _settingsChannel.invokeMethod<void>('openNotificationSettings');
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> sync({
    required List<TransactionTemplate> templates,
    required List<RecurringOccurrence> occurrences,
    required AppLanguage language,
    DateTime? now,
  }) async {
    await initialize();
    if (kIsWeb) return;

    await _refreshLocalTimezone();
    await _plugin.cancelAllPendingNotifications();
    final current = now ?? DateTime.now();
    final localizations = AppLocalizations(language);
    final schedules = RecurringNotificationPlanner.build(
      templates: templates,
      occurrences: occurrences,
      now: current,
    );
    for (final schedule in schedules) {
      await _plugin.zonedSchedule(
        _notificationId(schedule.template.id, schedule.dueDate),
        localizations.tr('recurring_notification_title'),
        localizations.trf('recurring_notification_body', {
          'title': schedule.template.title,
        }),
        tz.TZDateTime.from(schedule.scheduledAt, tz.local),
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
            'recurring:${schedule.template.id}:'
            '${schedule.dueDate.toIso8601String()}',
      );
    }
  }

  Future<void> cancelOccurrence({
    required String templateId,
    required DateTime dueDate,
  }) async {
    await initialize();
    if (kIsWeb) return;
    await _plugin.cancel(_notificationId(templateId, dueDate));
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

  void _publishPayload(String? rawPayload) {
    final payload = RecurringNotificationPayload.tryParse(rawPayload);
    if (payload == null) return;
    if (_payloadController.hasListener) {
      _payloadController.add(payload);
    } else {
      _pendingPayload = payload;
    }
  }
}

class RecurringNotificationPayload {
  final String templateId;
  final DateTime dueDate;

  const RecurringNotificationPayload({
    required this.templateId,
    required this.dueDate,
  });

  String get occurrenceKey {
    final month = dueDate.month.toString().padLeft(2, '0');
    return '${templateId}_${dueDate.year}_$month';
  }

  static RecurringNotificationPayload? tryParse(String? rawPayload) {
    const prefix = 'recurring:';
    if (rawPayload == null || !rawPayload.startsWith(prefix)) return null;

    final value = rawPayload.substring(prefix.length);
    final separator = value.indexOf(':');
    if (separator <= 0 || separator == value.length - 1) return null;
    final dueDate = DateTime.tryParse(value.substring(separator + 1));
    if (dueDate == null) return null;

    return RecurringNotificationPayload(
      templateId: value.substring(0, separator),
      dueDate: dueDate,
    );
  }
}
