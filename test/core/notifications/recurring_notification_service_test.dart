import 'package:doki_do/core/notifications/recurring_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecurringNotificationPayload', () {
    test('parses a valid recurring notification payload', () {
      final payload = RecurringNotificationPayload.tryParse(
        'recurring:template-123:2026-07-05T00:00:00.000',
      );

      expect(payload, isNotNull);
      expect(payload!.templateId, 'template-123');
      expect(payload.dueDate, DateTime(2026, 7, 5));
      expect(payload.occurrenceKey, 'template-123_2026_07');
    });

    test('rejects malformed or unrelated payloads', () {
      expect(RecurringNotificationPayload.tryParse(null), isNull);
      expect(
        RecurringNotificationPayload.tryParse('income:template-123'),
        isNull,
      );
      expect(
        RecurringNotificationPayload.tryParse(
          'recurring:template-123:not-a-date',
        ),
        isNull,
      );
    });
  });

  group('InboxNotificationPayload', () {
    test('parses a valid inbox notification payload', () {
      final payload = InboxNotificationPayload.tryParse(
        'inbox:budget:period-1:category-1:80',
      );

      expect(payload, isNotNull);
      expect(payload!.notificationId, 'budget:period-1:category-1:80');
    });

    test('rejects an empty or unrelated payload', () {
      expect(InboxNotificationPayload.tryParse('inbox:'), isNull);
      expect(InboxNotificationPayload.tryParse('recurring:test'), isNull);
    });
  });
}
