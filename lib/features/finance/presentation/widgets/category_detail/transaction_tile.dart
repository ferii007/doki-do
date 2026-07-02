import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/formatters/rupiah_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../domain/entities/transaction_item.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem transaction;
  final String? title;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.title,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ExpenseCardIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title ?? transaction.title,
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
                      _TransactionActionMenu(
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          DateFormatter.full(transaction.date),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '-${RupiahFormatter.format(transaction.amount)}',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger,
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

class _ExpenseCardIcon extends StatelessWidget {
  const _ExpenseCardIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.credit_card_outlined, color: AppColors.danger, size: 22),
          Positioned(
            right: 7,
            bottom: 7,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: const Icon(Icons.remove, color: Colors.white, size: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionActionMenu extends StatefulWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionActionMenu({required this.onEdit, required this.onDelete});

  @override
  State<_TransactionActionMenu> createState() => _TransactionActionMenuState();
}

class _TransactionActionMenuState extends State<_TransactionActionMenu> {
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
        _TransactionActionMenuCard(
          onEdit: () {
            _controller.close();
            widget.onEdit();
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
          tooltip: context.tr('expense_options'),
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

class _TransactionActionMenuCard extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TransactionActionMenuCard({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _TransactionActionMenuItem(
            icon: Icons.edit_outlined,
            label: context.tr('edit'),
            color: AppColors.primary,
            onTap: onEdit,
          ),
          const SizedBox(height: 4),
          _TransactionActionMenuItem(
            icon: Icons.delete_outline,
            label: context.tr('delete'),
            color: AppColors.danger,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _TransactionActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TransactionActionMenuItem({
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
