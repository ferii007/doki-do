import '../../../core/localization/app_localizations.dart';
import '../../../core/app_info/app_identity.dart';
import '../../finance/domain/entities/budget_snapshot.dart';
import '../../finance/domain/entities/transaction_item.dart';
import '../../finance/domain/entities/transaction_type.dart';
import '../domain/export_report_request.dart';

class ReportDataset {
  final ExportReportRequest request;
  final AppLocalizations localizations;
  final List<ReportPeriodData> periods;

  ReportDataset._({
    required this.request,
    required this.localizations,
    required this.periods,
  });

  factory ReportDataset.fromRequest(ExportReportRequest request) {
    final localizations = AppLocalizations(request.language);
    final snapshots = [...request.snapshots]
      ..sort((a, b) => a.period.startDate.compareTo(b.period.startDate));
    return ReportDataset._(
      request: request,
      localizations: localizations,
      periods: [
        for (final snapshot in snapshots)
          ReportPeriodData(
            snapshot: snapshot,
            label: _periodLabel(snapshot, localizations),
            rangeStart: request.dateRangeStart,
            rangeEnd: request.dateRangeEnd,
          ),
      ],
    );
  }

  int get totalIncome =>
      periods.fold(0, (sum, period) => sum + period.totalIncome);

  int get totalExpense =>
      periods.fold(0, (sum, period) => sum + period.totalExpense);

  int get remainingMoney => totalIncome - totalExpense;

  List<ReportTransactionData> get transactions {
    final rows = <ReportTransactionData>[
      for (final period in periods) ...period.transactions,
    ];
    rows.sort((a, b) => a.date.compareTo(b.date));
    return rows;
  }

  List<ReportDailyCashFlowData> get dailyCashFlow {
    final byDate = <DateTime, ({int income, int expense})>{};
    for (final transaction in transactions) {
      final date = _dateOnly(transaction.date);
      final current = byDate[date] ?? (income: 0, expense: 0);
      byDate[date] = transaction.type == TransactionType.income
          ? (
              income: current.income + transaction.amount,
              expense: current.expense,
            )
          : (
              income: current.income,
              expense: current.expense + transaction.amount,
            );
    }
    final dates = byDate.keys.toList()..sort();
    var income = 0;
    var expense = 0;
    final rows = <ReportDailyCashFlowData>[];
    for (final date in dates) {
      final values = byDate[date]!;
      income += values.income;
      expense += values.expense;
      rows.add(
        ReportDailyCashFlowData(
          date: date,
          cumulativeIncome: income,
          cumulativeExpense: expense,
          remainingMoney: income - expense,
        ),
      );
    }
    return rows;
  }

  List<ReportCategorySummaryData> get categorySummary {
    final totals =
        <String, ({int budgetLimit, int expense, int remainingMoney})>{};
    for (final period in periods) {
      for (final category in period.categories) {
        final current =
            totals[category.name] ??
            (budgetLimit: 0, expense: 0, remainingMoney: 0);
        totals[category.name] = (
          budgetLimit: current.budgetLimit + category.budgetLimit,
          expense: current.expense + category.expense,
          remainingMoney: current.remainingMoney + category.remainingMoney,
        );
      }
    }
    final rows = [
      for (final entry in totals.entries)
        ReportCategorySummaryData(
          name: entry.key,
          budgetLimit: entry.value.budgetLimit,
          expense: entry.value.expense,
          remainingMoney: entry.value.remainingMoney,
        ),
    ];
    rows.sort((a, b) => b.expense.compareTo(a.expense));
    return rows;
  }

  String get scopeLabel {
    if (request.dateRangeStart != null && request.dateRangeEnd != null) {
      return '${formatDate(request.dateRangeStart!)} - '
          '${formatDate(request.dateRangeEnd!)}';
    }
    return periods.length == 1
        ? periods.single.label
        : localizations.trf('financial_period_count', {
            'count': periods.length,
          });
  }

  String get fileNameStem {
    final scope = request.dateRangeStart != null && request.dateRangeEnd != null
        ? '${_compactDate(request.dateRangeStart!)}_'
              '${_compactDate(request.dateRangeEnd!)}'
        : periods.length == 1
        ? _compactDate(periods.single.snapshot.period.startDate)
        : '${_compactDate(periods.first.snapshot.period.startDate)}_'
              '${_compactDate(periods.last.snapshot.period.endDate)}';
    return '${AppIdentity.appName}_Laporan_Keuangan_$scope';
  }

  bool includesDate(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    final start = request.dateRangeStart;
    final end = request.dateRangeEnd;
    if (start != null && date.isBefore(_dateOnly(start))) return false;
    if (end != null && date.isAfter(_dateOnly(end))) return false;
    return true;
  }

  String formatCurrency(int value) => request.currency.format(value);

  String formatDate(DateTime value) {
    final month = localizations.tr('month_long_${value.month}');
    return '${value.day} $month ${value.year}';
  }

  static String _periodLabel(
    BudgetSnapshot snapshot,
    AppLocalizations localizations,
  ) {
    String full(DateTime value) {
      final month = localizations.tr('month_long_${value.month}');
      return '${value.day} $month ${value.year}';
    }

    return '${full(snapshot.period.startDate)} - '
        '${full(snapshot.period.endDate)}';
  }

  static String _compactDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}$month$day';
  }
}

class ReportPeriodData {
  final BudgetSnapshot snapshot;
  final String label;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  const ReportPeriodData({
    required this.snapshot,
    required this.label,
    this.rangeStart,
    this.rangeEnd,
  });

  bool get _hasDateFilter => rangeStart != null || rangeEnd != null;

  List<TransactionItem> get _transactions => snapshot.transactions
      .where((transaction) => _includesDate(transaction.date))
      .toList(growable: false);

  int get totalIncome => _hasDateFilter
      ? _transactions
            .where((item) => item.type == TransactionType.income)
            .fold(0, (sum, item) => sum + item.amount)
      : snapshot.period.totalIncome;
  int get totalExpense => _transactions
      .where((item) => item.type == TransactionType.expense)
      .fold(0, (sum, item) => sum + item.amount);
  int get remainingMoney => totalIncome - totalExpense;
  int get allocatedBudget => snapshot.categories.fold(
    0,
    (sum, category) => sum + category.allocatedAmount,
  );

  List<ReportCategoryData> get categories {
    return [
      for (final category in snapshot.categories)
        ReportCategoryData(
          name: category.name,
          allocationPercent: category.allocationPercent,
          budgetLimit: category.allocatedAmount,
          expense: _transactions
              .where(
                (transaction) =>
                    transaction.type == TransactionType.expense &&
                    transaction.categoryId == category.id,
              )
              .fold(0, (sum, transaction) => sum + transaction.amount),
          remainingMoney: _hasDateFilter
              ? category.allocatedAmount -
                    _transactions
                        .where(
                          (transaction) =>
                              transaction.type == TransactionType.expense &&
                              transaction.categoryId == category.id,
                        )
                        .fold(0, (sum, transaction) => sum + transaction.amount)
              : category.remainingAmount,
        ),
    ];
  }

  List<ReportTransactionData> get transactions {
    final categoryNames = {
      for (final category in snapshot.categories) category.id: category.name,
    };
    return [
      for (final transaction in _transactions)
        ReportTransactionData(
          periodLabel: label,
          type: transaction.type,
          category: transaction.type == TransactionType.expense
              ? categoryNames[transaction.categoryId] ?? '-'
              : '-',
          description: transaction.title,
          amount: transaction.amount,
          date: transaction.date,
        ),
    ];
  }

  bool _includesDate(DateTime value) {
    final date = _dateOnly(value);
    if (rangeStart != null && date.isBefore(_dateOnly(rangeStart!))) {
      return false;
    }
    if (rangeEnd != null && date.isAfter(_dateOnly(rangeEnd!))) return false;
    return true;
  }
}

class ReportCategoryData {
  final String name;
  final double? allocationPercent;
  final int budgetLimit;
  final int expense;
  final int remainingMoney;

  const ReportCategoryData({
    required this.name,
    required this.allocationPercent,
    required this.budgetLimit,
    required this.expense,
    required this.remainingMoney,
  });

  double get usagePercent => budgetLimit <= 0 ? 0 : expense / budgetLimit;
}

class ReportTransactionData {
  final String periodLabel;
  final TransactionType type;
  final String category;
  final String description;
  final int amount;
  final DateTime date;

  const ReportTransactionData({
    required this.periodLabel,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
  });
}

class ReportDailyCashFlowData {
  final DateTime date;
  final int cumulativeIncome;
  final int cumulativeExpense;
  final int remainingMoney;

  const ReportDailyCashFlowData({
    required this.date,
    required this.cumulativeIncome,
    required this.cumulativeExpense,
    required this.remainingMoney,
  });
}

class ReportCategorySummaryData {
  final String name;
  final int budgetLimit;
  final int expense;
  final int remainingMoney;

  const ReportCategorySummaryData({
    required this.name,
    required this.budgetLimit,
    required this.expense,
    required this.remainingMoney,
  });

  double get usagePercent => budgetLimit <= 0 ? 0 : expense / budgetLimit;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
