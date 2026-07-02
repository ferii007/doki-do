import 'package:flutter/material.dart';

class AppThemePalette {
  final String id;
  final String name;
  final String description;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color mintSurface;
  final Color creamSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color overlay;
  final Color sheet;
  final Color danger;
  final Color warning;

  const AppThemePalette({
    required this.id,
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.mintSurface,
    required this.creamSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.overlay,
    required this.sheet,
    required this.danger,
    required this.warning,
  });

  LinearGradient get heroGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, Color.lerp(primary, overlay, 0.18)!],
    );
  }

  LinearGradient get warmGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [surface, Color.lerp(surface, mintSurface, 0.52)!],
    );
  }
}

class AppThemePalettes {
  static const tealBalance = AppThemePalette(
    id: 'teal_balance',
    name: 'Teal Balance',
    description: 'fresh_modern_and_closest_to_dokido_s_identity',
    primary: Color(0xFF007979),
    secondary: Color(0xFF24B1B1),
    accent: Color(0xFFFFE0C5),
    background: Color(0xFFFFF0E4),
    surface: Color(0xFFFFFBF7),
    mintSurface: Color(0xFFE4F7F3),
    creamSurface: Color(0xFFFFF2E4),
    textPrimary: Color(0xFF173D3D),
    textSecondary: Color(0xFF64817C),
    border: Color(0xFFD6E6DE),
    overlay: Color(0xFF143836),
    sheet: Color(0xFF0D5F5F),
    danger: Color(0xFFD85B5B),
    warning: Color(0xFFE7A83D),
  );

  static const freshMint = AppThemePalette(
    id: 'fresh_mint',
    name: 'Fresh Mint',
    description: 'calm_fresh_green_and_comfortable_for_daily_use',
    primary: Color(0xFF659287),
    secondary: Color(0xFF88BDA4),
    accent: Color(0xFFB1D3B9),
    background: Color(0xFFE6F2DD),
    surface: Color(0xFFFBFFF8),
    mintSurface: Color(0xFFEAF6ED),
    creamSurface: Color(0xFFF4F8E9),
    textPrimary: Color(0xFF27433B),
    textSecondary: Color(0xFF637D70),
    border: Color(0xFFD8E6D8),
    overlay: Color(0xFF1D3832),
    sheet: Color(0xFF4D7B70),
    danger: Color(0xFFD85B5B),
    warning: Color(0xFFE0A642),
  );

  static const roseLedger = AppThemePalette(
    id: 'rose_ledger',
    name: 'Rose Ledger',
    description: 'warm_personal_with_a_strong_accent',
    primary: Color(0xFF850E35),
    secondary: Color(0xFFEE6983),
    accent: Color(0xFFFFC4C4),
    background: Color(0xFFFCF5EE),
    surface: Color(0xFFFFFBF8),
    mintSurface: Color(0xFFFFE4E8),
    creamSurface: Color(0xFFFFF0E5),
    textPrimary: Color(0xFF3B1220),
    textSecondary: Color(0xFF8B6671),
    border: Color(0xFFF0D6D6),
    overlay: Color(0xFF3B0A18),
    sheet: Color(0xFF6D0D2E),
    danger: Color(0xFFB4233E),
    warning: Color(0xFFE69B45),
  );

  static const sageBudget = AppThemePalette(
    id: 'sage_budget',
    name: 'Sage Budget',
    description: 'natural_soft_and_stable',
    primary: Color(0xFF89986D),
    secondary: Color(0xFF9CAB84),
    accent: Color(0xFFC5D89D),
    background: Color(0xFFF6F0D7),
    surface: Color(0xFFFFFCEF),
    mintSurface: Color(0xFFEAF1D6),
    creamSurface: Color(0xFFF9F1D4),
    textPrimary: Color(0xFF3C442F),
    textSecondary: Color(0xFF777D65),
    border: Color(0xFFE3DEC4),
    overlay: Color(0xFF333A28),
    sheet: Color(0xFF687650),
    danger: Color(0xFFD85B5B),
    warning: Color(0xFFD69A3A),
  );

  static const softLinen = AppThemePalette(
    id: 'soft_linen',
    name: 'Soft Linen',
    description: 'minimal_clean_and_calm_for_tidy_tracking',
    primary: Color(0xFFC9B59C),
    secondary: Color(0xFFD9CFC7),
    accent: Color(0xFFEFE9E3),
    background: Color(0xFFF9F8F6),
    surface: Color(0xFFFFFFFF),
    mintSurface: Color(0xFFF4EFE9),
    creamSurface: Color(0xFFFAF3EA),
    textPrimary: Color(0xFF40382F),
    textSecondary: Color(0xFF83786E),
    border: Color(0xFFE5DDD5),
    overlay: Color(0xFF3A3028),
    sheet: Color(0xFF8E7A64),
    danger: Color(0xFFD85B5B),
    warning: Color(0xFFD99B48),
  );

  static const warmSignal = AppThemePalette(
    id: 'warm_signal',
    name: 'Warm Signal',
    description: 'bright_clean_with_a_bold_accent',
    primary: Color(0xFFF62440),
    secondary: Color(0xFFFFE5BF),
    accent: Color(0xFFFFF2DB),
    background: Color(0xFFFFFAF3),
    surface: Color(0xFFFFFFFF),
    mintSurface: Color(0xFFFFEEE5),
    creamSurface: Color(0xFFFFF3D6),
    textPrimary: Color(0xFF3F2023),
    textSecondary: Color(0xFF8A6A63),
    border: Color(0xFFF3DEC1),
    overlay: Color(0xFF3C171D),
    sheet: Color(0xFFC51E33),
    danger: Color(0xFFF62440),
    warning: Color(0xFFE59A25),
  );

  static const lavenderCalm = AppThemePalette(
    id: 'lavender_calm',
    name: 'Lavender Calm',
    description: 'soft_lavender_with_warm_balance',
    primary: Color(0xFF8294C4),
    secondary: Color(0xFFACB1D6),
    accent: Color(0xFFFFEAD2),
    background: Color(0xFFF7F8FC),
    surface: Color(0xFFFFFFFF),
    mintSurface: Color(0xFFF0F2FA),
    creamSurface: Color(0xFFFFF4E8),
    textPrimary: Color(0xFF27324D),
    textSecondary: Color(0xFF68708A),
    border: Color(0xFFE0E4F2),
    overlay: Color(0xFF202A45),
    sheet: Color(0xFF687AAD),
    danger: Color(0xFFD85B6A),
    warning: Color(0xFFE5A54A),
  );

  static const coastalBlue = AppThemePalette(
    id: 'coastal_blue',
    name: 'Coastal Blue',
    description: 'cool_blue_clean_and_focused',
    primary: Color(0xFF355872),
    secondary: Color(0xFF7AAACE),
    accent: Color(0xFF9CD5FF),
    background: Color(0xFFF7F8F0),
    surface: Color(0xFFFFFFFF),
    mintSurface: Color(0xFFEAF5FB),
    creamSurface: Color(0xFFFBFAF0),
    textPrimary: Color(0xFF1C3445),
    textSecondary: Color(0xFF607987),
    border: Color(0xFFD8E8EF),
    overlay: Color(0xFF172D3C),
    sheet: Color(0xFF2D4E66),
    danger: Color(0xFFD85B5B),
    warning: Color(0xFFE2A23A),
  );

  static const electricBlue = AppThemePalette(
    id: 'electric_blue',
    name: 'Electric Blue',
    description: 'bright_blue_for_clear_financial_focus',
    primary: Color(0xFF2C5EAD),
    secondary: Color(0xFF1591DC),
    accent: Color(0xFF4BB8FA),
    background: Color(0xFFF2F8FE),
    surface: Color(0xFFFFFFFF),
    mintSurface: Color(0xFFE7F4FE),
    creamSurface: Color(0xFFF3F8FC),
    textPrimary: Color(0xFF17355F),
    textSecondary: Color(0xFF5D7795),
    border: Color(0xFFD5E7F6),
    overlay: Color(0xFF132B4F),
    sheet: Color(0xFF204F99),
    danger: Color(0xFFD85B5B),
    warning: Color(0xFFE6A23A),
  );

  static const blushMauve = AppThemePalette(
    id: 'blush_mauve',
    name: 'Blush Mauve',
    description: 'soft_blush_with_a_personal_feel',
    primary: Color(0xFFC5B3D3),
    secondary: Color(0xFFF5CBCB),
    accent: Color(0xFFFFE2E2),
    background: Color(0xFFFEF7F7),
    surface: Color(0xFFFFFFFF),
    mintSurface: Color(0xFFF9ECEF),
    creamSurface: Color(0xFFFFF1F1),
    textPrimary: Color(0xFF46364F),
    textSecondary: Color(0xFF836E86),
    border: Color(0xFFEEDDE8),
    overlay: Color(0xFF3B2B44),
    sheet: Color(0xFF9F83B4),
    danger: Color(0xFFD85B6A),
    warning: Color(0xFFE4A24B),
  );

  static const mintGlow = AppThemePalette(
    id: 'mint_glow',
    name: 'Mint Glow',
    description: 'fresh_mint_with_a_light_sunny_accent',
    primary: Color(0xFF34908B),
    secondary: Color(0xFF6FBEB2),
    accent: Color(0xFFA5E9DD),
    background: Color(0xFFFEFBDE),
    surface: Color(0xFFFFFEF2),
    mintSurface: Color(0xFFE8FAF5),
    creamSurface: Color(0xFFFFF7C8),
    textPrimary: Color(0xFF1D4643),
    textSecondary: Color(0xFF63827C),
    border: Color(0xFFD5EBE2),
    overlay: Color(0xFF173C39),
    sheet: Color(0xFF287A75),
    danger: Color(0xFFD85B5B),
    warning: Color(0xFFE2A63A),
  );

  static const olivePaper = AppThemePalette(
    id: 'olive_paper',
    name: 'Olive Paper',
    description: 'muted_green_with_soft_paper_tones',
    primary: Color(0xFF778873),
    secondary: Color(0xFFA1BC98),
    accent: Color(0xFFDCCFC0),
    background: Color(0xFFFDF6ED),
    surface: Color(0xFFFFFCF7),
    mintSurface: Color(0xFFEFF5EA),
    creamSurface: Color(0xFFF8EEE4),
    textPrimary: Color(0xFF344331),
    textSecondary: Color(0xFF6E7F68),
    border: Color(0xFFE2E8DA),
    overlay: Color(0xFF2D392A),
    sheet: Color(0xFF63755F),
    danger: Color(0xFFD85B5B),
    warning: Color(0xFFD99A42),
  );

  static const forestMint = AppThemePalette(
    id: 'forest_mint',
    name: 'Forest Mint',
    description: 'deep_green_with_mint_highlights',
    primary: Color(0xFF1A312C),
    secondary: Color(0xFF428475),
    accent: Color(0xFF89D7B7),
    background: Color(0xFFFFF4E1),
    surface: Color(0xFFFFFBF4),
    mintSurface: Color(0xFFE6F7EF),
    creamSurface: Color(0xFFFFF0D5),
    textPrimary: Color(0xFF182D29),
    textSecondary: Color(0xFF5B766F),
    border: Color(0xFFD8E9E1),
    overlay: Color(0xFF132622),
    sheet: Color(0xFF1F5148),
    danger: Color(0xFFD85B5B),
    warning: Color(0xFFE1A13B),
  );

  static const values = [
    tealBalance,
    lavenderCalm,
    coastalBlue,
    electricBlue,
    blushMauve,
    mintGlow,
    warmSignal,
    freshMint,
    olivePaper,
    forestMint,
    // roseLedger,
    // sageBudget,
    // softLinen,
  ];

  static AppThemePalette byId(String id) {
    return values.firstWhere(
      (palette) => palette.id == id,
      orElse: () => tealBalance,
    );
  }
}
