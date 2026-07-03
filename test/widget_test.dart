import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:doki_do/app/app.dart';
import 'package:doki_do/core/security/encrypted_storage.dart';
import 'package:doki_do/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:doki_do/features/settings/presentation/providers/app_settings_provider.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    tempDirectory = Directory.systemTemp.createTempSync('doki_do_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsPath: tempDirectory.path,
    );
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('renders DokiDo app root', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsLocalDatasourceProvider.overrideWithValue(
            SettingsLocalDatasource(
              encryptedStorage: EncryptedStorage(
                keyStore: MemoryEncryptionKeyStore(),
              ),
            ),
          ),
        ],
        child: const DokiDoApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(DokiDoApp), findsOneWidget);
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String documentsPath;

  _FakePathProviderPlatform({required this.documentsPath});

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
