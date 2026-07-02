import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';

class TransactionTemplateSaveOptions extends StatelessWidget {
  final bool saveAsTemplate;
  final bool saveAsRecurring;
  final int recurringDay;
  final ValueChanged<bool> onTemplateChanged;
  final ValueChanged<bool> onRecurringChanged;

  const TransactionTemplateSaveOptions({
    super.key,
    required this.saveAsTemplate,
    required this.saveAsRecurring,
    required this.recurringDay,
    required this.onTemplateChanged,
    required this.onRecurringChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OptionTile(
          icon: Icons.bookmark_add_rounded,
          title: context.tr('save_as_template'),
          subtitle: context.tr('save_as_template_description'),
          selected: saveAsTemplate,
          onTap: () => onTemplateChanged(!saveAsTemplate),
        ),
        const SizedBox(height: 10),
        _OptionTile(
          icon: Icons.event_repeat_rounded,
          title: context.tr('make_recurring'),
          subtitle: context.trf('make_recurring_description', {
            'day': recurringDay,
          }),
          selected: saveAsRecurring,
          onTap: () => onRecurringChanged(!saveAsRecurring),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.mintSurface.withValues(alpha: 0.9)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.38)
                : AppColors.border.withValues(alpha: 0.8),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.mintSurface,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                selected ? Icons.check_rounded : icon,
                color: selected ? Colors.white : AppColors.primary,
                size: 21,
              ),
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
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
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
