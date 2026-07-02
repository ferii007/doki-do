import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/rupiah_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/amount_text.dart';
import '../../../domain/entities/category_budget.dart';

class BudgetCategoryCard extends StatelessWidget {
  final CategoryBudget category;
  final int transactionCount;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onSetAmount;
  final VoidCallback onDelete;

  const BudgetCategoryCard({
    super.key,
    required this.category,
    required this.transactionCount,
    required this.canDelete,
    required this.onTap,
    required this.onEdit,
    required this.onIncrease,
    required this.onDecrease,
    required this.onSetAmount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final usedAmount = category.allocatedAmount - category.remainingAmount;
    final progress = category.allocatedAmount <= 0
        ? 0.0
        : (usedAmount / category.allocatedAmount).clamp(0.0, 1.0);
    final isWarning = progress >= 0.9 || category.remainingAmount < 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BudgetCategoryTitle(
                          name: category.name,
                          allocationPercent: category.allocationPercent,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.l10n.expenseRecordCount(transactionCount),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _BudgetActionMenu(
                    canDelete: canDelete,
                    onEdit: onEdit,
                    onIncrease: onIncrease,
                    onDecrease: onDecrease,
                    onSetAmount: onSetAmount,
                    onDelete: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  color: isWarning ? AppColors.danger : AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _BudgetValueBlock(
                      label: context.tr('budget_limit'),
                      child: Text(
                        RupiahFormatter.format(category.allocatedAmount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: _BudgetValueBlock(
                      label: context.tr('remaining_money'),
                      child: AmountText(
                        amount: category.remainingAmount,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCategoryTitle extends StatelessWidget {
  final String name;
  final double? allocationPercent;

  const _BudgetCategoryTitle({
    required this.name,
    required this.allocationPercent,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w900,
    );
    final percent = allocationPercent;

    if (percent == null) {
      return Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: titleStyle,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${_formatPercent(percent)}%',
            style: titleStyle?.copyWith(color: AppColors.primary),
          ),
          const TextSpan(text: ' | '),
          TextSpan(text: name),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
    );
  }

  String _formatPercent(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }
}

class _BudgetActionMenu extends StatefulWidget {
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onSetAmount;
  final VoidCallback onDelete;

  const _BudgetActionMenu({
    required this.canDelete,
    required this.onEdit,
    required this.onIncrease,
    required this.onDecrease,
    required this.onSetAmount,
    required this.onDelete,
  });

  @override
  State<_BudgetActionMenu> createState() => _BudgetActionMenuState();
}

class _BudgetActionMenuState extends State<_BudgetActionMenu> {
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
        _BudgetActionMenuCard(
          canDelete: widget.canDelete,
          onEdit: () {
            _controller.close();
            widget.onEdit();
          },
          onIncrease: () {
            _controller.close();
            widget.onIncrease();
          },
          onDecrease: () {
            _controller.close();
            widget.onDecrease();
          },
          onSetAmount: () {
            _controller.close();
            widget.onSetAmount();
          },
          onDelete: () {
            _controller.close();
            widget.onDelete();
          },
        ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: context.tr('budget_category_options'),
          onPressed: () {
            controller.isOpen ? controller.close() : controller.open();
          },
          icon: const Icon(Icons.more_horiz_rounded),
          color: AppColors.primary,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.mint.withValues(alpha: 0.34),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}

class _BudgetActionMenuCard extends StatelessWidget {
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onSetAmount;
  final VoidCallback onDelete;

  const _BudgetActionMenuCard({
    required this.canDelete,
    required this.onEdit,
    required this.onIncrease,
    required this.onDecrease,
    required this.onSetAmount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 216,
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
          _BudgetActionMenuItem(
            icon: Icons.edit_outlined,
            label: context.tr('edit'),
            color: AppColors.primary,
            onTap: onEdit,
          ),
          const SizedBox(height: 4),
          _BudgetActionMenuItem(
            icon: Icons.add_card_outlined,
            label: context.tr('add_budget_amount'),
            color: AppColors.primary,
            onTap: onIncrease,
          ),
          const SizedBox(height: 4),
          _BudgetActionMenuItem(
            icon: Icons.remove_circle_outline,
            label: context.tr('reduce_budget_amount'),
            color: AppColors.danger,
            onTap: onDecrease,
          ),
          const SizedBox(height: 4),
          _BudgetActionMenuItem(
            icon: Icons.tune_rounded,
            label: context.tr('set_budget_amount'),
            color: AppColors.textSecondary,
            onTap: onSetAmount,
          ),
          const SizedBox(height: 4),
          _BudgetActionMenuItem(
            icon: Icons.delete_outline,
            label: context.tr('delete'),
            color: AppColors.danger,
            opacity: canDelete ? 1 : 0.45,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _BudgetActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double opacity;
  final VoidCallback onTap;

  const _BudgetActionMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    this.opacity = 1,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Opacity(
          opacity: opacity,
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
      ),
    );
  }
}

class _BudgetValueBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _BudgetValueBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
