enum AppLanguage {
  id(code: 'id', label: 'Indonesia'),
  en(code: 'en', label: 'English');

  final String code;
  final String label;

  const AppLanguage({required this.code, required this.label});

  static AppLanguage byCode(String code) {
    return values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.id,
    );
  }
}
