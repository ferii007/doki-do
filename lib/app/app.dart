import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/formatters/date_formatter.dart';
import '../core/formatters/rupiah_formatter.dart';
import '../core/localization/app_localizations.dart';
import '../features/finance/presentation/screens/dashboard_screen.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/domain/entities/app_language.dart';
import '../features/settings/presentation/providers/app_settings_provider.dart';
import '../features/setup/presentation/screens/setup_screen.dart';
import 'router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class DokiDoApp extends ConsumerWidget {
  const DokiDoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final settings = settingsAsync.asData?.value;
    final language = settings?.language ?? AppLanguage.id;
    FinancialPrivacyPreference.hideAmounts =
        settings?.hideFinancialAmounts ?? false;
    if (settings != null) {
      AppColors.applyPalette(settings.themePalette);
      CurrencyFormatterPreference.current = settings.currency;
      DateFormatterPreference.current = settings.language;
    }

    return MaterialApp(
      title: 'DokiDo Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: Locale(language.code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routes: AppRouter.routes,
      builder: (context, child) => AppLocalizationsScope(
        localizations: AppLocalizations(language),
        child: child ?? const SizedBox.shrink(),
      ),
      home: AppLocalizationsScope(
        localizations: AppLocalizations(language),
        child: _AppStartupGate(settingsAsync: settingsAsync),
      ),
    );
  }
}

class _AppStartupGate extends StatefulWidget {
  final AsyncValue<AppSettings> settingsAsync;

  const _AppStartupGate({required this.settingsAsync});

  @override
  State<_AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<_AppStartupGate> {
  static const _minimumSplashDuration = Duration(milliseconds: 1300);

  bool _splashDone = false;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(_minimumSplashDuration, () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone || widget.settingsAsync.isLoading) {
      return const _AnimatedSplashScreen();
    }

    return widget.settingsAsync.when(
      loading: () => const _AnimatedSplashScreen(),
      error: (error, _) => _AppBootError(error: error),
      data: (settings) {
        AppColors.applyPalette(settings.themePalette);
        CurrencyFormatterPreference.current = settings.currency;
        DateFormatterPreference.current = settings.language;
        FinancialPrivacyPreference.hideAmounts = settings.hideFinancialAmounts;
        return settings.hasCompletedSetup
            ? const DashboardScreen()
            : SetupScreen(initialSettings: settings);
      },
    );
  }
}

class _AnimatedSplashScreen extends StatefulWidget {
  const _AnimatedSplashScreen();

  @override
  State<_AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<_AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _opacity = Tween<double>(
      begin: 0.74,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.mintSurface,
              AppColors.surface,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Image.asset(
                'assets/images/dokido_logo.png',
                width: 220,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBootError extends StatelessWidget {
  final Object error;

  const _AppBootError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.trf('failed_to_load_settings_error', {'error': error}),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
