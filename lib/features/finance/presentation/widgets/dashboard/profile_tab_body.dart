import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/app_info/app_version_provider.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/amount_text.dart';
import '../../../../../core/widgets/loading_view.dart';
import '../../../../settings/presentation/providers/app_settings_provider.dart';
import '../../../domain/entities/budget_snapshot.dart';
import '../../providers/current_budget_provider.dart';
import '../transaction_type_icon.dart';

class ProfileTabBody extends ConsumerWidget {
  final BudgetSnapshot? currentSnapshot;

  const ProfileTabBody({super.key, required this.currentSnapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = ref.watch(allBudgetSnapshotsProvider);
    final settings = ref.watch(appSettingsProvider).asData?.value;
    final version = ref.watch(appVersionProvider).asData?.value ?? '-';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: snapshotsAsync.when(
        loading: () => const LoadingView(padding: EdgeInsets.zero),
        error: (error, _) => _ProfileErrorCard(message: error.toString()),
        data: (snapshots) {
          final totalIncome = snapshots.fold<int>(
            0,
            (total, snapshot) => total + snapshot.period.totalIncome,
          );
          final totalExpense = snapshots.fold<int>(
            0,
            (total, snapshot) => total + snapshot.totalExpense,
          );
          final activeBudgetCount = currentSnapshot?.categories.length ?? 0;
          final remaining = currentSnapshot == null
              ? 0
              : currentSnapshot!.period.totalIncome -
                    currentSnapshot!.totalExpense;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(
                displayName: settings?.displayName ?? context.tr('dokido_user'),
              ),
              const SizedBox(height: 16),
              _ProfileSummaryGrid(
                periodCount: snapshots.length,
                activeBudgetCount: activeBudgetCount,
                totalIncome: totalIncome,
                totalExpense: totalExpense,
              ),
              const SizedBox(height: 16),
              _ProfileStatusCard(remaining: remaining),
              const SizedBox(height: 16),
              _ProfileMenuCard(
                children: [
                  _ProfileMenuRow(
                    icon: Icons.settings_outlined,
                    title: context.tr('settings'),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.settings),
                  ),
                  _ProfileMenuRow(
                    icon: Icons.info_outline_rounded,
                    title: context.tr('general_info'),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.generalInfo),
                  ),
                  _ProfileMenuRow(
                    icon: Icons.apps_rounded,
                    title: context.tr('version'),
                    value: version,
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  context.tr('powered_by_niskala'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileMenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.78)),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool showDivider;

  const _ProfileMenuRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.mintSurface,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (value != null)
                  Text(
                    value!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.7)),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;

  const _ProfileHeader({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(alpha: 0.045),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('financial_profile'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryGrid extends StatelessWidget {
  final int periodCount;
  final int activeBudgetCount;
  final int totalIncome;
  final int totalExpense;

  const _ProfileSummaryGrid({
    required this.periodCount,
    required this.activeBudgetCount,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.28,
      ),
      children: [
        _ProfileMetricCard(
          icon: Icons.calendar_month_rounded,
          label: context.tr('recorded_periods'),
          value: '$periodCount',
          tint: AppColors.primary,
        ),
        _ProfileMetricCard(
          icon: Icons.account_balance_wallet_rounded,
          label: context.tr('active_categories'),
          value: '$activeBudgetCount',
          tint: AppColors.secondary,
        ),
        _ProfileAmountMetricCard(
          leading: const TransactionTypeIcon(isIncome: true, size: 34),
          label: context.tr('income'),
          amount: totalIncome,
          tint: AppColors.success,
        ),
        _ProfileAmountMetricCard(
          leading: const TransactionTypeIcon(isIncome: false, size: 34),
          label: context.tr('expense'),
          amount: totalExpense,
          tint: AppColors.danger,
        ),
      ],
    );
  }
}

class _ProfileMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  const _ProfileMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MetricIcon(icon: icon, tint: tint),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAmountMetricCard extends StatelessWidget {
  final Widget leading;
  final String label;
  final int amount;
  final Color tint;

  const _ProfileAmountMetricCard({
    required this.leading,
    required this.label,
    required this.amount,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          leading,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountText(
                amount: amount,
                highlightNegative: false,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStatusCard extends StatelessWidget {
  final int remaining;

  const _ProfileStatusCard({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final isHealthy = remaining >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHealthy
            ? AppColors.primary.withValues(alpha: 0.09)
            : AppColors.danger.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isHealthy ? AppColors.primary : AppColors.danger).withValues(
            alpha: 0.16,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isHealthy ? Icons.verified_rounded : Icons.warning_amber_rounded,
              color: isHealthy ? AppColors.primary : AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy
                      ? context.tr('this_period_is_still_on_track')
                      : context.tr('this_period_needs_attention'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                AmountText(
                  amount: remaining,
                  highlightNegative: false,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const _MetricIcon({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: tint, size: 19),
    );
  }
}

class _ProfileErrorCard extends StatelessWidget {
  final String message;

  const _ProfileErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
