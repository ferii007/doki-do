import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/rupiah_formatter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/delete_confirmation_dialog.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/transaction_template.dart';
import '../../domain/entities/transaction_type.dart';
import '../providers/transaction_template_provider.dart';
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
            tooltip: context.tr('delete'),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.danger.withValues(alpha: 0.1),
              foregroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
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
