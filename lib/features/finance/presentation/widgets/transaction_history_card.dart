import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/formatters/rupiah_formatter.dart';
import '../../../../core/localization/app_localizations.dart';

class TransactionHistoryCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final int amount;
  final bool isIncome;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionHistoryCard({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = isIncome ? AppColors.primary : AppColors.danger;
    final sign = isIncome ? '+' : '-';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TransactionTypeIcon(isIncome: isIncome),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _TransactionHistoryMenu(
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormatter.full(date),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$sign${RupiahFormatter.format(amount)}',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
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

class _TransactionTypeIcon extends StatelessWidget {
  final bool isIncome;

  const _TransactionTypeIcon({required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.primary : AppColors.danger;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isIncome
          ? Icon(Icons.add_card_outlined, color: color)
          : Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.credit_card_outlined, color: color, size: 22),
                Positioned(
                  right: 7,
                  bottom: 7,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.4),
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: Colors.white,
                      size: 9,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TransactionHistoryMenu extends StatefulWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionHistoryMenu({required this.onEdit, required this.onDelete});

  @override
  State<_TransactionHistoryMenu> createState() =>
      _TransactionHistoryMenuState();
}

class _TransactionHistoryMenuState extends State<_TransactionHistoryMenu> {
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
              _TransactionHistoryMenuItem(
                icon: Icons.edit_outlined,
                label: context.tr('edit'),
                color: AppColors.primary,
                onTap: () {
                  _controller.close();
                  widget.onEdit();
                },
              ),
              const SizedBox(height: 4),
              _TransactionHistoryMenuItem(
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
          tooltip: context.tr('transaction_options'),
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

class _TransactionHistoryMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TransactionHistoryMenuItem({
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
