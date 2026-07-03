import '../../features/settings/domain/entities/app_language.dart';
import '../localization/app_localizations.dart';

class DateFormatterPreference {
  static AppLanguage current = AppLanguage.id;
}

class DateFormatter {
  static String period(DateTime start, DateTime end) {
    return '${short(start)} - ${shortWithYear(end)}';
  }

  static String periodFull(DateTime start, DateTime end) {
    return '${full(start)} - ${full(end)}';
  }

  static String short(DateTime value) {
    return '${value.day} ${_localizations.tr('month_short_${value.month}')}';
  }

  static String shortWithYear(DateTime value) {
    return '${short(value)} ${value.year}';
  }

  static String monthYear(DateTime value) {
    return '${_localizations.tr('month_long_${value.month}')} ${value.year}';
  }

  static String monthName(int month, {bool short = false}) {
    return _localizations.tr('${short ? 'month_short' : 'month_long'}_$month');
  }

  static String full(DateTime value) {
    return '${value.day} ${_localizations.tr('month_long_${value.month}')} ${value.year}';
  }

  static AppLocalizations get _localizations =>
      AppLocalizations(DateFormatterPreference.current);
}
