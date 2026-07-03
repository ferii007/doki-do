import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';

class SettingsLocalDatasource {
  static const _storageFileName = 'doki_do_settings.json';

  AppSettings? _cache;

  Future<AppSettings> readSettings() async {
    if (_cache != null) return _cache!;

    final file = await _storageFile();
    if (!await file.exists()) {
      _cache = AppSettings.defaults();
      await saveSettings(_cache!);
      return _cache!;
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Settings storage root must be an object.');
      }
      final userType = decoded['user_type'];
      if (userType is String &&
          AppLanguage.values.any(
            (language) =>
                userType ==
                AppLocalizations(language).tr('flexible_financial_period_user'),
          )) {
        decoded['user_type'] = 'flexible_financial_period_user';
      }
      _cache = AppSettings.fromJson(decoded);
      await saveSettings(_cache!);
      return _cache!;
    } on FormatException {
      _cache = AppSettings.defaults();
      await saveSettings(_cache!);
      return _cache!;
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    _cache = settings;
    final file = await _storageFile();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(settings.toJson()));
  }

  Future<File> _storageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_storageFileName');
  }
}
