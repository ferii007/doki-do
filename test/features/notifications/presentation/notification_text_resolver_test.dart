import 'package:doki_do/core/localization/app_localizations.dart';
import 'package:doki_do/features/notifications/domain/app_notification_item.dart';
import 'package:doki_do/features/notifications/presentation/notification_text_resolver.dart';
import 'package:doki_do/features/settings/domain/entities/app_currency.dart';
import 'package:doki_do/features/settings/domain/entities/app_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves stored notification data in the selected language', () {
    final item = AppNotificationItem(
      id: 'budget:test',
      category: AppNotificationCategory.budget,
      createdAt: DateTime(2026, 7, 2),
      data: const {'category_name': 'Kebutuhan Harian', 'usage_percent': 82},
    );

    final indonesian = NotificationTextResolver(
      localizations: const AppLocalizations(AppLanguage.id),
      currency: AppCurrency.idr,
    );
    final english = NotificationTextResolver(
      localizations: const AppLocalizations(AppLanguage.en),
      currency: AppCurrency.idr,
    );

    expect(indonesian.title(item), 'Anggaran Hampir Habis');
    expect(indonesian.body(item), contains('82%'));
    expect(english.title(item), 'Budget Is Almost Used Up');
  });
}
