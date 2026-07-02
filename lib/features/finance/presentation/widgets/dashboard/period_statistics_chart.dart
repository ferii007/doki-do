import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/formatters/rupiah_formatter.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../domain/entities/budget_snapshot.dart';
import '../../../domain/entities/transaction_type.dart';

enum _ChartMode { line, bar }

const _maxXAxisLabels = 6;

class PeriodStatisticsChart extends StatefulWidget {
  final List<BudgetSnapshot> snapshots;

  const PeriodStatisticsChart({super.key, required this.snapshots});

  @override
  State<PeriodStatisticsChart> createState() => _PeriodStatisticsChartState();
}

class _PeriodStatisticsChartState extends State<PeriodStatisticsChart> {
  _ChartMode _mode = _ChartMode.line;

  @override
  Widget build(BuildContext context) {
    final snapshots = [...widget.snapshots]
      ..sort((a, b) => a.period.startDate.compareTo(b.period.startDate));
    final hasFinancialData = snapshots.any(
      (snapshot) =>
          snapshot.period.totalIncome > 0 || snapshot.totalExpense > 0,
    );
    final isEmpty = snapshots.isEmpty || !hasFinancialData;
    final maxY = _maxAmount(snapshots);

    return _ChartSection(
      accentColor: AppColors.primary,
      title: context.tr('financial_statistics'),
      subtitle: isEmpty
          ? context.tr('no_financial_data_yet')
          : context.l10n.periodCount(snapshots.length),
      mode: _mode,
      onModeTap: _showChartModeSheet,
      child: isEmpty
          ? _ChartEmptyState(
              accentColor: AppColors.primary,
              title: context.tr('no_financial_data_yet'),
              description: context.tr(
                'create_a_financial_period_first_the_summary_will_appear_here',
              ),
            )
          : Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 260,
                  child: _mode == _ChartMode.line
                      ? snapshots.length == 1
                            ? _SingleFinancePointChart(
                                snapshot: snapshots.first,
                              )
                            : _LineFinanceChart(
                                snapshots: snapshots,
                                maxY: maxY,
                              )
                      : _BarFinanceChart(snapshots: snapshots, maxY: maxY),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Center(child: _Legend()),
                ),
              ],
            ),
    );
  }

  double _maxAmount(List<BudgetSnapshot> snapshots) {
    final max = snapshots.fold<int>(1, (currentMax, snapshot) {
      final values = [snapshot.period.totalIncome, snapshot.totalExpense];
      final localMax = values.fold<int>(
        currentMax,
        (innerMax, value) => value > innerMax ? value : innerMax,
      );
      return localMax > currentMax ? localMax : currentMax;
    });

    return (max * 1.15).toDouble();
  }

  void _showChartModeSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
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
                  context.tr('choose_chart_type'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _ChartModeOption(
                  selected: _mode == _ChartMode.line,
                  icon: Icons.show_chart,
                  label: context.tr('line_chart'),
                  onTap: () {
                    setState(() => _mode = _ChartMode.line);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                _ChartModeOption(
                  selected: _mode == _ChartMode.bar,
                  icon: Icons.bar_chart_rounded,
                  label: context.tr('column_chart'),
                  onTap: () {
                    setState(() => _mode = _ChartMode.bar);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ExpenseStatisticsChart extends StatefulWidget {
  final BudgetSnapshot snapshot;

  const ExpenseStatisticsChart({super.key, required this.snapshot});

  @override
  State<ExpenseStatisticsChart> createState() => _ExpenseStatisticsChartState();
}

class _ExpenseStatisticsChartState extends State<ExpenseStatisticsChart> {
  _ChartMode _mode = _ChartMode.line;

  @override
  Widget build(BuildContext context) {
    final points = _expensePoints(widget.snapshot);
    final isEmpty = points.isEmpty;
    final minY = isEmpty ? 0.0 : _minExpenseAmount(points);
    final maxY = isEmpty ? 1.0 : _maxExpenseAmount(points);

    return _ChartSection(
      accentColor: AppColors.danger,
      title: context.tr('expense_statistics'),
      subtitle: DateFormatter.periodFull(
        widget.snapshot.period.startDate,
        widget.snapshot.period.endDate,
      ),
      mode: _mode,
      onModeTap: _showChartModeSheet,
      child: isEmpty
          ? _ChartEmptyState(
              accentColor: AppColors.danger,
              title: context.tr('no_expenses_yet'),
              description: context.tr(
                'expense_records_in_this_period_will_appear_here',
              ),
            )
          : SizedBox(
              height: 240,
              width: double.infinity,
              child: _mode == _ChartMode.line
                  ? points.length == 1
                        ? _SingleExpensePointChart(point: points.first)
                        : _ExpenseLineChart(
                            points: points,
                            minY: minY,
                            maxY: maxY,
                          )
                  : _ExpenseBarChart(points: points, minY: minY, maxY: maxY),
            ),
    );
  }

  List<_ExpenseChartPoint> _expensePoints(BudgetSnapshot snapshot) {
    final dailyTotals = <DateTime, int>{};

    for (final transaction in snapshot.transactions) {
      if (transaction.type != TransactionType.expense) continue;

      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyTotals.update(
        date,
        (amount) => amount + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final points =
        dailyTotals.entries
            .map(
              (entry) =>
                  _ExpenseChartPoint(date: entry.key, amount: entry.value),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return points;
  }

  double _minExpenseAmount(List<_ExpenseChartPoint> points) {
    if (points.isEmpty) return 0;

    final min = points
        .map((point) => point.amount)
        .reduce((a, b) => a < b ? a : b);
    final max = points
        .map((point) => point.amount)
        .reduce((a, b) => a > b ? a : b);

    if (min == max) {
      return min == 0 ? 0 : (min * 0.9).toDouble();
    }

    final padding = (max - min) * 0.14;
    return (min - padding).clamp(0, double.infinity).toDouble();
  }

  double _maxExpenseAmount(List<_ExpenseChartPoint> points) {
    if (points.isEmpty) return 1;

    final min = points
        .map((point) => point.amount)
        .reduce((a, b) => a < b ? a : b);
    final max = points
        .map((point) => point.amount)
        .reduce((a, b) => a > b ? a : b);

    if (min == max) {
      return max == 0 ? 1 : (max * 1.1).toDouble();
    }

    return (max + ((max - min) * 0.14)).toDouble();
  }

  void _showChartModeSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
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
                  context.tr('choose_chart_type'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _ChartModeOption(
                  selected: _mode == _ChartMode.line,
                  icon: Icons.show_chart,
                  label: context.tr('line_chart'),
                  onTap: () {
                    setState(() => _mode = _ChartMode.line);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                _ChartModeOption(
                  selected: _mode == _ChartMode.bar,
                  icon: Icons.bar_chart_rounded,
                  label: context.tr('column_chart'),
                  onTap: () {
                    setState(() => _mode = _ChartMode.bar);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChartSection extends StatelessWidget {
  final Color accentColor;
  final String title;
  final String subtitle;
  final _ChartMode mode;
  final VoidCallback onModeTap;
  final Widget child;

  const _ChartSection({
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.onModeTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.72),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withValues(alpha: 0.16),
                  AppColors.cream.withValues(alpha: 0.42),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              border: Border(
                bottom: BorderSide(
                  color: accentColor.withValues(alpha: 0.16),
                  width: 1.2,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accentColor, AppColors.mint],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ChartModeButton(
                  accentColor: accentColor,
                  mode: mode,
                  onTap: onModeTap,
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  final Color accentColor;
  final String title;
  final String description;

  const _ChartEmptyState({
    required this.accentColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: accentColor.withValues(alpha: 0.08)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(Icons.insights_rounded, color: accentColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartModeButton extends StatelessWidget {
  final Color accentColor;
  final _ChartMode mode;
  final VoidCallback onTap;

  const _ChartModeButton({
    required this.accentColor,
    required this.mode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.22)),
        ),
        child: Icon(
          mode == _ChartMode.line ? Icons.show_chart : Icons.bar_chart_rounded,
          color: accentColor,
        ),
      ),
    );
  }
}

class _ChartModeOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChartModeOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.secondary
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}

class _LineFinanceChart extends StatelessWidget {
  final List<BudgetSnapshot> snapshots;
  final double maxY;

  const _LineFinanceChart({required this.snapshots, required this.maxY});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: _gridData(),
        borderData: _borderData(),
        titlesData: _titlesData(context, snapshots),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchSpotThreshold: double.infinity,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: barData.color ?? AppColors.primary,
                  strokeWidth: 2,
                ),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: barData.color ?? AppColors.primary,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipBorder: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.28),
            ),
            tooltipPadding: const EdgeInsets.all(10),
            tooltipMargin: 8,
            maxContentWidth: 190,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              return spots.asMap().entries.map((entry) {
                final tooltipIndex = entry.key;
                final spot = entry.value;
                final snapshot = snapshots[spot.x.toInt()];
                final icon = spot.barIndex == 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded;
                final color = spot.barIndex == 0
                    ? AppColors.secondary
                    : AppColors.danger;

                return LineTooltipItem(
                  '',
                  const TextStyle(),
                  textAlign: TextAlign.left,
                  children: [
                    if (tooltipIndex == 0)
                      TextSpan(
                        text:
                            '${DateFormatter.period(snapshot.period.startDate, snapshot.period.endDate)}\n',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    TextSpan(
                      text: String.fromCharCode(icon.codePoint),
                      style: TextStyle(
                        color: color,
                        fontFamily: icon.fontFamily,
                        package: icon.fontPackage,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: ' ${RupiahFormatter.format(spot.y.toInt())}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          _lineBar(
            snapshots: snapshots,
            valueOf: (snapshot) => snapshot.period.totalIncome,
            color: AppColors.secondary,
          ),
          _lineBar(
            snapshots: snapshots,
            valueOf: (snapshot) => snapshot.totalExpense,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineBar({
    required List<BudgetSnapshot> snapshots,
    required int Function(BudgetSnapshot snapshot) valueOf,
    required Color color,
  }) {
    return LineChartBarData(
      isCurved: true,
      preventCurveOverShooting: true,
      isStrokeCapRound: true,
      barWidth: 3,
      color: color,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.42),
            color.withValues(alpha: 0.12),
          ],
        ),
      ),
      spots: [
        for (var i = 0; i < snapshots.length; i++)
          FlSpot(i.toDouble(), valueOf(snapshots[i]).toDouble()),
      ],
    );
  }
}

class _BarFinanceChart extends StatelessWidget {
  final List<BudgetSnapshot> snapshots;
  final double maxY;

  const _BarFinanceChart({required this.snapshots, required this.maxY});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        gridData: _gridData(),
        borderData: _borderData(),
        titlesData: _titlesData(context, snapshots),
        barTouchData: BarTouchData(
          enabled: true,
          touchExtraThreshold: const EdgeInsets.all(56),
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipBorder: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.28),
            ),
            tooltipPadding: const EdgeInsets.all(10),
            tooltipMargin: 8,
            maxContentWidth: 190,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final snapshot = snapshots[group.x.toInt()];
              final icon = rodIndex == 0
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded;
              final color = rodIndex == 0
                  ? AppColors.secondary
                  : AppColors.danger;

              return BarTooltipItem(
                '',
                const TextStyle(),
                textAlign: TextAlign.left,
                children: [
                  TextSpan(
                    text:
                        '${DateFormatter.period(snapshot.period.startDate, snapshot.period.endDate)}\n',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: String.fromCharCode(icon.codePoint),
                    style: TextStyle(
                      color: color,
                      fontFamily: icon.fontFamily,
                      package: icon.fontPackage,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' ${RupiahFormatter.format(rod.toY.toInt())}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < snapshots.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: snapshots[i].period.totalIncome.toDouble(),
                  color: AppColors.secondary,
                  width: 9,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: snapshots[i].totalExpense.toDouble(),
                  color: AppColors.danger,
                  width: 9,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ExpenseChartPoint {
  final DateTime date;
  final int amount;

  const _ExpenseChartPoint({required this.date, required this.amount});
}

class _SingleFinancePointChart extends StatelessWidget {
  final BudgetSnapshot snapshot;

  const _SingleFinancePointChart({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Text(
            DateFormatter.period(
              snapshot.period.startDate,
              snapshot.period.endDate,
            ),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _SinglePointMetric(
                    icon: Icons.trending_up_rounded,
                    label: context.tr('income'),
                    amount: snapshot.period.totalIncome,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SinglePointMetric(
                    icon: Icons.trending_down_rounded,
                    label: context.tr('expense'),
                    amount: snapshot.totalExpense,
                    color: AppColors.danger,
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

class _SingleExpensePointChart extends StatelessWidget {
  final _ExpenseChartPoint point;

  const _SingleExpensePointChart({required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Text(
            DateFormatter.full(point.date),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _SinglePointMetric(
              icon: Icons.trending_down_rounded,
              label: context.tr('expense'),
              amount: point.amount,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _SinglePointMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final int amount;
  final Color color;

  const _SinglePointMetric({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: color.withValues(alpha: 0.18),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2.4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            RupiahFormatter.format(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseLineChart extends StatelessWidget {
  final List<_ExpenseChartPoint> points;
  final double minY;
  final double maxY;

  const _ExpenseLineChart({
    required this.points,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: _softGridData(AppColors.danger),
        borderData: FlBorderData(show: false),
        titlesData: _expenseTitlesData(context, points),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchSpotThreshold: double.infinity,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: AppColors.danger, strokeWidth: 2),
                FlDotData(
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: AppColors.danger,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipBorder: BorderSide(
              color: AppColors.danger.withValues(alpha: 0.24),
            ),
            tooltipPadding: const EdgeInsets.all(10),
            tooltipMargin: 8,
            maxContentWidth: 190,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final point = points[spot.x.toInt()];

                return LineTooltipItem(
                  '',
                  const TextStyle(),
                  textAlign: TextAlign.left,
                  children: [
                    TextSpan(
                      text: '${DateFormatter.full(point.date)}\n',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: String.fromCharCode(
                        Icons.trending_down_rounded.codePoint,
                      ),
                      style: TextStyle(
                        color: AppColors.danger,
                        fontFamily: Icons.trending_down_rounded.fontFamily,
                        package: Icons.trending_down_rounded.fontPackage,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: ' ${RupiahFormatter.format(point.amount)}',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            preventCurveOverShooting: true,
            isStrokeCapRound: true,
            barWidth: 3,
            color: AppColors.danger,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.danger.withValues(alpha: 0.46),
                  AppColors.danger.withValues(alpha: 0.14),
                ],
              ),
            ),
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].amount.toDouble()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseBarChart extends StatelessWidget {
  final List<_ExpenseChartPoint> points;
  final double minY;
  final double maxY;

  const _ExpenseBarChart({
    required this.points,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: _expenseTitlesData(context, points),
        barTouchData: BarTouchData(
          enabled: true,
          touchExtraThreshold: const EdgeInsets.all(56),
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorderRadius: BorderRadius.circular(8),
            tooltipBorder: BorderSide(
              color: AppColors.danger.withValues(alpha: 0.24),
            ),
            tooltipPadding: const EdgeInsets.all(10),
            tooltipMargin: 8,
            maxContentWidth: 190,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final point = points[group.x.toInt()];

              return BarTooltipItem(
                '',
                const TextStyle(),
                textAlign: TextAlign.left,
                children: [
                  TextSpan(
                    text: '${DateFormatter.full(point.date)}\n',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: String.fromCharCode(
                      Icons.trending_down_rounded.codePoint,
                    ),
                    style: TextStyle(
                      color: AppColors.danger,
                      fontFamily: Icons.trending_down_rounded.fontFamily,
                      package: Icons.trending_down_rounded.fontPackage,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' ${RupiahFormatter.format(rod.toY.toInt())}',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].amount.toDouble(),
                  color: AppColors.danger,
                  width: 12,
                  borderRadius: BorderRadius.circular(6),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: AppColors.danger.withValues(alpha: 0.06),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(label: context.tr('income'), color: AppColors.secondary),
        const SizedBox(width: 14),
        _LegendItem(label: context.tr('expense'), color: AppColors.danger),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

FlGridData _gridData() {
  return FlGridData(
    drawVerticalLine: false,
    getDrawingHorizontalLine: (_) =>
        FlLine(color: AppColors.border.withValues(alpha: 0.72), strokeWidth: 1),
  );
}

FlGridData _softGridData(Color color) {
  return FlGridData(
    drawVerticalLine: false,
    getDrawingHorizontalLine: (_) =>
        FlLine(color: color.withValues(alpha: 0.1), strokeWidth: 1),
  );
}

FlBorderData _borderData() {
  return FlBorderData(
    show: true,
    border: Border(bottom: BorderSide(color: AppColors.border)),
  );
}

FlTitlesData _titlesData(BuildContext context, List<BudgetSnapshot> snapshots) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 42,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= snapshots.length) {
            return const SizedBox.shrink();
          }
          if (!_shouldShowXAxisLabel(index, snapshots.length)) {
            return const SizedBox.shrink();
          }

          final period = snapshots[index].period;
          return SideTitleWidget(
            meta: meta,
            space: 8,
            fitInside: SideTitleFitInsideData.fromTitleMeta(
              meta,
              distanceFromEdge: 4,
            ),
            child: Text(
              DateFormatter.short(period.startDate),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    ),
  );
}

FlTitlesData _expenseTitlesData(
  BuildContext context,
  List<_ExpenseChartPoint> points,
) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 34,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= points.length) {
            return const SizedBox.shrink();
          }
          if (!_shouldShowXAxisLabel(index, points.length)) {
            return const SizedBox.shrink();
          }

          return SideTitleWidget(
            meta: meta,
            space: 8,
            fitInside: SideTitleFitInsideData.fromTitleMeta(
              meta,
              distanceFromEdge: 4,
            ),
            child: Text(
              DateFormatter.short(points[index].date),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    ),
  );
}

bool _shouldShowXAxisLabel(int index, int itemCount) {
  if (itemCount <= _maxXAxisLabels) return true;
  if (index == 0 || index == itemCount - 1) return true;

  final interval = ((itemCount - 1) / (_maxXAxisLabels - 1)).ceil();
  return index % interval == 0;
}
