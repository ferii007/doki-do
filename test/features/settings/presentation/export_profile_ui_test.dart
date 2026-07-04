import 'package:doki_do/core/app_info/app_version_provider.dart';
import 'package:doki_do/features/finance/presentation/providers/current_budget_provider.dart';
import 'package:doki_do/features/finance/presentation/widgets/dashboard/profile_tab_body.dart';
import 'package:doki_do/features/settings/domain/entities/app_settings.dart';
import 'package:doki_do/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:doki_do/features/settings/presentation/screens/export_report_templates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('profile data actions render and show unavailable toast', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allBudgetSnapshotsProvider.overrideWith((ref) async => const []),
          appSettingsProvider.overrideWith(_FakeSettingsNotifier.new),
          appVersionProvider.overrideWith((ref) async => '1.0.0+1'),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: const [ProfileTabBody(currentSnapshot: null)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ekspor Laporan'), findsOneWidget);
    expect(find.text('Impor Data'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Ekspor Laporan'));
    await tester.pump();

    expect(find.text('Fitur ini belum tersedia.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('export templates default to Dashboard and can select Basic', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [appSettingsProvider.overrideWith(_FakeSettingsNotifier.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ExportReportTemplatesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Basic'), findsOneWidget);
    expect(
      container.read(appSettingsProvider).requireValue.exportReportTemplateCode,
      'dashboard',
    );

    await tester.ensureVisible(find.text('Basic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basic'));
    await tester.pump();

    expect(
      container.read(appSettingsProvider).requireValue.exportReportTemplateCode,
      'basic',
    );
    expect(find.text('Template Basic dipilih.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}

class _FakeSettingsNotifier extends AppSettingsNotifier {
  @override
  Future<AppSettings> build() async {
    return AppSettings.defaults().copyWith(
      hasCompletedSetup: true,
      displayName: 'Feri',
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    state = AsyncData(settings);
  }
}
