import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../domain/entities/budget_period.dart';

class PeriodSelectorSheet extends StatelessWidget {
  final List<BudgetPeriod> periods;
  final String selectedPeriodId;
  final ValueChanged<String> onSelect;
  final ValueChanged<BudgetPeriod> onEditPeriod;
  final ValueChanged<BudgetPeriod> onDeletePeriod;
  final VoidCallback onAddPeriod;
  final bool isAdding;

  const PeriodSelectorSheet({
    super.key,
    required this.periods,
    required this.selectedPeriodId,
    required this.onSelect,
    required this.onEditPeriod,
    required this.onDeletePeriod,
    required this.onAddPeriod,
    required this.isAdding,
  });

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSheetHeader(
            title: context.tr('choose_financial_period'),
            icon: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: periods.length,
              separatorBuilder: (_, _) =>
                  Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final period = periods[index];
                final selected = period.id == selectedPeriodId;

                return _PeriodOptionTile(
                  period: period,
                  selected: selected,
                  onSelect: () => onSelect(period.id),
                  onEdit: () => onEditPeriod(period),
                  onDelete: () => onDeletePeriod(period),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isAdding ? null : onAddPeriod,
              icon: const Icon(Icons.add),
              label: Text(
                context.tr(isAdding ? 'adding' : 'add_financial_period'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodOptionTile extends StatelessWidget {
  final BudgetPeriod period;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PeriodOptionTile({
    required this.period,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (selected)
              Icon(Icons.check_circle, color: AppColors.primary)
            else
              Icon(Icons.radio_button_unchecked, color: AppColors.border),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                DateFormatter.periodFull(period.startDate, period.endDate),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PeriodActionMenu(onEdit: onEdit, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _PeriodActionMenu extends StatefulWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PeriodActionMenu({required this.onEdit, required this.onDelete});

  @override
  State<_PeriodActionMenu> createState() => _PeriodActionMenuState();
}

class _PeriodActionMenuState extends State<_PeriodActionMenu> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(-144, 4),
      style: const MenuStyle(
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      menuChildren: [
        Container(
          width: 176,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.overlay.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PeriodActionItem(
                icon: Icons.edit_outlined,
                label: context.tr('edit'),
                color: AppColors.primary,
                onTap: () {
                  _controller.close();
                  widget.onEdit();
                },
              ),
              const SizedBox(height: 4),
              _PeriodActionItem(
                icon: Icons.delete_outline,
                label: context.tr('delete'),
                color: AppColors.danger,
                onTap: () {
                  _controller.close();
                  widget.onDelete();
                },
              ),
            ],
          ),
        ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: context.tr('period_options'),
          onPressed: () {
            controller.isOpen ? controller.close() : controller.open();
          },
          icon: const Icon(Icons.more_horiz_rounded),
          color: AppColors.primary,
          style: IconButton.styleFrom(backgroundColor: AppColors.mintSurface),
        );
      },
    );
  }
}

class _PeriodActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PeriodActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
