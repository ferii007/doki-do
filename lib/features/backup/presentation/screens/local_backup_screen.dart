import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/entities/backup_frequency.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../../data/backup_file_gateway.dart';
import '../../domain/backup_archive.dart';
import '../../domain/backup_archive_codec.dart';
import '../providers/backup_provider.dart';

class LocalBackupScreen extends ConsumerWidget {
  const LocalBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appSettingsProvider).asData?.value ?? AppSettings.defaults();
    final backupState = ref.watch(backupControllerProvider).asData?.value;
    final isRunning = backupState?.isRunning ?? false;
    final configured =
        settings.backupFolderUri != null && (backupState?.hasPassword ?? false);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('local_backup'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _BackupStatusCard(
            configured: configured,
            lastBackupAt: settings.lastBackupDateTime,
          ),
          const SizedBox(height: 14),
          _BackupSection(
            title: context.tr('backup_storage'),
            children: [
              _BackupOption(
                icon: Icons.folder_rounded,
                title: context.tr('backup_location'),
                subtitle:
                    settings.backupFolderName ??
                    context.tr('backup_location_not_selected'),
                actionLabel: context.tr(
                  settings.backupFolderUri == null ? 'choose' : 'change',
                ),
                onTap: isRunning ? null : () => _chooseDirectory(context, ref),
              ),
              _BackupOption(
                icon: Icons.password_rounded,
                title: context.tr('backup_password'),
                subtitle: context.tr(
                  backupState?.hasPassword ?? false
                      ? 'backup_password_configured'
                      : 'backup_password_missing_description',
                ),
                actionLabel: context.tr(
                  backupState?.hasPassword ?? false ? 'change' : 'create',
                ),
                showDivider: false,
                onTap: isRunning
                    ? null
                    : () => _configurePassword(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BackupSection(
            title: context.tr('automatic_backup'),
            children: [
              _BackupOption(
                icon: Icons.autorenew_rounded,
                title: context.tr('backup_frequency'),
                subtitle: context.tr(settings.backupFrequency.labelKey),
                actionLabel: context.tr('set'),
                showDivider: false,
                onTap: isRunning
                    ? null
                    : () => _chooseFrequency(context, ref, settings),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BackupSection(
            title: context.tr('backup_actions'),
            children: [
              _BackupOption(
                icon: Icons.backup_rounded,
                title: context.tr('backup_now'),
                subtitle: context.tr('backup_now_description'),
                actionLabel: context.tr('start'),
                onTap: isRunning ? null : () => _backupNow(context, ref),
              ),
              _BackupOption(
                icon: Icons.settings_backup_restore_rounded,
                title: context.tr('restore_latest_backup'),
                subtitle: context.tr('restore_latest_backup_description'),
                actionLabel: context.tr('restore'),
                onTap: isRunning ? null : () => _restoreLatest(context, ref),
              ),
              _BackupOption(
                icon: Icons.file_open_rounded,
                title: context.tr('choose_another_backup_file'),
                subtitle: context.tr('choose_another_backup_file_description'),
                actionLabel: context.tr('choose'),
                showDivider: false,
                onTap: isRunning
                    ? null
                    : () => _chooseRestoreFile(context, ref),
              ),
            ],
          ),
          if (isRunning) ...[
            const SizedBox(height: 16),
            _WorkingIndicator(label: context.tr('processing_backup')),
          ],
        ],
      ),
    );
  }

  Future<void> _chooseDirectory(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupControllerProvider.notifier).chooseDirectory();
    } on Object catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _configurePassword(BuildContext context, WidgetRef ref) async {
    final password = await _showPasswordSheet(
      context,
      confirming: true,
      titleKey: 'create_backup_password',
    );
    if (password == null || !context.mounted) return;
    try {
      await ref
          .read(backupControllerProvider.notifier)
          .configurePassword(password);
      if (context.mounted) {
        AppToast.show(context, context.tr('backup_password_saved'));
      }
    } on Object catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _chooseFrequency(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final selected = await showModalBottomSheet<BackupFrequency>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FrequencySheet(selected: settings.backupFrequency),
    );
    if (selected == null || !context.mounted) return;

    if (selected != BackupFrequency.off) {
      final ready = await _ensureBackupConfigured(context, ref);
      if (!ready || !context.mounted) return;
    }
    final current = ref.read(appSettingsProvider).asData?.value;
    if (current == null) return;
    await ref
        .read(appSettingsProvider.notifier)
        .save(current.copyWith(backupFrequencyCode: selected.code));
    if (context.mounted) {
      AppToast.show(context, context.tr('automatic_backup_updated'));
    }
  }

  Future<void> _backupNow(BuildContext context, WidgetRef ref) async {
    if (!await _ensureBackupConfigured(context, ref) || !context.mounted) {
      return;
    }
    try {
      await ref.read(backupControllerProvider.notifier).backupNow();
      if (context.mounted) {
        AppToast.show(context, context.tr('backup_created_successfully'));
      }
    } on Object catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<bool> _ensureBackupConfigured(
    BuildContext context,
    WidgetRef ref,
  ) async {
    var settings = ref.read(appSettingsProvider).asData?.value;
    if (settings?.backupFolderUri == null) {
      await _chooseDirectory(context, ref);
      settings = ref.read(appSettingsProvider).asData?.value;
      if (settings?.backupFolderUri == null) return false;
    }
    if (!context.mounted) return false;

    final hasPassword =
        ref.read(backupControllerProvider).asData?.value.hasPassword ?? false;
    if (!hasPassword) {
      await _configurePassword(context, ref);
    }
    return ref.read(backupControllerProvider).asData?.value.hasPassword ??
        false;
  }

  Future<void> _restoreLatest(BuildContext context, WidgetRef ref) async {
    try {
      final file = await ref
          .read(backupControllerProvider.notifier)
          .readLatestBackup();
      if (file == null) {
        if (context.mounted) {
          AppToast.show(context, context.tr('latest_backup_not_found'));
        }
        return;
      }
      if (context.mounted) await _inspectAndRestore(context, ref, file);
    } on Object catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _chooseRestoreFile(BuildContext context, WidgetRef ref) async {
    try {
      final file = await ref
          .read(backupControllerProvider.notifier)
          .chooseBackupFile();
      if (file != null && context.mounted) {
        await _inspectAndRestore(context, ref, file);
      }
    } on Object catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _inspectAndRestore(
    BuildContext context,
    WidgetRef ref,
    BackupFileContent file,
  ) async {
    final password = await _showPasswordSheet(
      context,
      confirming: false,
      titleKey: 'enter_backup_password',
    );
    if (password == null || !context.mounted) return;

    try {
      final archive = await ref
          .read(backupControllerProvider.notifier)
          .inspectBackup(file, password);
      if (!context.mounted) return;
      final confirmed =
          await showModalBottomSheet<bool>(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) =>
                _RestorePreviewSheet(fileName: file.name, archive: archive),
          ) ??
          false;
      if (!confirmed || !context.mounted) return;
      await ref.read(backupControllerProvider.notifier).restoreBackup(archive);
      if (context.mounted) {
        AppToast.show(context, context.tr('backup_restored_successfully'));
      }
    } on Object catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<String?> _showPasswordSheet(
    BuildContext context, {
    required bool confirming,
    required String titleKey,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _BackupPasswordSheet(titleKey: titleKey, confirming: confirming),
    );
  }

  void _showError(BuildContext context, Object error) {
    if (error is PlatformException) {
      AppToast.show(
        context,
        context.trf('backup_operation_failed_with_reason', {
          'reason': error.message ?? error.code,
        }),
      );
      return;
    }
    final key = error is BackupArchiveException
        ? error.code
        : 'backup_operation_failed';
    AppToast.show(context, context.tr(key));
  }
}

class _BackupStatusCard extends StatelessWidget {
  final bool configured;
  final DateTime? lastBackupAt;

  const _BackupStatusCard({
    required this.configured,
    required this.lastBackupAt,
  });

  @override
  Widget build(BuildContext context) {
    final lastBackup = lastBackupAt == null
        ? context.tr('no_backup_yet')
        : context.trf('last_backup_value', {
            'date': DateFormatter.full(lastBackupAt!),
            'time':
                '${lastBackupAt!.hour.toString().padLeft(2, '0')}:${lastBackupAt!.minute.toString().padLeft(2, '0')}',
          });
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: configured ? AppColors.mintSurface : AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: configured ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              configured ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: configured ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    configured ? 'backup_ready' : 'backup_not_configured',
                  ),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastBackup,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _BackupSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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

class _BackupOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool showDivider;
  final VoidCallback? onTap;

  const _BackupOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.mintSurface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  actionLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: onTap == null
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.7)),
      ],
    );
  }
}

class _BackupPasswordSheet extends StatefulWidget {
  final String titleKey;
  final bool confirming;

  const _BackupPasswordSheet({
    required this.titleKey,
    required this.confirming,
  });

  @override
  State<_BackupPasswordSheet> createState() => _BackupPasswordSheetState();
}

class _BackupPasswordSheetState extends State<_BackupPasswordSheet> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;
  String? _errorKey;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetHeader(
              title: context.tr(widget.titleKey),
              icon: Icons.password_rounded,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('backup_password_recovery_warning'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _password,
              obscureText: _obscure,
              autofocus: true,
              textInputAction: widget.confirming
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: widget.confirming ? null : (_) => _submit(),
              decoration: InputDecoration(
                labelText: context.tr('backup_password'),
                hintText: context.tr('backup_password_hint'),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
            ),
            if (widget.confirming) ...[
              const SizedBox(height: 28),
              TextField(
                controller: _confirmation,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: context.tr('confirm_backup_password'),
                  hintText: context.tr('repeat_backup_password'),
                ),
              ),
            ],
            if (_errorKey != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr(_errorKey!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(
                  context.tr(widget.confirming ? 'save_password' : 'continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final password = _password.text;
    if (password.length < 8) {
      setState(() => _errorKey = 'backup_password_too_short');
      return;
    }
    if (widget.confirming && password != _confirmation.text) {
      setState(() => _errorKey = 'backup_passwords_do_not_match');
      return;
    }
    Navigator.pop(context, password);
  }
}

class _FrequencySheet extends StatelessWidget {
  final BackupFrequency selected;

  const _FrequencySheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(
            title: context.tr('backup_frequency'),
            icon: Icons.autorenew_rounded,
          ),
          const SizedBox(height: 18),
          for (final frequency in BackupFrequency.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => Navigator.pop(context, frequency),
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: frequency == selected
                        ? AppColors.mintSurface
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: frequency == selected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(frequency.labelKey),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (frequency == selected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RestorePreviewSheet extends StatelessWidget {
  final String fileName;
  final BackupArchive archive;

  const _RestorePreviewSheet({required this.fileName, required this.archive});

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(
            title: context.tr('restore_preview'),
            icon: Icons.settings_backup_restore_rounded,
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _PreviewRow(label: context.tr('backup_file'), value: fileName),
                _PreviewRow(
                  label: context.tr('backup_created_at'),
                  value: DateFormatter.full(archive.createdAt),
                ),
                _PreviewRow(
                  label: context.tr('financial_periods'),
                  value: '${archive.periodCount}',
                ),
                _PreviewRow(
                  label: context.tr('transactions'),
                  value: '${archive.transactionCount}',
                ),
                _PreviewRow(
                  label: context.tr('budget_categories'),
                  value: '${archive.categoryCount}',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('restore_replaces_current_data_warning'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.tr('cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.tr('restore')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _PreviewRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.7)),
      ],
    );
  }
}

class _WorkingIndicator extends StatefulWidget {
  final String label;

  const _WorkingIndicator({required this.label});

  @override
  State<_WorkingIndicator> createState() => _WorkingIndicatorState();
}

class _WorkingIndicatorState extends State<_WorkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.mintSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
