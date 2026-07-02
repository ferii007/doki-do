import '../../features/settings/domain/entities/app_language.dart';

class DateFormatterPreference {
  static AppLanguage current = AppLanguage.id;
}

class DateFormatter {
  static const _shortMonthsId = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const _longMonthsId = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const _shortMonthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _longMonthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String period(DateTime start, DateTime end) {
    return '${short(start)} - ${shortWithYear(end)}';
  }

  static String periodFull(DateTime start, DateTime end) {
    return '${full(start)} - ${full(end)}';
  }

  static String short(DateTime value) {
    final months = DateFormatterPreference.current == AppLanguage.en
        ? _shortMonthsEn
        : _shortMonthsId;
    return '${value.day} ${months[value.month - 1]}';
  }

  static String shortWithYear(DateTime value) {
    return '${short(value)} ${value.year}';
  }

  static String monthYear(DateTime value) {
    final months = DateFormatterPreference.current == AppLanguage.en
        ? _longMonthsEn
        : _longMonthsId;
    return '${months[value.month - 1]} ${value.year}';
  }

  static String full(DateTime value) {
    final months = DateFormatterPreference.current == AppLanguage.en
        ? _longMonthsEn
        : _longMonthsId;
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}
