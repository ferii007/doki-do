import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/rupiah_formatter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/transaction_template.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/recurring_notification_provider.dart';
import '../providers/transaction_template_provider.dart';
import '../widgets/transaction_form/recurring_template_edit_sheet.dart';
import '../widgets/transaction_type_icon.dart';

class TransactionTemplatesScreen extends ConsumerWidget {
  const TransactionTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(transactionTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('transaction_templates'))),
      body: templatesAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (templates) {
          final quickTemplates = templates
              .where((template) => !template.isRecurring)
              .toList();
          final recurringTemplates = templates
              .where((template) => template.isRecurring)
              .toList();

          if (templates.isEmpty) {
            return _EmptyTemplatesState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (recurringTemplates.isNotEmpty) ...[
                _SectionTitle(title: context.tr('recurring_transactions')),
                const SizedBox(height: 10),
                ...recurringTemplates.map(
                  (template) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TemplateCard(template: template),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (quickTemplates.isNotEmpty) ...[
                _SectionTitle(title: context.tr('quick_templates')),
                const SizedBox(height: 10),
                ...quickTemplates.map(
                  (template) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TemplateCard(template: template),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EmptyTemplatesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.mintSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.bookmark_add_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('no_transaction_templates_yet'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('transaction_template_empty_description'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final TransactionTemplate template;

  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ended =
        template.endDate != null &&
        (!template.isActive ||
            DateTime(
              template.endDate!.year,
              template.endDate!.month,
              template.endDate!.day,
            ).isBefore(today));
    final color = template.type == TransactionType.income
        ? AppColors.secondary
        : AppColors.danger;
    final subtitle = [
      template.type == TransactionType.income
          ? context.tr('income')
          : context.tr('expense'),
      if (template.preferredCategoryName != null)
        template.preferredCategoryName!,
      if (template.dayOfMonth != null)
        context.trf('every_day_of_month', {'day': template.dayOfMonth!}),
      if (template.isRecurring)
        context.tr(ended ? 'ended' : (template.isActive ? 'active' : 'paused')),
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          TransactionTypeIcon(
            isIncome: template.type == TransactionType.income,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  RupiahFormatter.format(template.amount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: context.tr(
              template.isRecurring ? 'transaction_options' : 'delete',
            ),
            style: _actionButtonStyle(
              foreground: template.isRecurring
                  ? AppColors.primary
                  : AppColors.danger,
              background: template.isRecurring
                  ? AppColors.mintSurface
                  : AppColors.danger.withValues(alpha: 0.1),
            ),
            onPressed: () => template.isRecurring
                ? _showActions(context, ref, ended: ended)
                : _delete(context, ref),
            icon: Icon(
              template.isRecurring
                  ? Icons.more_horiz_rounded
                  : Icons.delete_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref, {
    required bool ended,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TemplateActionsSheet(
        template: template,
        ended: ended,
        onEdit: () {
          Navigator.pop(sheetContext);
          _edit(context, ref);
        },
        onToggleActive: () {
          Navigator.pop(sheetContext);
          _toggleActive(context, ref);
        },
        onEnd: () {
          Navigator.pop(sheetContext);
          _end(context, ref);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          _delete(context, ref);
        },
      ),
    );
  }

  ButtonStyle _actionButtonStyle({
    required Color foreground,
    required Color background,
  }) {
    return IconButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      minimumSize: const Size(40, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<RecurringTemplateEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecurringTemplateEditSheet(template: template),
    );
    if (result == null || !context.mounted) return;

    final permissionGranted = await ref
        .read(transactionTemplateActionProvider.notifier)
        .save(
          templateId: template.id,
          type: template.type,
          title: result.title,
          amount: result.amount,
          preferredCategoryName: result.preferredCategoryName,
          dayOfMonth: result.dayOfMonth,
          isActive: template.isActive,
          activeFromDate: result.activeFromDate,
          endDate: result.endDate,
          reminderEnabled: result.reminderEnabled,
          reminderHour: result.reminderHour,
          reminderMinute: result.reminderMinute,
        );
    if (!context.mounted) return;
    final notificationService = permissionGranted == false
        ? ref.read(recurringNotificationServiceProvider)
        : null;
    AppToast.show(
      context,
      context.tr(
        permissionGranted == false
            ? 'recurring_updated_notification_not_allowed'
            : 'recurring_transaction_updated',
      ),
      actionLabel: permissionGranted == false
          ? context.tr('open_settings')
          : null,
      onAction: notificationService == null
          ? null
          : () => notificationService.openNotificationSettings(),
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    await ref
        .read(transactionTemplateActionProvider.notifier)
        .setActive(templateId: template.id, isActive: !template.isActive);
    if (!context.mounted) return;
    AppToast.show(
      context,
      context.tr(
        template.isActive
            ? 'recurring_transaction_paused'
            : 'recurring_transaction_resumed',
      ),
    );
  }

  Future<void> _end(BuildContext context, WidgetRef ref) async {
    final today = DateTime.now();
    final endDate = today.isBefore(template.activeFromDate)
        ? template.activeFromDate
        : today;
    await ref
        .read(transactionTemplateActionProvider.notifier)
        .save(
          templateId: template.id,
          type: template.type,
          title: template.title,
          amount: template.amount,
          preferredCategoryName: template.preferredCategoryName,
          dayOfMonth: template.dayOfMonth,
          isActive: false,
          activeFromDate: template.activeFromDate,
          endDate: endDate,
          reminderEnabled: false,
          reminderHour: template.reminderHour,
          reminderMinute: template.reminderMinute,
        );
    if (!context.mounted) return;
    AppToast.show(context, context.tr('recurring_transaction_ended'));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: context.tr('delete_transaction_template'),
      message: context.trf('delete_transaction_template_message', {
        'title': template.title,
      }),
    );
    if (!confirmed) return;

    await ref
        .read(transactionTemplateActionProvider.notifier)
        .delete(template.id);
    if (!context.mounted) return;
    AppToast.show(context, context.tr('transaction_template_deleted'));
  }
}

class _TemplateActionsSheet extends StatelessWidget {
  final TransactionTemplate template;
  final bool ended;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onEnd;
  final VoidCallback onDelete;

  const _TemplateActionsSheet({
    required this.template,
    required this.ended,
    required this.onEdit,
    required this.onToggleActive,
    required this.onEnd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSheetHeader(
            title: context.tr('recurring_transaction_options'),
            icon: Icons.event_repeat_rounded,
          ),
          const SizedBox(height: 16),
          _TemplateActionTile(
            icon: Icons.edit_outlined,
            label: context.tr('edit_schedule'),
            onTap: onEdit,
          ),
          if (!ended)
            _TemplateActionTile(
              icon: template.isActive
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              label: context.tr(template.isActive ? 'pause' : 'resume'),
              onTap: onToggleActive,
            ),
          if (!ended)
            _TemplateActionTile(
              icon: Icons.event_busy_outlined,
              label: context.tr('end_schedule'),
              onTap: onEnd,
            ),
          _TemplateActionTile(
            icon: Icons.delete_outline_rounded,
            label: context.tr('delete'),
            color: AppColors.danger,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _TemplateActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _TemplateActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground, size: 21),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
