// ignore_for_file: unused_element, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_theme_palette.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../settings/domain/entities/app_currency.dart';
import '../../../../settings/domain/entities/app_language.dart';
import '../../../../settings/domain/entities/app_settings.dart';
import '../../../../settings/presentation/providers/app_settings_provider.dart';

class SettingsTabBody extends ConsumerWidget {
  const SettingsTabBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).asData?.value;
    final value = settings ?? AppSettings.defaults();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccountProfileCard(settings: value),
          const SizedBox(height: 14),
          _SettingsSection(
            title: context.tr('app_preferences'),
            children: [
              _SettingsOptionRow(
                icon: Icons.palette_rounded,
                label: context.tr('color_theme'),
                value: context.tr(value.themePalette.nameKey),
                onTap: () => _showThemeSheet(context, ref, value),
              ),
              _SettingsOptionRow(
                icon: Icons.translate_rounded,
                label: context.tr('language'),
                value: context.tr(value.language.labelKey),
                onTap: () => _showLanguageSheet(context, ref, value),
              ),
              _SettingsOptionRow(
                icon: Icons.attach_money_rounded,
                label: context.tr('currency'),
                value:
                    '${value.currency.code} • ${context.tr(value.currency.labelKey)}',
                onTap: () => _showCurrencySheet(context, ref, value),
              ),
              _SettingsOptionRow(
                icon: Icons.event_repeat_rounded,
                label: context.tr('transaction_templates'),
                value: context.tr('transaction_templates_settings_value'),
                showDivider: false,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.transactionTemplates,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              context.tr('powered_by_feri'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          /*
          const SizedBox(height: 14),
          _SettingsSection(
            title: context.tr('daily_tracking'),
            children: [
              _SettingsOptionRow(
                icon: Icons.today_rounded,
                label: context.tr('new_record_date'),
                value: context.tr('today'),
              ),
              _SettingsOptionRow(
                icon: Icons.bolt_rounded,
                label: context.tr('quick_add_default'),
                value: context.tr('expense'),
              ),
              _SettingsToggleRow(
                icon: Icons.notes_rounded,
                label: context.tr('note_required'),
                value: context.tr('off'),
                enabled: false,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: context.tr('period_and_budget'),
            children: [
              _SettingsOptionRow(
                icon: Icons.date_range_rounded,
                label: context.tr('period_start_date'),
                value: context.tr('the_22nd_of_every_month'),
              ),
              _SettingsOptionRow(
                icon: Icons.pie_chart_rounded,
                label: context.tr('default_template'),
                value: '50/30/20',
              ),
              _SettingsOptionRow(
                icon: Icons.sync_alt_rounded,
                label: context.tr('new_budget_calculation'),
                value: context.tr('follows_income'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: context.tr('reminders'),
            children: [
              _SettingsToggleRow(
                icon: Icons.notifications_active_rounded,
                label: context.tr('daily_tracking_reminder'),
                value: context.tr('off'),
                enabled: false,
              ),
              _SettingsOptionRow(
                icon: Icons.schedule_rounded,
                label: context.tr('reminder_time'),
                value: '20:00',
              ),
              _SettingsToggleRow(
                icon: Icons.event_available_rounded,
                label: context.tr('end_period_reminder'),
                value: 'H-3',
                enabled: true,
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: context.tr('data'),
            children: [
              _SettingsOptionRow(
                icon: Icons.storage_rounded,
                label: context.tr('data_mode'),
                value: context.tr('local_device_storage'),
                chipText: context.tr('local'),
              ),
              _SettingsOptionRow(
                icon: Icons.file_download_rounded,
                label: context.tr('download_data'),
                value: context.tr('not_active'),
              ),
              _SettingsOptionRow(
                icon: Icons.cloud_sync_rounded,
                label: context.tr('online_sync'),
                value: context.tr('not_connected'),
                showDivider: false,
              ),
            ],
          ),
          */
        ],
      ),
    );
  }

  Future<void> _showThemeSheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _PreferenceSheet<AppThemePalette>(
        title: context.tr('choose_color_theme'),
        selected: settings.themePalette,
        options: [
          for (final palette in AppThemePalettes.values)
            _PreferenceOption(
              value: palette,
              title: context.tr(palette.nameKey),
              subtitle: context.tr(palette.description),
              swatches: [
                palette.primary,
                palette.secondary,
                palette.accent,
                palette.background,
              ],
            ),
        ],
        onSelected: (palette) async {
          await _saveSettings(
            context,
            ref,
            settings.copyWith(themeId: palette.id),
          );
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _showLanguageSheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _PreferenceSheet<AppLanguage>(
        title: context.tr('choose_language'),
        selected: settings.language,
        options: [
          for (final language in AppLanguage.values)
            _PreferenceOption(
              value: language,
              title: context.tr(language.labelKey),
              subtitle: language.code.toUpperCase(),
              icon: Icons.translate_rounded,
            ),
        ],
        onSelected: (language) async {
          await _saveSettings(
            context,
            ref,
            settings.copyWith(languageCode: language.code),
          );
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _showCurrencySheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => _PreferenceSheet<AppCurrency>(
        title: context.tr('choose_currency'),
        selected: settings.currency,
        options: [
          for (final currency in AppCurrency.values)
            _PreferenceOption(
              value: currency,
              title: currency.code,
              subtitle: context.tr(currency.labelKey),
              icon: Icons.payments_rounded,
            ),
        ],
        onSelected: (currency) async {
          await _saveSettings(
            context,
            ref,
            settings.copyWith(currencyCode: currency.code),
          );
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _saveSettings(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    await ref.read(appSettingsProvider.notifier).save(settings);
    if (!context.mounted) return;
    AppToast.show(context, context.tr('settings_updated_successfully'));
  }
}

class _AccountProfileCard extends StatelessWidget {
  final AppSettings settings;

  const _AccountProfileCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(alpha: 0.045),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('account_profile'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settings.email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _SettingsChip(label: context.tr('local')),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.7)),
          const SizedBox(height: 4),
          _SettingsOptionRow(
            icon: Icons.badge_rounded,
            label: context.tr('display_name'),
            value: settings.displayName,
          ),
          _SettingsOptionRow(
            icon: Icons.work_rounded,
            label: context.tr('tracking_pattern'),
            value: _localizedUserType(context, settings.userType),
            showDivider: false,
          ),
          /*
          _SettingsOptionRow(
            icon: Icons.lock_rounded,
            label: context.tr('login_and_security'),
            value: context.tr('not_active'),
            showDivider: false,
          ),
          */
        ],
      ),
    );
  }
}

String _localizedUserType(BuildContext context, String value) {
  return value == 'flexible_financial_period_user' ? context.tr(value) : value;
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? chipText;
  final bool showDivider;
  final VoidCallback? onTap;

  const _SettingsOptionRow({
    required this.icon,
    required this.label,
    required this.value,
    this.chipText,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsRowShell(
      icon: icon,
      label: label,
      value: value,
      trailing: onTap != null
          ? Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary)
          : chipText == null
          ? null
          : _SettingsChip(label: chipText!),
      showDivider: showDivider,
      onTap: onTap,
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool enabled;
  final bool showDivider;

  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsRowShell(
      icon: icon,
      label: label,
      value: value,
      trailing: _SchemaSwitch(enabled: enabled),
      showDivider: showDivider,
    );
  }
}

class _SettingsRowShell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final bool showDivider;
  final VoidCallback? onTap;

  const _SettingsRowShell({
    required this.icon,
    required this.label,
    required this.value,
    required this.trailing,
    required this.showDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _SettingsIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );

    return Column(
      children: [
        if (onTap == null)
          content
        else
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: content,
          ),
        if (showDivider)
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.7)),
      ],
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;

  const _SettingsIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.mintSurface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

class _SettingsChip extends StatelessWidget {
  final String label;

  const _SettingsChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mintSurface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SchemaSwitch extends StatelessWidget {
  final bool enabled;

  const _SchemaSwitch({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: enabled ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppColors.overlay.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceOption<T> {
  final T value;
  final String title;
  final String subtitle;
  final IconData? icon;
  final List<Color> swatches;

  const _PreferenceOption({
    required this.value,
    required this.title,
    required this.subtitle,
    this.icon,
    this.swatches = const [],
  });
}

class _PreferenceSheet<T> extends StatelessWidget {
  final String title;
  final T selected;
  final List<_PreferenceOption<T>> options;
  final ValueChanged<T> onSelected;

  const _PreferenceSheet({
    required this.title,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSheetHeader(title: title, icon: Icons.tune_rounded),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                return _PreferenceOptionCard<T>(
                  option: option,
                  selected: option.value == selected,
                  onTap: () => onSelected(option.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceOptionCard<T> extends StatelessWidget {
  final _PreferenceOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  const _PreferenceOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            if (option.swatches.isNotEmpty)
              _PreferenceSwatches(colors: option.swatches)
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.mintSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: AppColors.primary, size: 20),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSwatches extends StatelessWidget {
  final List<Color> colors;

  const _PreferenceSwatches({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final color in colors)
          Container(
            width: 9,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}
