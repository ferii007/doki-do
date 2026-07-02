import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/amount_text.dart';
import '../../../domain/entities/budget_period.dart';

class PeriodSummaryCard extends StatelessWidget {
  final BudgetPeriod period;
  final int totalExpense;
  final VoidCallback? onPeriodTap;
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;

  const PeriodSummaryCard({
    super.key,
    required this.period,
    required this.totalExpense,
    this.onPeriodTap,
    this.onIncomeTap,
    this.onExpenseTap,
  });

  @override
  Widget build(BuildContext context) {
    final allocatableAmount = period.totalIncome - totalExpense;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    );
    final amountStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
    );
    final compactAmountStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('financial_period'),
                    style: titleStyle,
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onPeriodTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormatter.periodFull(
                          period.startDate,
                          period.endDate,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _SummaryMetric(
              label: context.tr('remaining_money_this_period'),
              amount: allocatableAmount,
              amountStyle: amountStyle,
              icon: Icons.savings_outlined,
              iconSize: 22,
              accentColor: AppColors.primary,
              borderColor: AppColors.primary,
              negativeAmountColor: const Color(0xFFFFD6D6),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: context.tr('income'),
                    amount: period.totalIncome,
                    amountStyle: compactAmountStyle,
                    icon: Icons.trending_up_rounded,
                    accentColor: AppColors.secondary,
                    onTap: onIncomeTap,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: context.tr('expense'),
                    amount: totalExpense,
                    amountStyle: compactAmountStyle,
                    icon: Icons.trending_down_rounded,
                    accentColor: AppColors.danger,
                    borderColor: AppColors.secondary,
                    onTap: onExpenseTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final int amount;
  final TextStyle? amountStyle;
  final IconData icon;
  final double iconSize;
  final Color? accentColor;
  final Color? borderColor;
  final Color? negativeAmountColor;
  final VoidCallback? onTap;

  const _SummaryMetric({
    required this.label,
    required this.amount,
    required this.amountStyle,
    required this.icon,
    this.iconSize = 18,
    this.accentColor,
    this.borderColor,
    this.negativeAmountColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Colors.white;
    final border = borderColor ?? accent;
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: iconSize, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AmountText(
            amount: amount,
            style: amountStyle,
            negativeColor: negativeAmountColor,
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: content,
    );
  }
}
