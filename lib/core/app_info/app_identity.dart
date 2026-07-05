class AppIdentity {
  static const appName = 'DokiDo';
  static const appTitle = '$appName Finance';

  static const developerName = 'Niscala.dev';
  static const developerHandle = 'niscala';
  static const developerEmail = '$developerHandle@dokido.local';
  static const developerAttribution = 'Powered by $developerName';

  // Compatibility identifier. Changing this makes existing encrypted data and
  // portable backups unreadable, so it must not follow a future app rename.
  static const storageProtocolId = 'DokiDo';
  static const legacyDeveloperEmail = 'feri@dokido.local';

  const AppIdentity._();
}
