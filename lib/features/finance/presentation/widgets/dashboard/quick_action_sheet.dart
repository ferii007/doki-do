import 'package:flutter/material.dart';

import '../../../../../app/router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';

class QuickActionSheet extends StatelessWidget {
  const QuickActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
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
              context.tr('add_data'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _ActionCard(
                  icon: Icons.trending_up_rounded,
                  title: context.tr('income'),
                  color: AppColors.secondary,
                  onTap: () => _openRoute(context, AppRouter.addIncome),
                ),
                _ActionCard(
                  icon: Icons.trending_down_rounded,
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
      ),
    );
  }

  void _openRoute(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.92),
              AppColors.mintSurface.withValues(alpha: 0.86),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlay.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
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
