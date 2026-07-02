import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/amount_text.dart';
import '../../../domain/entities/category_budget.dart';

class CategoryBalanceHeader extends StatelessWidget {
  final CategoryBudget category;

  const CategoryBalanceHeader({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              category.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('remaining_money'),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
            ),
            const SizedBox(height: 4),
            AmountText(
              amount: category.remainingAmount,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
              negativeColor: const Color(0xFFFFD6D6),
            ),
          ],
        ),
      ),
    );
  }
}
