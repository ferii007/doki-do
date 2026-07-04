import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../finance/domain/entities/transaction_type.dart';
import '../../../finance/domain/services/recurring_notification_draft_resolver.dart';
import '../../../finance/presentation/providers/finance_repository_provider.dart';
import '../../../finance/presentation/providers/selected_period_provider.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../../domain/app_notification_item.dart';
import '../notification_text_resolver.dart';
import '../providers/notification_inbox_provider.dart';

enum _NotificationFilter { all, unread }

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationInboxProvider);
    final settings =
        ref.watch(appSettingsProvider).asData?.value ?? AppSettings.defaults();
    final resolver = NotificationTextResolver(
      localizations: context.l10n,
      currency: settings.currency,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notifications')),
        actions: [
          TextButton(
            onPressed:
                (notificationsAsync.asData?.value.any((item) => !item.isRead) ??
                    false)
                ? () =>
                      ref.read(notificationInboxProvider.notifier).markAllRead()
                : null,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
            ),
            child: Text(context.tr('mark_all_as_read')),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const _NotificationSkeleton(),
        error: (error, _) => Center(
          child: Text(
            context.tr('notifications_could_not_be_loaded'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        data: (allItems) {
          final items = _filter == _NotificationFilter.unread
              ? allItems.where((item) => !item.isRead).toList()
              : allItems;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: _FilterControl(
                  selected: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _EmptyNotifications(filter: _filter)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: _buildGroups(items, resolver),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildGroups(
    List<AppNotificationItem> items,
    NotificationTextResolver resolver,
  ) {
    final groups = <String, List<AppNotificationItem>>{};
    for (final item in items) {
      groups.putIfAbsent(_dateGroupKey(item.createdAt), () => []).add(item);
    }

    return [
      for (final entry in groups.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Text(
            _dateGroupLabel(entry.value.first.createdAt),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        for (final item in entry.value)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NotificationCard(
              item: item,
              resolver: resolver,
              onTap: () => _openItem(item),
              onDelete: () => _deleteItem(item),
            ),
          ),
      ],
    ];
  }

  String _dateGroupKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  String _dateGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(date.year, date.month, date.day);
    final difference = today.difference(value).inDays;
    if (difference == 0) return context.tr('today');
    if (difference == 1) return context.tr('yesterday');
    return DateFormatter.full(date);
  }

  Future<void> _openItem(AppNotificationItem item) async {
    await ref.read(notificationInboxProvider.notifier).markRead(item.id);
    if (!mounted) return;

    switch (item.category) {
      case AppNotificationCategory.recurring:
        final templateId = item.data['template_id'] as String?;
        final dueDate = DateTime.tryParse(
          item.data['due_date'] as String? ?? '',
        );
        if (templateId == null || dueDate == null) return;
        final repository = ref.read(financeRepositoryProvider);
        final draft = RecurringNotificationDraftResolver.resolve(
          templateId: templateId,
          dueDate: dueDate,
          templates: await repository.getTransactionTemplates(),
          occurrences: await repository.getRecurringOccurrences(),
        );
        if (draft == null || !mounted) return;
        await Navigator.pushNamed(
          context,
          draft.template.type == TransactionType.income
              ? AppRouter.addIncome
              : AppRouter.addExpense,
          arguments: draft,
        );
      case AppNotificationCategory.budget:
        final periodId = item.data['period_id'] as String?;
        final categoryId = item.data['category_id'] as String?;
        if (periodId == null || categoryId == null) return;
        ref.read(selectedPeriodIdProvider.notifier).select(periodId);
        await Navigator.pushNamed(
          context,
          AppRouter.categoryDetail,
          arguments: categoryId,
        );
      case AppNotificationCategory.backup:
        await Navigator.pushNamed(context, AppRouter.localBackup);
      case AppNotificationCategory.period:
        final periodId = item.data['period_id'] as String?;
        if (periodId == null) return;
        ref.read(selectedPeriodIdProvider.notifier).select(periodId);
        if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteItem(AppNotificationItem item) async {
    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: context.tr('delete_notification'),
      message: context.tr('delete_notification_description'),
    );
    if (!confirmed) return;
    await ref.read(notificationInboxProvider.notifier).delete(item.id);
  }
}

class _FilterControl extends StatelessWidget {
  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onChanged;

  const _FilterControl({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          for (final filter in _NotificationFilter.values)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(filter),
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == filter
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    context.tr(
                      filter == _NotificationFilter.all ? 'all' : 'unread',
                    ),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected == filter
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationItem item;
  final NotificationTextResolver resolver;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.item,
    required this.resolver,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _NotificationVisual.from(item.category);
    return InkWell(
      onTap: onTap,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: item.isRead ? 0.72 : 1,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? AppColors.border
                  : visual.color.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(visual.icon, color: visual.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            resolver.title(item),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.createdAt.hour.toString().padLeft(2, '0')}:'
                          '${item.createdAt.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          tooltip: context.tr('delete'),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      resolver.body(item),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: Text(resolver.actionLabel(item)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationVisual {
  final IconData icon;
  final Color color;

  const _NotificationVisual({required this.icon, required this.color});

  factory _NotificationVisual.from(AppNotificationCategory category) {
    return switch (category) {
      AppNotificationCategory.recurring => _NotificationVisual(
        icon: Icons.sync_rounded,
        color: AppColors.primary,
      ),
      AppNotificationCategory.budget => _NotificationVisual(
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.danger,
      ),
      AppNotificationCategory.backup => _NotificationVisual(
        icon: Icons.cloud_off_rounded,
        color: AppColors.warning,
      ),
      AppNotificationCategory.period => _NotificationVisual(
        icon: Icons.calendar_month_rounded,
        color: AppColors.textSecondary,
      ),
    };
  }
}

class _EmptyNotifications extends StatelessWidget {
  final _NotificationFilter filter;

  const _EmptyNotifications({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(
                filter == _NotificationFilter.unread
                    ? 'no_unread_notifications'
                    : 'no_notifications_yet',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        height: 132,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }
}
