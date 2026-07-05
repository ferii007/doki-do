import 'dart:ui';

enum AppLanguage {
  id(code: 'id', labelKey: 'language_indonesian'),
  en(code: 'en', labelKey: 'language_english');

  final String code;
  final String labelKey;

  const AppLanguage({required this.code, required this.labelKey});

  static AppLanguage byCode(String code) {
    return values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.en,
    );
  }

  static AppLanguage fromSystemLanguageCode(String languageCode) {
    if (languageCode.toLowerCase() == 'in') return AppLanguage.id;
    return values.firstWhere(
      (language) => language.code == languageCode.toLowerCase(),
      orElse: () => AppLanguage.en,
    );
  }

  static AppLanguage get systemDefault =>
      fromSystemLanguageCode(PlatformDispatcher.instance.locale.languageCode);
}
