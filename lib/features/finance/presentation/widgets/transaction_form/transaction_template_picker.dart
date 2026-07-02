import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/rupiah_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../domain/entities/transaction_template.dart';
import '../../../domain/entities/transaction_type.dart';

class TransactionTemplatePicker extends StatelessWidget {
  final List<TransactionTemplate> templates;
  final TransactionType type;
  final ValueChanged<TransactionTemplate> onSelected;

  const TransactionTemplatePicker({
    super.key,
    required this.templates,
    required this.type,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = templates
        .where((template) => template.type == type)
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('use_template'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final template = filtered[index];
              return _TemplateChipCard(
                template: template,
                onTap: () => onSelected(template),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TemplateChipCard extends StatelessWidget {
  final TransactionTemplate template;
  final VoidCallback onTap;

  const _TemplateChipCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = template.type == TransactionType.income
        ? AppColors.secondary
        : AppColors.danger;
    final subtitle = template.isRecurring
        ? context.trf('every_day_of_month', {'day': template.dayOfMonth!})
        : context.tr('quick_template');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 196,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlay.withValues(alpha: 0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                template.type == TransactionType.income
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    template.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    RupiahFormatter.format(template.amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
