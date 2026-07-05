import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/app_info/app_identity.dart';
import '../../finance/domain/entities/transaction_type.dart';
import '../../settings/domain/entities/export_report_template.dart';
import '../domain/export_report_request.dart';
import '../domain/generated_report.dart';
import 'report_data_mapper.dart';

class PdfReportGenerator {
  const PdfReportGenerator();

  Future<GeneratedReport> generate(ExportReportRequest request) async {
    final dataset = ReportDataset.fromRequest(request);
    final document = pw.Document(
      title: dataset.localizations.tr('financial_report'),
      author: '${AppIdentity.appTitle} - ${AppIdentity.developerName}',
      creator: AppIdentity.appTitle,
    );
    final regularFontData = await rootBundle.load(
      'assets/fonts/Poppins-Regular.ttf',
    );
    final boldFontData = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');
    final theme = pw.ThemeData.withFont(
      base: pw.Font.ttf(regularFontData),
      bold: pw.Font.ttf(boldFontData),
    );
    final isDashboard = request.template == ExportReportTemplate.dashboard;
    if (isDashboard) {
      document
        ..addPage(
          pw.Page(
            pageTheme: pw.PageTheme(
              pageFormat: PdfPageFormat.a4.landscape,
              margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 30),
              theme: theme,
            ),
            build: (context) => pw.Column(
              children: [
                _header(dataset),
                ..._dashboardContent(dataset),
                pw.Spacer(),
                _footer(dataset, context),
              ],
            ),
          ),
        )
        ..addPage(
          pw.MultiPage(
            pageTheme: pw.PageTheme(
              pageFormat: PdfPageFormat.a4.landscape,
              margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 30),
              theme: theme,
            ),
            header: (context) => _header(dataset),
            footer: (context) => _footer(dataset, context),
            build: (context) => _dashboardDetailsContent(dataset),
          ),
        );
    } else {
      document.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 30),
            theme: theme,
          ),
          header: (context) => _header(dataset),
          footer: (context) => _footer(dataset, context),
          build: (context) => _basicContent(dataset),
        ),
      );
    }

    final suffix = request.template == ExportReportTemplate.dashboard
        ? 'Dashboard'
        : 'Basic';
    return GeneratedReport(
      fileName: '${dataset.fileNameStem}_$suffix.pdf',
      mimeType: request.format.mimeType,
      bytes: Uint8List.fromList(await document.save()),
    );
  }

  List<pw.Widget> _dashboardContent(ReportDataset dataset) {
    return [
      _dashboardMetricGrid(dataset),
      pw.SizedBox(height: 10),
      _dashboardCharts(dataset),
      pw.SizedBox(height: 10),
      _dashboardBottom(dataset),
    ];
  }

  List<pw.Widget> _dashboardDetailsContent(ReportDataset dataset) {
    return [
      _detailSection(
        dataset.localizations.tr('category_details'),
        _categorySummaryTable(dataset),
      ),
      pw.SizedBox(height: 18),
      _detailSection(
        dataset.localizations.tr('transaction_details'),
        _transactionTable(dataset),
      ),
    ];
  }

  List<pw.Widget> _basicContent(ReportDataset dataset) {
    return [
      _detailSection(
        dataset.localizations.tr('transaction_details'),
        _transactionTable(dataset),
      ),
    ];
  }

  pw.Widget _header(ReportDataset dataset) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                AppIdentity.appTitle,
                style: pw.TextStyle(
                  color: _teal,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _reportPeriodRange(dataset),
                style: const pw.TextStyle(color: _muted, fontSize: 9),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: double.infinity,
            height: 0.8,
            color: const PdfColor.fromInt(0xFFB7DCD8),
          ),
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  pw.Widget _footer(ReportDataset dataset, pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2ECEB)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            AppIdentity.developerAttribution,
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
          pw.Text(
            dataset.localizations.trf('page_of_pages', {
              'page': context.pageNumber,
              'pages': context.pagesCount,
            }),
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _dashboardMetricGrid(ReportDataset dataset) {
    final metrics = [
      (
        dataset.localizations.tr('total_income'),
        dataset.formatCurrency(dataset.totalIncome),
      ),
      (
        dataset.localizations.tr('total_expense'),
        dataset.formatCurrency(dataset.totalExpense),
      ),
      (
        dataset.localizations.tr('remaining_money'),
        dataset.formatCurrency(dataset.remainingMoney),
      ),
    ];
    final stats = [
      (
        dataset.localizations.tr('recorded_periods'),
        dataset.periods.length.toString(),
      ),
      (
        dataset.localizations.tr('active_categories'),
        dataset.categorySummary.length.toString(),
      ),
      (
        dataset.localizations.tr('recorded_transactions'),
        dataset.transactions.length.toString(),
      ),
    ];
    return pw.Column(
      children: [
        for (var index = 0; index < metrics.length; index++) ...[
          pw.Row(
            children: [
              pw.Expanded(
                child: _dashboardMetricRow(
                  metrics[index].$1,
                  metrics[index].$2,
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Expanded(
                child: _dashboardMetricRow(stats[index].$1, stats[index].$2),
              ),
            ],
          ),
          if (index != metrics.length - 1) pw.SizedBox(height: 4),
        ],
      ],
    );
  }

  pw.Widget _dashboardMetricRow(String label, String value) {
    return pw.Container(
      height: 24,
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              height: 24,
              alignment: pw.Alignment.centerLeft,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10),
              color: _teal,
              child: pw.Text(
                label,
                maxLines: 1,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              height: 24,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: _tableSurface,
                border: pw.Border.all(color: _teal, width: 0.7),
              ),
              child: pw.FittedBox(
                fit: pw.BoxFit.scaleDown,
                child: pw.Text(
                  value,
                  style: pw.TextStyle(
                    color: _teal,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _dashboardCharts(ReportDataset dataset) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _chartPanel(
            title: dataset.localizations.tr('cash_flow'),
            child: _cashFlowChart(dataset),
          ),
        ),
        pw.SizedBox(width: 18),
        pw.Expanded(
          child: _chartPanel(
            title: dataset.localizations.tr('expense_composition'),
            child: _expenseComposition(dataset),
          ),
        ),
      ],
    );
  }

  pw.Widget _chartPanel({required String title, required pw.Widget child}) {
    return pw.Container(
      height: 164,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            width: double.infinity,
            height: 24,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _teal,
              border: pw.Border.all(color: _teal, width: _chartBorderWidth),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: _sectionHeaderGap),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 7),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: _teal, width: _chartBorderWidth),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _dashboardBottom(ReportDataset dataset) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _dashboardSection(
            dataset.localizations.tr('transaction_highlights'),
            _dashboardTransactionHighlightsTable(dataset),
          ),
        ),
        pw.SizedBox(width: 18),
        pw.Expanded(
          child: _dashboardSection(
            dataset.localizations.tr('category_highlights'),
            _dashboardHighlightsTable(dataset),
          ),
        ),
      ],
    );
  }

  pw.Widget _dashboardSection(String title, pw.Widget content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          width: double.infinity,
          height: 22,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: _teal,
            border: pw.Border.all(color: _teal, width: _tableBorderWidth),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: _sectionHeaderGap),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _teal, width: _tableBorderWidth),
          ),
          child: content,
        ),
      ],
    );
  }

  pw.Widget _dashboardTransactionHighlightsTable(ReportDataset dataset) {
    final transactions = dataset.transactions;
    final incomes = transactions
        .where((transaction) => transaction.type == TransactionType.income)
        .toList();
    final expenses = transactions
        .where((transaction) => transaction.type == TransactionType.expense)
        .toList();
    final largestIncome = incomes.isEmpty
        ? null
        : incomes.reduce((a, b) => a.amount >= b.amount ? a : b);
    final largestExpense = expenses.isEmpty
        ? null
        : expenses.reduce((a, b) => a.amount >= b.amount ? a : b);
    final latestTransaction = transactions.isEmpty ? null : transactions.last;
    final rows = [
      (
        dataset.localizations.tr('largest_income'),
        largestIncome?.description ?? '-',
        largestIncome?.amount ?? 0,
      ),
      (
        dataset.localizations.tr('largest_expense'),
        largestExpense?.description ?? '-',
        largestExpense?.amount ?? 0,
      ),
      (
        dataset.localizations.tr('latest_transaction'),
        latestTransaction?.description ?? '-',
        latestTransaction?.amount ?? 0,
      ),
    ];
    return _compactDashboardTable(
      headers: [
        '',
        dataset.localizations.tr('transaction'),
        dataset.localizations.tr('amount'),
      ],
      rows: [
        for (final row in rows)
          [row.$1, row.$2, dataset.formatCurrency(row.$3)],
      ],
      columnWidths: {
        0: const pw.FlexColumnWidth(1.65),
        1: const pw.FlexColumnWidth(1.3),
        2: const pw.FlexColumnWidth(1.15),
      },
      firstColumnAccent: true,
    );
  }

  pw.Widget _dashboardHighlightsTable(ReportDataset dataset) {
    final categories = dataset.categorySummary;
    final largestExpense = categories.isEmpty
        ? null
        : categories.reduce((a, b) => a.expense >= b.expense ? a : b);
    final largestRemaining = categories.isEmpty
        ? null
        : categories.reduce(
            (a, b) => a.remainingMoney >= b.remainingMoney ? a : b,
          );
    final deficits = categories
        .where((category) => category.remainingMoney < 0)
        .toList();
    final highestDeficit = deficits.isEmpty
        ? null
        : deficits.reduce(
            (a, b) => a.remainingMoney <= b.remainingMoney ? a : b,
          );
    final rows = [
      (
        dataset.localizations.tr('largest_expense'),
        largestExpense?.expense ?? 0,
        largestExpense?.name ?? '-',
      ),
      (
        dataset.localizations.tr('largest_remaining_budget'),
        largestRemaining?.remainingMoney ?? 0,
        largestRemaining?.name ?? '-',
      ),
      (
        dataset.localizations.tr('highest_deficit'),
        highestDeficit?.remainingMoney ?? 0,
        highestDeficit?.name ?? '-',
      ),
    ];
    return _compactDashboardTable(
      headers: [
        '',
        dataset.localizations.tr('budget_category'),
        dataset.localizations.tr('amount'),
      ],
      rows: [
        for (final row in rows)
          [row.$1, row.$3, dataset.formatCurrency(row.$2)],
      ],
      columnWidths: {
        0: const pw.FlexColumnWidth(1.65),
        1: const pw.FlexColumnWidth(1.3),
        2: const pw.FlexColumnWidth(1.15),
      },
      firstColumnAccent: true,
    );
  }

  pw.Widget _compactDashboardTable({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, pw.TableColumnWidth> columnWidths,
    bool firstColumnAccent = false,
  }) {
    return pw.Table(
      columnWidths: columnWidths,
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(
          color: PdfColors.white,
          width: _tableBorderWidth,
        ),
      ),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _teal),
          children: [
            for (final header in headers)
              pw.Container(
                height: 20,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(horizontal: 3),
                child: pw.Text(
                  header,
                  maxLines: 2,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        for (final row in rows)
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _tableSurface),
            children: [
              for (var index = 0; index < row.length; index++)
                pw.Container(
                  height: 20,
                  alignment: index == 0
                      ? pw.Alignment.centerLeft
                      : pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                  color: firstColumnAccent && index == 0 ? _teal : null,
                  child: pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    child: pw.Text(
                      row[index],
                      style: pw.TextStyle(
                        color: firstColumnAccent && index == 0
                            ? PdfColors.white
                            : _text,
                        fontSize: 7.5,
                        fontWeight: firstColumnAccent && index == 0
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  pw.Widget _cashFlowChart(ReportDataset dataset) {
    final source = dataset.dailyCashFlow;
    if (source.isEmpty) return _chartEmpty(dataset);
    final expandedRows = [
      ReportDailyCashFlowData(
        date: source.first.date.subtract(const Duration(days: 1)),
        cumulativeIncome: 0,
        cumulativeExpense: 0,
        remainingMoney: 0,
      ),
      ...source,
    ];
    final rows = _sampleCashFlowRows(expandedRows);
    final values = [
      for (final row in rows) ...[
        row.cumulativeIncome,
        row.cumulativeExpense,
        row.remainingMoney,
      ],
    ];
    var minimum = math.min(0, values.reduce(math.min)).toDouble();
    var maximum = _chartUpperBound(
      math.max(1, values.reduce(math.max)).toDouble(),
    );
    if (minimum == maximum) maximum = minimum + 1;
    final middle = minimum + ((maximum - minimum) / 2);
    final labels = [for (final row in rows) _shortPeriod(row.date)];
    final chart = pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis.fromStrings(
          labels,
          textStyle: const pw.TextStyle(color: _muted, fontSize: 5.5),
          ticks: true,
          color: PdfColor.fromInt(0xFFB9CECC),
        ),
        yAxis: pw.FixedAxis<double>(
          [minimum, middle, maximum],
          format: _compactNumber,
          textStyle: const pw.TextStyle(color: _muted, fontSize: 5.5),
          divisions: true,
          divisionsColor: PdfColor.fromInt(0xFFE6EFEE),
          color: PdfColor.fromInt(0xFFB9CECC),
        ),
      ),
      datasets: [
        pw.LineDataSet(
          data: [
            for (var index = 0; index < rows.length; index++)
              pw.PointChartValue(
                index.toDouble(),
                rows[index].cumulativeIncome.toDouble(),
              ),
          ],
          drawPoints: false,
          drawSurface: true,
          surfaceColor: _teal,
          surfaceOpacity: 0.12,
          isCurved: true,
          lineWidth: 1.6,
          color: _teal,
          lineColor: _teal,
        ),
        pw.LineDataSet(
          data: [
            for (var index = 0; index < rows.length; index++)
              pw.PointChartValue(
                index.toDouble(),
                rows[index].cumulativeExpense.toDouble(),
              ),
          ],
          drawPoints: false,
          drawSurface: true,
          surfaceColor: _danger,
          surfaceOpacity: 0.1,
          isCurved: true,
          lineWidth: 1.6,
          color: _danger,
          lineColor: _danger,
        ),
        pw.LineDataSet(
          data: [
            for (var index = 0; index < rows.length; index++)
              pw.PointChartValue(
                index.toDouble(),
                rows[index].remainingMoney.toDouble(),
              ),
          ],
          drawPoints: false,
          drawSurface: true,
          surfaceColor: _gold,
          surfaceOpacity: 0.1,
          isCurved: true,
          lineWidth: 1.2,
          color: _gold,
          lineColor: _gold,
        ),
      ],
    );
    return pw.Column(
      children: [
        pw.Expanded(child: chart),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _chartLegend(dataset.localizations.tr('income'), _teal),
            pw.SizedBox(width: 8),
            _chartLegend(dataset.localizations.tr('expense'), _danger),
            pw.SizedBox(width: 8),
            _chartLegend(dataset.localizations.tr('remaining_money'), _gold),
          ],
        ),
      ],
    );
  }

  pw.Widget _expenseComposition(ReportDataset dataset) {
    final source = dataset.categorySummary
        .where((category) => category.expense > 0)
        .toList();
    final categories = source.take(5).toList();
    if (source.length > 5) {
      final otherExpense = source
          .skip(5)
          .fold<int>(0, (sum, category) => sum + category.expense);
      categories.add(
        ReportCategorySummaryData(
          name: dataset.localizations.tr('others'),
          budgetLimit: 0,
          expense: otherExpense,
          remainingMoney: 0,
        ),
      );
    }
    if (categories.isEmpty) return _chartEmpty(dataset);
    const colors = [_blue, _coral, _green, _purple, _mint, _gold];
    final total = categories.fold<int>(
      0,
      (sum, category) => sum + category.expense,
    );
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Chart(
            grid: pw.PieGrid(),
            datasets: [
              for (var index = 0; index < categories.length; index++)
                pw.PieDataSet(
                  value: categories[index].expense,
                  color: colors[index],
                  innerRadius: 22,
                  legendPosition: pw.PieLegendPosition.none,
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < categories.length; index++) ...[
                _chartLegend(
                  '${categories[index].name} '
                  '${((categories[index].expense / total) * 100).round()}%',
                  colors[index],
                ),
                if (index != categories.length - 1) pw.SizedBox(height: 5),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<ReportDailyCashFlowData> _sampleCashFlowRows(
    List<ReportDailyCashFlowData> rows,
  ) {
    if (rows.length <= 6) return rows;
    final sampled = <ReportDailyCashFlowData>[];
    for (var index = 0; index < 6; index++) {
      final sourceIndex = ((rows.length - 1) * index / 5).round();
      final row = rows[sourceIndex];
      if (sampled.isEmpty || sampled.last.date != row.date) sampled.add(row);
    }
    return sampled;
  }

  pw.Widget _chartLegend(String label, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 6,
          height: 6,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 3),
        pw.Flexible(
          child: pw.Text(
            label,
            maxLines: 2,
            style: const pw.TextStyle(color: _muted, fontSize: 5.7),
          ),
        ),
      ],
    );
  }

  pw.Widget _chartEmpty(ReportDataset dataset) {
    return pw.Center(
      child: pw.Text(
        dataset.localizations.tr('no_transactions_to_export'),
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(color: _muted, fontSize: 7),
      ),
    );
  }

  String _compactNumber(num value) {
    final absolute = value.abs();
    if (absolute >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (absolute >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (absolute >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  double _chartUpperBound(double value) {
    final paddedValue = value * 1.1;
    final magnitude = math
        .pow(10, (math.log(paddedValue) / math.ln10).floor())
        .toDouble();
    final normalized = paddedValue / magnitude;
    const steps = [1.0, 1.2, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0];
    final step = steps.firstWhere(
      (candidate) => candidate >= normalized,
      orElse: () => 10,
    );
    return step * magnitude;
  }

  pw.Widget _categorySummaryTable(ReportDataset dataset) {
    final categories = dataset.categorySummary;
    if (categories.isEmpty) {
      return pw.Text(
        dataset.localizations.tr('no_budget_categories_yet'),
        style: const pw.TextStyle(color: _muted, fontSize: 9),
      );
    }
    return _table(
      headers: [
        dataset.localizations.tr('budget_category'),
        dataset.localizations.tr('budget_limit'),
        dataset.localizations.tr('expense'),
        dataset.localizations.tr('remaining_money'),
        dataset.localizations.tr('usage'),
      ],
      rows: [
        for (final category in categories)
          [
            category.name,
            dataset.formatCurrency(category.budgetLimit),
            dataset.formatCurrency(category.expense),
            dataset.formatCurrency(category.remainingMoney),
            '${(category.usagePercent * 100).toStringAsFixed(0)}%',
          ],
      ],
      columnWidths: {
        0: const pw.FlexColumnWidth(1.8),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(0.9),
      },
    );
  }

  pw.Widget _transactionTable(ReportDataset dataset) {
    if (dataset.transactions.isEmpty) {
      return pw.Text(
        dataset.localizations.tr('no_transactions_to_export'),
        style: const pw.TextStyle(color: _muted, fontSize: 9),
      );
    }
    return _table(
      headers: [
        dataset.localizations.tr('date'),
        dataset.localizations.tr('type'),
        dataset.localizations.tr('category'),
        dataset.localizations.tr('description'),
        dataset.localizations.tr('amount'),
      ],
      rows: [
        for (final transaction in dataset.transactions)
          [
            dataset.formatDate(transaction.date),
            dataset.localizations.tr(
              transaction.type == TransactionType.income ? 'income' : 'expense',
            ),
            transaction.category,
            transaction.description,
            dataset.formatCurrency(transaction.amount),
          ],
      ],
      columnWidths: {
        0: const pw.FlexColumnWidth(1.15),
        1: const pw.FlexColumnWidth(0.85),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.7),
        4: const pw.FlexColumnWidth(1.15),
      },
    );
  }

  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, pw.TableColumnWidth> columnWidths,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      columnWidths: columnWidths,
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(
          color: PdfColors.white,
          width: _tableBorderWidth,
        ),
      ),
      headerDecoration: const pw.BoxDecoration(color: _teal),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(color: _text, fontSize: 7.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      rowDecoration: const pw.BoxDecoration(color: _tableSurface),
      oddRowDecoration: const pw.BoxDecoration(color: _tableSurface),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _detailSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      height: 26,
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
      decoration: pw.BoxDecoration(
        color: _teal,
        border: pw.Border.all(color: _teal, width: _tableBorderWidth),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _detailSection(String title, pw.Widget content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _detailSectionTitle(title),
        pw.SizedBox(height: _sectionHeaderGap),
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _teal, width: _tableBorderWidth),
          ),
          child: content,
        ),
      ],
    );
  }

  String _shortPeriod(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    return '${value.day}/$month';
  }

  String _reportPeriodRange(ReportDataset dataset) {
    final start =
        dataset.request.dateRangeStart ??
        dataset.periods.first.snapshot.period.startDate;
    final end =
        dataset.request.dateRangeEnd ??
        dataset.periods.last.snapshot.period.endDate;
    return '${dataset.formatDate(start)} - ${dataset.formatDate(end)}';
  }

  static const _teal = PdfColor.fromInt(0xFF45B5AA);
  static const _chartBorderWidth = 0.7;
  static const _tableBorderWidth = 0.8;
  static const _sectionHeaderGap = 3.0;
  static const _danger = PdfColor.fromInt(0xFFD9534F);
  static const _coral = PdfColor.fromInt(0xFFD67D79);
  static const _gold = PdfColor.fromInt(0xFFF7BA7C);
  static const _blue = PdfColor.fromInt(0xFF82B1D6);
  static const _green = PdfColor.fromInt(0xFFAED37A);
  static const _purple = PdfColor.fromInt(0xFF9F8DC2);
  static const _mint = PdfColor.fromInt(0xFF69C2D1);
  static const _tableSurface = PdfColor.fromInt(0xFFE2F4F1);
  static const _text = PdfColor.fromInt(0xFF333333);
  static const _muted = PdfColor.fromInt(0xFF637A78);
}
