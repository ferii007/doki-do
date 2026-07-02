import 'package:flutter/material.dart';

import 'app_theme_palette.dart';

class AppColors {
  static AppThemePalette _active = AppThemePalettes.tealBalance;

  static void applyPalette(AppThemePalette palette) {
    _active = palette;
  }

  static AppThemePalette get activePalette => _active;

  static Color _towardWhite(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount)!;
  }

  static Color get cream => _towardWhite(_active.background, 0.55);
  static Color get mint => _towardWhite(_active.accent, 0.28);
  static Color get aqua => _active.secondary;
  static Color get deepTeal => _active.primary;

  static Color get primary => _active.primary;
  static Color get secondary => _active.secondary;
  static Color get textPrimary => _active.textPrimary;
  static Color get textSecondary => _active.textSecondary;
  static Color get background => _towardWhite(_active.background, 0.62);
  static Color get overlay => _active.overlay;
  static Color get sheet => _active.sheet;
  static Color get surface => _active.surface;
  static Color get mintSurface => _towardWhite(_active.mintSurface, 0.48);
  static Color get creamSurface => _towardWhite(_active.creamSurface, 0.52);
  static Color get border => _active.border;
  static Color get danger => _active.danger;
  static Color get warning => _active.warning;
  static Color get success => _active.primary;

  static LinearGradient get heroGradient => _active.heroGradient;
  static LinearGradient get warmGradient => _active.warmGradient;
}
