import '../../finance/data/datasources/finance_local_datasource.dart';
import '../../settings/data/datasources/settings_local_datasource.dart';
import 'backup_archive.dart';
import 'backup_archive_codec.dart';
import '../data/backup_file_gateway.dart';

class BackupService {
  final FinanceLocalDatasource _financeDatasource;
  final SettingsLocalDatasource _settingsDatasource;
  final BackupArchiveCodec _codec;
  final BackupFileGateway _fileGateway;
  final DateTime Function() _now;

  const BackupService({
    required FinanceLocalDatasource financeDatasource,
    required SettingsLocalDatasource settingsDatasource,
    required BackupArchiveCodec codec,
    required BackupFileGateway fileGateway,
    DateTime Function()? now,
  }) : _financeDatasource = financeDatasource,
       _settingsDatasource = settingsDatasource,
       _codec = codec,
       _fileGateway = fileGateway,
       _now = now ?? DateTime.now;

  Future<bool> hasPassword() => _codec.hasStoredCredential();

  Future<void> configurePassword(String password) {
    return _codec.configurePassword(password);
  }

  Future<BackupDirectory?> chooseDirectory() {
    return _fileGateway.chooseDirectory();
  }

  Future<BackupArchive> createBackup(String directoryUri) async {
    final archive = BackupArchive(
      createdAt: _now(),
      finance: await _financeDatasource.exportBackupData(),
      settings: await _settingsDatasource.exportBackupData(),
    );
    final encoded = await _codec.encodeWithStoredCredential(archive);
    await _codec.decodeWithStoredCredential(encoded);
    await _fileGateway.writeRotatingBackup(
      directoryUri: directoryUri,
      bytes: encoded,
    );
    return archive;
  }

  Future<BackupFileContent?> chooseBackupFile() {
    return _fileGateway.chooseBackupFile();
  }

  Future<BackupFileContent?> readLatestBackup(String directoryUri) {
    return _fileGateway.readLatestBackup(directoryUri);
  }

  Future<BackupArchive> inspectBackup(BackupFileContent file, String password) {
    return _codec.decodeWithPassword(file.bytes, password);
  }

  Future<void> restoreBackup(BackupArchive archive) async {
    final previousFinance = await _financeDatasource.exportBackupData();
    final previousSettings = await _settingsDatasource.exportBackupData();

    try {
      await _financeDatasource.restoreBackupData(archive.finance);
      await _settingsDatasource.restoreBackupData(archive.settings);
    } on Object {
      await _financeDatasource.restoreBackupData(previousFinance);
      await _settingsDatasource.restoreBackupData(previousSettings);
      rethrow;
    }
  }
}
