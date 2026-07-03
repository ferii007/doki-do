import 'package:flutter/material.dart';

import '../../../../../app/router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../transaction_type_icon.dart';

class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSheetHeader(
            title: context.tr('add_data'),
            icon: Icons.add_rounded,
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _ActionCard(
                leading: const TransactionTypeIcon(isIncome: true, size: 34),
                title: context.tr('income'),
                color: AppColors.secondary,
                onTap: () => _openRoute(context, AppRouter.addIncome),
              ),
              _ActionCard(
                leading: const TransactionTypeIcon(isIncome: false, size: 34),
                title: context.tr('expense'),
                color: AppColors.danger,
                onTap: () => _openRoute(context, AppRouter.addExpense),
              ),
              _ActionCard(
                icon: Icons.account_balance_wallet_outlined,
                title: context.tr('budget_categories'),
                color: AppColors.primary,
                onTap: () => _openRoute(context, AppRouter.addCategory),
              ),
              _ActionCard(
                icon: Icons.date_range_rounded,
                title: context.tr('new_period'),
                color: AppColors.warning,
                onTap: () => _openRoute(context, AppRouter.addPeriod),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRoute(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    this.icon,
    this.leading,
    required this.title,
    required this.color,
    required this.onTap,
  }) : assert(icon != null || leading != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            leading ??
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
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
