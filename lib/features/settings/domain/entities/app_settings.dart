import '../../../../app/theme/app_theme_palette.dart';
import 'app_lock_timeout.dart';
import 'app_currency.dart';
import 'app_language.dart';

class AppSettings {
  final bool hasCompletedSetup;
  final String displayName;
  final String email;
  final String userType;
  final String themeId;
  final String languageCode;
  final String currencyCode;
  final bool hideFinancialAmounts;
  final bool notificationPermissionPromptDismissed;
  final bool appLockEnabled;
  final bool biometricUnlockEnabled;
  final String appLockTimeoutCode;

  const AppSettings({
    required this.hasCompletedSetup,
    required this.displayName,
    required this.email,
    required this.userType,
    required this.themeId,
    required this.languageCode,
    required this.currencyCode,
    required this.hideFinancialAmounts,
    required this.notificationPermissionPromptDismissed,
    required this.appLockEnabled,
    required this.biometricUnlockEnabled,
    required this.appLockTimeoutCode,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      hasCompletedSetup: false,
      displayName: '',
      email: 'feri@dokido.local',
      userType: 'flexible_financial_period_user',
      themeId: 'teal_balance',
      languageCode: 'id',
      currencyCode: 'IDR',
      hideFinancialAmounts: false,
      notificationPermissionPromptDismissed: false,
      appLockEnabled: false,
      biometricUnlockEnabled: false,
      appLockTimeoutCode: 'immediately',
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      hasCompletedSetup:
          json['has_completed_setup'] as bool? ?? defaults.hasCompletedSetup,
      displayName: json['display_name'] as String? ?? defaults.displayName,
      email: json['email'] as String? ?? defaults.email,
      userType: json['user_type'] as String? ?? defaults.userType,
      themeId: json['theme_id'] as String? ?? defaults.themeId,
      languageCode: json['language_code'] as String? ?? defaults.languageCode,
      currencyCode: json['currency_code'] as String? ?? defaults.currencyCode,
      hideFinancialAmounts:
          json['hide_financial_amounts'] as bool? ??
          defaults.hideFinancialAmounts,
      notificationPermissionPromptDismissed:
          json['notification_permission_prompt_dismissed'] as bool? ??
          defaults.notificationPermissionPromptDismissed,
      appLockEnabled:
          json['app_lock_enabled'] as bool? ?? defaults.appLockEnabled,
      biometricUnlockEnabled:
          json['biometric_unlock_enabled'] as bool? ??
          defaults.biometricUnlockEnabled,
      appLockTimeoutCode:
          json['app_lock_timeout'] as String? ?? defaults.appLockTimeoutCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_completed_setup': hasCompletedSetup,
      'display_name': displayName,
      'email': email,
      'user_type': userType,
      'theme_id': themeId,
      'language_code': languageCode,
      'currency_code': currencyCode,
      'hide_financial_amounts': hideFinancialAmounts,
      'notification_permission_prompt_dismissed':
          notificationPermissionPromptDismissed,
      'app_lock_enabled': appLockEnabled,
      'biometric_unlock_enabled': biometricUnlockEnabled,
      'app_lock_timeout': appLockTimeoutCode,
    };
  }

  AppThemePalette get themePalette => AppThemePalettes.byId(themeId);
  AppLanguage get language => AppLanguage.byCode(languageCode);
  AppCurrency get currency => AppCurrency.byCode(currencyCode);
  AppLockTimeout get appLockTimeout =>
      AppLockTimeout.byCode(appLockTimeoutCode);

  AppSettings copyWith({
    bool? hasCompletedSetup,
    String? displayName,
    String? email,
    String? userType,
    String? themeId,
    String? languageCode,
    String? currencyCode,
    bool? hideFinancialAmounts,
    bool? notificationPermissionPromptDismissed,
    bool? appLockEnabled,
    bool? biometricUnlockEnabled,
    String? appLockTimeoutCode,
  }) {
    return AppSettings(
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      themeId: themeId ?? this.themeId,
      languageCode: languageCode ?? this.languageCode,
      currencyCode: currencyCode ?? this.currencyCode,
      hideFinancialAmounts: hideFinancialAmounts ?? this.hideFinancialAmounts,
      notificationPermissionPromptDismissed:
          notificationPermissionPromptDismissed ??
          this.notificationPermissionPromptDismissed,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricUnlockEnabled:
          biometricUnlockEnabled ?? this.biometricUnlockEnabled,
      appLockTimeoutCode: appLockTimeoutCode ?? this.appLockTimeoutCode,
    );
  }
}
