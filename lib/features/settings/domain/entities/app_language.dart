enum AppLanguage {
  id(code: 'id', labelKey: 'language_indonesian'),
  en(code: 'en', labelKey: 'language_english');

  final String code;
  final String labelKey;

  const AppLanguage({required this.code, required this.labelKey});

  static AppLanguage byCode(String code) {
    return values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.id,
    );
  }
}
