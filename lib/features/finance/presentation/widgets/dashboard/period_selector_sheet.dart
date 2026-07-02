import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('choose_financial_period'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: periods.length,
                separatorBuilder: (_, _) => Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 1,
                ),
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
            const SizedBox(height: 12),
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
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            if (selected)
              Icon(Icons.check_circle, color: AppColors.secondary)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.white.withValues(alpha: 0.32),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                DateFormatter.periodFull(period.startDate, period.endDate),
                style: TextStyle(
                  color: Colors.white,
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
          color: Colors.white,
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
