import 'dart:math' as math;
import 'dart:typed_data';

import 'package:excel_community/excel_community.dart';

import '../../../core/app_info/app_identity.dart';
import '../../finance/domain/entities/category_adjustment.dart';
import '../../finance/domain/entities/transaction_type.dart';
import '../../settings/domain/entities/export_report_template.dart';
import '../domain/export_report_request.dart';
import '../domain/generated_report.dart';
import 'report_data_mapper.dart';

class ExcelReportGenerator {
  const ExcelReportGenerator();

  Future<GeneratedReport> generate(ExportReportRequest request) async {
    final dataset = ReportDataset.fromRequest(request);
    final excel = Excel.createExcel();
    final names = _SheetNames(dataset);

    excel.rename('Sheet1', names.transactions);
    final transactions = excel[names.transactions];
    final categories = excel[names.categories];
    final adjustments = excel[names.adjustments];
    _buildTransactionsSheet(transactions, dataset);
    _buildCategoriesSheet(categories, dataset);
    _buildAdjustmentsSheet(adjustments, dataset);

    if (request.template == ExportReportTemplate.dashboard) {
      final periodSummary = excel[names.periodSummary];
      _buildPeriodSummarySheet(periodSummary, dataset, names);
      final chartData = excel[names.chartData];
      _buildChartDataSheet(chartData, dataset, names);
      final dashboard = excel[names.dashboard];
      _buildDashboardSheet(dashboard, dataset, names);
      excel.setDefaultSheet(names.dashboard);
    } else {
      excel.setDefaultSheet(names.transactions);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw StateError('Excel report could not be encoded.');
    }
    final suffix = request.template == ExportReportTemplate.dashboard
        ? 'Dashboard'
        : 'Basic';
    return GeneratedReport(
      fileName: '${dataset.fileNameStem}_$suffix.xlsx',
      mimeType: request.format.mimeType,
      bytes: Uint8List.fromList(encoded),
    );
  }

  void _buildTransactionsSheet(Sheet sheet, ReportDataset dataset) {
    _writeDocumentTitle(
      sheet,
      title: dataset.localizations.tr('transaction_details'),
      subtitle: dataset.scopeLabel,
      lastColumn: 5,
    );
    final headers = [
      dataset.localizations.tr('date'),
      dataset.localizations.tr('financial_period'),
      dataset.localizations.tr('type'),
      dataset.localizations.tr('category'),
      dataset.localizations.tr('description'),
      dataset.localizations.tr('amount'),
    ];
    _writeHeaderRow(sheet, 4, headers);

    for (var index = 0; index < dataset.transactions.length; index++) {
      final transaction = dataset.transactions[index];
      final row = index + 5;
      _setCell(
        sheet,
        row,
        0,
        DateCellValue.fromDateTime(transaction.date),
        _dateStyle,
      );
      _setText(sheet, row, 1, transaction.periodLabel, _bodyStyle);
      _setText(
        sheet,
        row,
        2,
        dataset.localizations.tr(
          transaction.type == TransactionType.income ? 'income' : 'expense',
        ),
        _bodyStyle,
      );
      _setText(sheet, row, 3, transaction.category, _bodyStyle);
      _setText(sheet, row, 4, transaction.description, _bodyWrapStyle);
      _setNumber(sheet, row, 5, transaction.amount, _currencyStyle);
      if (index.isOdd) _applyRowStyle(sheet, row, 6, _alternateBodyStyle);
    }

    _setWidths(sheet, [14, 34, 15, 24, 32, 18]);
  }

  void _buildCategoriesSheet(Sheet sheet, ReportDataset dataset) {
    _writeDocumentTitle(
      sheet,
      title: dataset.localizations.tr('budget_categories'),
      subtitle: dataset.scopeLabel,
      lastColumn: 6,
    );
    final headers = [
      dataset.localizations.tr('financial_period'),
      dataset.localizations.tr('budget_category'),
      dataset.localizations.tr('budget_type'),
      dataset.localizations.tr('allocation_percentage'),
      dataset.localizations.tr('budget_limit'),
      dataset.localizations.tr('expense'),
      dataset.localizations.tr('remaining_money'),
    ];
    _writeHeaderRow(sheet, 4, headers);

    var row = 5;
    for (final period in dataset.periods) {
      for (final category in period.categories) {
        _setText(sheet, row, 0, period.label, _bodyStyle);
        _setText(sheet, row, 1, category.name, _bodyStyle);
        _setText(
          sheet,
          row,
          2,
          dataset.localizations.tr(
            period.snapshot.period.allocationsFollowIncome
                ? 'follows_incoming_money'
                : 'fixed_amount',
          ),
          _bodyStyle,
        );
        if (category.allocationPercent != null) {
          _setNumber(
            sheet,
            row,
            3,
            category.allocationPercent! / 100,
            _percentageStyle,
          );
        } else {
          _setText(sheet, row, 3, '-', _bodyStyle);
        }
        _setNumber(sheet, row, 4, category.budgetLimit, _currencyStyle);
        _setNumber(sheet, row, 5, category.expense, _currencyStyle);
        _setNumber(sheet, row, 6, category.remainingMoney, _currencyStyle);
        if ((row - 5).isOdd) {
          _applyRowStyle(sheet, row, 7, _alternateBodyStyle);
        }
        row++;
      }
    }

    _setWidths(sheet, [34, 25, 22, 16, 18, 18, 18]);
  }

  void _buildAdjustmentsSheet(Sheet sheet, ReportDataset dataset) {
    _writeDocumentTitle(
      sheet,
      title: dataset.localizations.tr('budget_change_history'),
      subtitle: dataset.scopeLabel,
      lastColumn: 8,
    );
    final headers = [
      dataset.localizations.tr('date'),
      dataset.localizations.tr('financial_period'),
      dataset.localizations.tr('budget_category'),
      dataset.localizations.tr('change_type'),
      dataset.localizations.tr('source_category'),
      dataset.localizations.tr('reason'),
      dataset.localizations.tr('previous_amount'),
      dataset.localizations.tr('change_amount'),
      dataset.localizations.tr('new_amount'),
    ];
    _writeHeaderRow(sheet, 4, headers);

    var row = 5;
    for (final period in dataset.periods) {
      final categoryNames = {
        for (final category in period.snapshot.categories)
          category.id: category.name,
      };
      for (final adjustment in period.snapshot.categoryAdjustments) {
        if (!dataset.includesDate(adjustment.date)) continue;
        _setCell(
          sheet,
          row,
          0,
          DateCellValue.fromDateTime(adjustment.date),
          _dateStyle,
        );
        _setText(sheet, row, 1, period.label, _bodyStyle);
        _setText(
          sheet,
          row,
          2,
          categoryNames[adjustment.categoryId] ?? '-',
          _bodyStyle,
        );
        _setText(
          sheet,
          row,
          3,
          dataset.localizations.tr(_adjustmentTypeKey(adjustment.type)),
          _bodyStyle,
        );
        _setText(
          sheet,
          row,
          4,
          categoryNames[adjustment.relatedCategoryId] ?? '-',
          _bodyStyle,
        );
        _setText(sheet, row, 5, adjustment.reason, _bodyWrapStyle);
        _setNumber(sheet, row, 6, adjustment.previousAmount, _currencyStyle);
        _setNumber(sheet, row, 7, adjustment.deltaAmount, _currencyStyle);
        _setNumber(sheet, row, 8, adjustment.newAmount, _currencyStyle);
        if ((row - 5).isOdd) {
          _applyRowStyle(sheet, row, 9, _alternateBodyStyle);
        }
        row++;
      }
    }

    _setWidths(sheet, [14, 34, 24, 20, 24, 32, 18, 18, 18]);
  }

  void _buildDashboardSheet(
    Sheet sheet,
    ReportDataset dataset,
    _SheetNames names,
  ) {
    _configureDashboardChartPalette();
    const categoryStartRow = 28;
    _paintDashboardCanvas(
      sheet,
      math.max(34, categoryStartRow + dataset.categorySummary.length + 2),
    );
    _mergeText(
      sheet,
      1,
      1,
      2,
      12,
      '${AppIdentity.appName} - ${dataset.localizations.tr('financial_report')}',
      _dashboardTitleStyle,
    );
    _mergeText(sheet, 3, 1, 3, 12, dataset.scopeLabel, _dashboardSubtitleStyle);
    sheet.setRowHeight(0, 8);
    sheet.setRowHeight(1, 25);
    sheet.setRowHeight(2, 25);
    sheet.setRowHeight(3, 20);

    _writeDashboardMetricRow(
      sheet,
      row: 5,
      label: dataset.localizations.tr('total_income'),
      formula:
          "SUM('${names.periodSummary}'!D6:D${dataset.periods.length + 5})",
    );
    _writeDashboardStatRow(
      sheet,
      row: 5,
      label: dataset.localizations.tr('recorded_periods'),
      value: dataset.periods.length,
    );
    _writeDashboardMetricRow(
      sheet,
      row: 7,
      label: dataset.localizations.tr('total_expense'),
      formula:
          "SUM('${names.periodSummary}'!E6:E${dataset.periods.length + 5})",
    );
    _writeDashboardStatRow(
      sheet,
      row: 7,
      label: dataset.localizations.tr('active_categories'),
      value: dataset.categorySummary.length,
    );
    _writeDashboardMetricRow(
      sheet,
      row: 9,
      label: dataset.localizations.tr('remaining_money'),
      formula:
          "SUM('${names.periodSummary}'!F6:F${dataset.periods.length + 5})",
    );
    _writeDashboardStatRow(
      sheet,
      row: 9,
      label: dataset.localizations.tr('recorded_transactions'),
      value: dataset.transactions.length,
    );

    _mergeText(
      sheet,
      12,
      1,
      12,
      7,
      dataset.localizations.tr('cash_flow'),
      _dashboardSectionStyle,
    );
    _mergeText(
      sheet,
      12,
      8,
      12,
      12,
      dataset.localizations.tr('expense_composition'),
      _dashboardSectionStyle,
    );
    _mergeText(
      sheet,
      categoryStartRow - 1,
      1,
      categoryStartRow - 1,
      7,
      dataset.localizations.tr('category_summary'),
      _dashboardSectionStyle,
    );
    _writeDashboardCategoryHeader(sheet, categoryStartRow, dataset);
    _mergeText(
      sheet,
      categoryStartRow - 1,
      8,
      categoryStartRow - 1,
      12,
      dataset.localizations.tr('category_highlights'),
      _dashboardSectionStyle,
    );
    _writeDashboardHighlightHeader(sheet, categoryStartRow, dataset);

    final categorySourceEnd = math.max(
      6,
      dataset.periods.fold<int>(
            0,
            (sum, period) => sum + period.categories.length,
          ) +
          5,
    );
    var categoryRow = categoryStartRow + 1;
    for (final category in dataset.categorySummary) {
      final excelRow = categoryRow + 1;
      _setText(sheet, categoryRow, 1, category.name, _dashboardBodyStyle);
      _setFormula(
        sheet,
        categoryRow,
        2,
        "SUMIF('${names.categories}'!\$B\$6:\$B\$$categorySourceEnd,"
        'B$excelRow,'
        "'${names.categories}'!\$E\$6:\$E\$$categorySourceEnd)",
        _dashboardCurrencyStyle,
      );
      _setFormula(
        sheet,
        categoryRow,
        3,
        "SUMIF('${names.categories}'!\$B\$6:\$B\$$categorySourceEnd,"
        'B$excelRow,'
        "'${names.categories}'!\$F\$6:\$F\$$categorySourceEnd)",
        _dashboardCurrencyStyle,
      );
      _setFormula(
        sheet,
        categoryRow,
        4,
        'C$excelRow-D$excelRow',
        _dashboardCurrencyStyle,
      );
      _setFormula(
        sheet,
        categoryRow,
        5,
        'IF(C$excelRow=0,0,D$excelRow/C$excelRow)',
        _dashboardPercentageStyle,
      );
      _setFormula(
        sheet,
        categoryRow,
        6,
        'REPT("■",ROUND(MIN(1,F$excelRow)*10,0))',
        _dashboardProgressStyle,
      );
      if ((categoryRow - categoryStartRow).isEven) {
        _applyDashboardRowBackground(sheet, categoryRow, 1, 7);
      }
      categoryRow++;
    }
    _writeDashboardHighlights(sheet, dataset, categoryStartRow);

    final dailyRows = _chartDailyRows(dataset);
    final chartDataName = names.chartData.replaceAll("'", "''");
    const firstDailyExcelRow = 6;
    final lastDailyExcelRow = firstDailyExcelRow + dailyRows.length - 1;
    sheet.addChart(
      LineChart(
        title: ' ',
        series: [
          ChartSeries(
            name: dataset.localizations.tr('income'),
            categoriesRange:
                "'$chartDataName'!\$A\$$firstDailyExcelRow:"
                "\$A\$$lastDailyExcelRow",
            valuesRange:
                "'$chartDataName'!\$B\$$firstDailyExcelRow:"
                "\$B\$$lastDailyExcelRow",
            categories: [
              for (final row in dailyRows) dataset.formatDate(row.date),
            ],
            values: [for (final row in dailyRows) row.cumulativeIncome],
          ),
          ChartSeries(
            name: dataset.localizations.tr('expense'),
            categoriesRange:
                "'$chartDataName'!\$A\$$firstDailyExcelRow:"
                "\$A\$$lastDailyExcelRow",
            valuesRange:
                "'$chartDataName'!\$C\$$firstDailyExcelRow:"
                "\$C\$$lastDailyExcelRow",
            categories: [
              for (final row in dailyRows) dataset.formatDate(row.date),
            ],
            values: [for (final row in dailyRows) row.cumulativeExpense],
          ),
          ChartSeries(
            name: dataset.localizations.tr('remaining_money'),
            categoriesRange:
                "'$chartDataName'!\$A\$$firstDailyExcelRow:"
                "\$A\$$lastDailyExcelRow",
            valuesRange:
                "'$chartDataName'!\$D\$$firstDailyExcelRow:"
                "\$D\$$lastDailyExcelRow",
            categories: [
              for (final row in dailyRows) dataset.formatDate(row.date),
            ],
            values: [for (final row in dailyRows) row.remainingMoney],
          ),
        ],
        anchor: ChartAnchor.at(column: 1, row: 13, width: 6, height: 13),
      ),
    );

    if (dataset.categorySummary.isNotEmpty) {
      final dashboardName = names.dashboard.replaceAll("'", "''");
      final firstCategoryExcelRow = categoryStartRow + 2;
      final lastCategoryExcelRow =
          firstCategoryExcelRow + dataset.categorySummary.length - 1;
      sheet.addChart(
        DoughnutChart(
          title: ' ',
          series: [
            ChartSeries(
              name: dataset.localizations.tr('expense'),
              categoriesRange:
                  "'$dashboardName'!\$B\$$firstCategoryExcelRow:"
                  "\$B\$$lastCategoryExcelRow",
              valuesRange:
                  "'$dashboardName'!\$D\$$firstCategoryExcelRow:"
                  "\$D\$$lastCategoryExcelRow",
              categories: [
                for (final category in dataset.categorySummary) category.name,
              ],
              values: [
                for (final category in dataset.categorySummary)
                  category.expense,
              ],
            ),
          ],
          anchor: ChartAnchor.at(column: 8, row: 13, width: 5, height: 13),
        ),
      );
    }

    _setWidths(sheet, [4.5, 22, 15, 15, 15, 12, 18, 4, 18, 18, 15, 15, 18]);
  }

  void _buildChartDataSheet(
    Sheet sheet,
    ReportDataset dataset,
    _SheetNames names,
  ) {
    _writeDocumentTitle(
      sheet,
      title: dataset.localizations.tr('chart_data'),
      subtitle: dataset.scopeLabel,
      lastColumn: 3,
    );
    _writeHeaderRow(sheet, 4, [
      dataset.localizations.tr('date'),
      dataset.localizations.tr('income'),
      dataset.localizations.tr('expense'),
      dataset.localizations.tr('remaining_money'),
    ]);
    final dailyRows = _chartDailyRows(dataset);
    final transactionEnd = math.max(506, dataset.transactions.length + 5);
    for (var index = 0; index < dailyRows.length; index++) {
      final row = 5 + index;
      final excelRow = row + 1;
      _setCell(
        sheet,
        row,
        0,
        DateCellValue.fromDateTime(dailyRows[index].date),
        _dateStyle,
      );
      _setFormula(
        sheet,
        row,
        1,
        "SUMIFS('${names.transactions}'!\$F\$6:\$F\$$transactionEnd,"
        "'${names.transactions}'!\$A\$6:\$A\$$transactionEnd,"
        '"<="&A$excelRow,'
        "'${names.transactions}'!\$C\$6:\$C\$$transactionEnd,"
        '"${dataset.localizations.tr('income')}")',
        _currencyStyle,
      );
      _setFormula(
        sheet,
        row,
        2,
        "SUMIFS('${names.transactions}'!\$F\$6:\$F\$$transactionEnd,"
        "'${names.transactions}'!\$A\$6:\$A\$$transactionEnd,"
        '"<="&A$excelRow,'
        "'${names.transactions}'!\$C\$6:\$C\$$transactionEnd,"
        '"${dataset.localizations.tr('expense')}")',
        _currencyStyle,
      );
      _setFormula(sheet, row, 3, 'B$excelRow-C$excelRow', _currencyStyle);
    }
    _setWidths(sheet, [16, 18, 18, 18]);
  }

  void _paintDashboardCanvas(Sheet sheet, int endRow) {
    for (var row = 0; row <= endRow; row++) {
      for (var column = 0; column < 13; column++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: column,
                    rowIndex: row,
                  ),
                )
                .cellStyle =
            _dashboardCanvasStyle;
      }
    }
  }

  void _configureDashboardChartPalette() {
    ChartColorConfig.seriesPalette
      ..clear()
      ..addAll([
        _teal,
        _danger,
        _gold,
        ExcelColor.fromHexString('FF82B1D6'),
        ExcelColor.fromHexString('FF9F8DC2'),
      ]);
    final pieColors = [
      ExcelColor.fromHexString('FF82B1D6'),
      ExcelColor.fromHexString('FFD67D79'),
      ExcelColor.fromHexString('FFAED37A'),
      ExcelColor.fromHexString('FF9F8DC2'),
      ExcelColor.fromHexString('FF69C2D1'),
      ExcelColor.fromHexString('FFF7BA7C'),
      _teal,
      _danger,
      _gold,
      ExcelColor.fromHexString('FF7FA7A3'),
    ];
    ChartColorConfig.piePalette
      ..clear()
      ..addAll([...pieColors, ...pieColors]);
  }

  List<ReportDailyCashFlowData> _chartDailyRows(ReportDataset dataset) {
    final rows = dataset.dailyCashFlow;
    if (rows.isEmpty) {
      final start = dataset.periods.first.snapshot.period.startDate;
      final end = dataset.periods.last.snapshot.period.endDate;
      return [
        ReportDailyCashFlowData(
          date: start,
          cumulativeIncome: 0,
          cumulativeExpense: 0,
          remainingMoney: 0,
        ),
        ReportDailyCashFlowData(
          date: end.isAfter(start) ? end : start.add(const Duration(days: 1)),
          cumulativeIncome: 0,
          cumulativeExpense: 0,
          remainingMoney: 0,
        ),
      ];
    }
    if (rows.length != 1) return rows;
    return [
      ReportDailyCashFlowData(
        date: rows.first.date.subtract(const Duration(days: 1)),
        cumulativeIncome: 0,
        cumulativeExpense: 0,
        remainingMoney: 0,
      ),
      rows.first,
    ];
  }

  void _writeDashboardMetricRow(
    Sheet sheet, {
    required int row,
    required String label,
    required String formula,
  }) {
    _mergeText(sheet, row, 1, row, 4, label, _dashboardMetricLabelStyle);
    final start = CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row);
    sheet.merge(
      start,
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
      customValue: FormulaCellValue(formula),
    );
    sheet.setMergedCellStyle(start, _dashboardMetricValueStyle);
    sheet.setRowHeight(row, 24);
  }

  void _writeDashboardStatRow(
    Sheet sheet, {
    required int row,
    required String label,
    required int value,
  }) {
    _mergeText(sheet, row, 8, row, 10, label, _dashboardMetricLabelStyle);
    final start = CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row);
    sheet.merge(
      start,
      CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row),
      customValue: IntCellValue(value),
    );
    sheet.setMergedCellStyle(start, _dashboardStatValueStyle);
    sheet.setRowHeight(row, 24);
  }

  void _writeDashboardCategoryHeader(
    Sheet sheet,
    int row,
    ReportDataset dataset,
  ) {
    final headers = [
      dataset.localizations.tr('budget_category'),
      dataset.localizations.tr('budget_limit'),
      dataset.localizations.tr('expense'),
      dataset.localizations.tr('remaining_money'),
      dataset.localizations.tr('usage'),
      dataset.localizations.tr('usage_progress'),
    ];
    for (var index = 0; index < headers.length; index++) {
      _setText(sheet, row, index + 1, headers[index], _dashboardHeaderStyle);
    }
    sheet.setRowHeight(row, 23);
  }

  void _writeDashboardHighlightHeader(
    Sheet sheet,
    int row,
    ReportDataset dataset,
  ) {
    _mergeText(sheet, row, 8, row, 10, '', _dashboardHeaderStyle);
    _setText(
      sheet,
      row,
      11,
      dataset.localizations.tr('amount'),
      _dashboardHeaderStyle,
    );
    _setText(
      sheet,
      row,
      12,
      dataset.localizations.tr('budget_category'),
      _dashboardHeaderStyle,
    );
  }

  void _writeDashboardHighlights(
    Sheet sheet,
    ReportDataset dataset,
    int categoryStartRow,
  ) {
    final highlights = [
      dataset.localizations.tr('largest_expense'),
      dataset.localizations.tr('largest_remaining_budget'),
      dataset.localizations.tr('highest_deficit'),
    ];
    final firstCategoryExcelRow = categoryStartRow + 2;
    final lastCategoryExcelRow =
        firstCategoryExcelRow + dataset.categorySummary.length - 1;
    for (var index = 0; index < highlights.length; index++) {
      final row = categoryStartRow + index + 1;
      final excelRow = row + 1;
      _mergeText(
        sheet,
        row,
        8,
        row,
        10,
        highlights[index],
        _dashboardHighlightLabelStyle,
      );
      if (dataset.categorySummary.isEmpty) {
        _setNumber(sheet, row, 11, 0, _dashboardCurrencyStyle);
        _setText(sheet, row, 12, '-', _dashboardBodyStyle);
        continue;
      }
      final sourceColumn = index == 0 ? 'D' : 'E';
      final valueFormula = index == 2
          ? 'MIN(0,MIN(E$firstCategoryExcelRow:E$lastCategoryExcelRow))'
          : 'MAX($sourceColumn$firstCategoryExcelRow:'
                '$sourceColumn$lastCategoryExcelRow)';
      _setFormula(sheet, row, 11, valueFormula, _dashboardCurrencyStyle);
      final categoryFormula = index == 2
          ? 'IF(L$excelRow<0,INDEX(B$firstCategoryExcelRow:'
                'B$lastCategoryExcelRow,MATCH(L$excelRow,'
                'E$firstCategoryExcelRow:E$lastCategoryExcelRow,0)),"-")'
          : 'INDEX(B$firstCategoryExcelRow:B$lastCategoryExcelRow,'
                'MATCH(L$excelRow,$sourceColumn$firstCategoryExcelRow:'
                '$sourceColumn$lastCategoryExcelRow,0))';
      _setFormula(
        sheet,
        row,
        12,
        categoryFormula,
        _dashboardHighlightCategoryStyle.copyWith(
          fontColorHexVal: index == 2 ? _danger : _success,
        ),
      );
    }
  }

  void _applyDashboardRowBackground(
    Sheet sheet,
    int row,
    int startColumn,
    int endColumn,
  ) {
    for (var column = startColumn; column <= endColumn; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
      );
      final existing = cell.cellStyle ?? _dashboardBodyStyle;
      cell.cellStyle = existing.copyWith(
        backgroundColorHexVal: _dashboardTableBackground,
      );
    }
  }

  void _buildPeriodSummarySheet(
    Sheet sheet,
    ReportDataset dataset,
    _SheetNames names,
  ) {
    _writeDocumentTitle(
      sheet,
      title: dataset.localizations.tr('period_summary'),
      subtitle: dataset.scopeLabel,
      lastColumn: 5,
    );
    _writeHeaderRow(sheet, 4, [
      dataset.localizations.tr('financial_period'),
      dataset.localizations.tr('start_date'),
      dataset.localizations.tr('end_date'),
      dataset.localizations.tr('income'),
      dataset.localizations.tr('expense'),
      dataset.localizations.tr('remaining_money'),
    ]);
    final transactionEnd = dataset.transactions.isEmpty
        ? 6
        : dataset.transactions.length + 5;
    for (var index = 0; index < dataset.periods.length; index++) {
      final period = dataset.periods[index];
      final row = index + 5;
      final excelRow = row + 1;
      _setText(sheet, row, 0, period.label, _bodyStyle);
      _setCell(
        sheet,
        row,
        1,
        DateCellValue.fromDateTime(period.snapshot.period.startDate),
        _dateStyle,
      );
      _setCell(
        sheet,
        row,
        2,
        DateCellValue.fromDateTime(period.snapshot.period.endDate),
        _dateStyle,
      );
      _setFormula(
        sheet,
        row,
        3,
        "SUMIFS('${names.transactions}'!\$F\$6:\$F\$$transactionEnd,"
        "'${names.transactions}'!\$B\$6:\$B\$$transactionEnd,A$excelRow,"
        "'${names.transactions}'!\$C\$6:\$C\$$transactionEnd,"
        '"${dataset.localizations.tr('income')}")',
        _currencyStyle,
      );
      _setFormula(
        sheet,
        row,
        4,
        "SUMIFS('${names.transactions}'!\$F\$6:\$F\$$transactionEnd,"
        "'${names.transactions}'!\$B\$6:\$B\$$transactionEnd,A$excelRow,"
        "'${names.transactions}'!\$C\$6:\$C\$$transactionEnd,"
        '"${dataset.localizations.tr('expense')}")',
        _currencyStyle,
      );
      _setFormula(sheet, row, 5, 'D$excelRow-E$excelRow', _currencyStyle);
    }
    _setWidths(sheet, [34, 14, 14, 18, 18, 18]);
  }

  void _writeDocumentTitle(
    Sheet sheet, {
    required String title,
    required String subtitle,
    required int lastColumn,
  }) {
    _mergeText(sheet, 0, 0, 1, lastColumn, title, _titleStyle);
    _mergeText(sheet, 2, 0, 2, lastColumn, subtitle, _subtitleStyle);
    sheet.setRowHeight(0, 24);
    sheet.setRowHeight(1, 24);
    sheet.setRowHeight(2, 20);
  }

  void _writeHeaderRow(Sheet sheet, int row, List<String> headers) {
    for (var column = 0; column < headers.length; column++) {
      _setText(sheet, row, column, headers[column], _headerStyle);
    }
    sheet.setRowHeight(row, 24);
  }

  void _mergeText(
    Sheet sheet,
    int startRow,
    int startColumn,
    int endRow,
    int endColumn,
    String value,
    CellStyle style,
  ) {
    final start = CellIndex.indexByColumnRow(
      columnIndex: startColumn,
      rowIndex: startRow,
    );
    sheet.merge(
      start,
      CellIndex.indexByColumnRow(columnIndex: endColumn, rowIndex: endRow),
      customValue: TextCellValue(value),
    );
    sheet.setMergedCellStyle(start, style);
  }

  void _setText(
    Sheet sheet,
    int row,
    int column,
    String value,
    CellStyle style,
  ) {
    _setCell(sheet, row, column, TextCellValue(value), style);
  }

  void _setNumber(
    Sheet sheet,
    int row,
    int column,
    num value,
    CellStyle style,
  ) {
    _setCell(
      sheet,
      row,
      column,
      value is int ? IntCellValue(value) : DoubleCellValue(value.toDouble()),
      style,
    );
  }

  void _setFormula(
    Sheet sheet,
    int row,
    int column,
    String formula,
    CellStyle style,
  ) {
    _setCell(sheet, row, column, FormulaCellValue(formula), style);
  }

  void _setCell(
    Sheet sheet,
    int row,
    int column,
    CellValue value,
    CellStyle style,
  ) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
    );
    cell.value = value;
    cell.cellStyle = style;
  }

  void _applyRowStyle(
    Sheet sheet,
    int row,
    int columnCount,
    CellStyle baseStyle,
  ) {
    for (var column = 0; column < columnCount; column++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
      );
      final existing = cell.cellStyle ?? baseStyle;
      cell.cellStyle = existing.copyWith(
        backgroundColorHexVal: _alternateBackground,
      );
    }
  }

  void _setWidths(Sheet sheet, List<double> widths) {
    for (var index = 0; index < widths.length; index++) {
      sheet.setColumnWidth(index, widths[index]);
    }
  }

  String _adjustmentTypeKey(CategoryAdjustmentType type) {
    return switch (type) {
      CategoryAdjustmentType.increase => 'budget_increased',
      CategoryAdjustmentType.decrease => 'budget_decreased',
      CategoryAdjustmentType.setAmount => 'budget_set',
    };
  }

  static final _teal = ExcelColor.fromHexString('FF45B5AA');
  static final _danger = ExcelColor.fromHexString('FFD9534F');
  static final _success = ExcelColor.fromHexString('FF5CB85C');
  static final _gold = ExcelColor.fromHexString('FFF0AD4E');
  static final _darkText = ExcelColor.fromHexString('FF333333');
  static final _mutedText = ExcelColor.fromHexString('FF637A78');
  static final _border = ExcelColor.fromHexString('FFD7E9E7');
  static final _softBackground = ExcelColor.fromHexString('FFF7FBFA');
  static final _alternateBackground = ExcelColor.fromHexString('FFF3F8F7');
  static final _dashboardTableBackground = ExcelColor.fromHexString('FFE2F4F1');

  static final _thinBorder = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: _border,
  );
  static final _tealThinBorder = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: _teal,
  );
  static final _whiteThinBorder = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: ExcelColor.white,
  );

  static final _titleStyle = CellStyle(
    backgroundColorHex: _teal,
    fontColorHex: ExcelColor.white,
    fontSize: 20,
    bold: true,
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
  );
  static final _dashboardTitleStyle = CellStyle(
    backgroundColorHex: _teal,
    fontColorHex: ExcelColor.white,
    fontSize: 20,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );
  static final _dashboardSubtitleStyle = CellStyle(
    fontColorHex: _teal,
    fontSize: 11,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );
  static final _dashboardSectionStyle = CellStyle(
    backgroundColorHex: _teal,
    fontColorHex: ExcelColor.white,
    fontSize: 11,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );
  static final _dashboardCanvasStyle = CellStyle(
    backgroundColorHex: ExcelColor.white,
  );
  static final _subtitleStyle = CellStyle(
    backgroundColorHex: _softBackground,
    fontColorHex: _mutedText,
    fontSize: 10,
    bold: true,
    verticalAlign: VerticalAlign.Center,
  );
  static final _headerStyle = CellStyle(
    backgroundColorHex: _teal,
    fontColorHex: ExcelColor.white,
    fontSize: 10,
    bold: true,
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _thinBorder,
    rightBorder: _thinBorder,
    topBorder: _thinBorder,
    bottomBorder: _thinBorder,
  );
  static final _bodyStyle = CellStyle(
    fontColorHex: _darkText,
    fontSize: 10,
    verticalAlign: VerticalAlign.Center,
    leftBorder: _thinBorder,
    rightBorder: _thinBorder,
    topBorder: _thinBorder,
    bottomBorder: _thinBorder,
  );
  static final _alternateBodyStyle = _bodyStyle.copyWith(
    backgroundColorHexVal: _alternateBackground,
  );
  static final _bodyWrapStyle = _bodyStyle.copyWith(
    textWrappingVal: TextWrapping.WrapText,
  );
  static final _dateStyle = _bodyStyle.copyWith(
    numberFormat: NumFormat.custom(formatCode: 'dd mmm yyyy'),
  );
  static final _currencyStyle = _bodyStyle.copyWith(
    numberFormat: NumFormat.custom(formatCode: '"Rp" #,##0;[Red]-"Rp" #,##0'),
  );
  static final _percentageStyle = _bodyStyle.copyWith(
    numberFormat: NumFormat.custom(formatCode: '0%'),
  );
  static final _dashboardMetricLabelStyle = CellStyle(
    backgroundColorHex: _teal,
    fontColorHex: ExcelColor.white,
    fontSize: 10,
    bold: true,
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    leftBorder: _tealThinBorder,
    rightBorder: _tealThinBorder,
    topBorder: _tealThinBorder,
    bottomBorder: _tealThinBorder,
  );
  static final _dashboardMetricValueStyle = CellStyle(
    backgroundColorHex: _dashboardTableBackground,
    fontColorHex: _teal,
    fontSize: 11,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: '"Rp" #,##0;[Red]-"Rp" #,##0'),
    leftBorder: _tealThinBorder,
    rightBorder: _tealThinBorder,
    topBorder: _tealThinBorder,
    bottomBorder: _tealThinBorder,
  );
  static final _dashboardStatValueStyle = CellStyle(
    backgroundColorHex: _dashboardTableBackground,
    fontColorHex: _teal,
    fontSize: 11,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: '#,##0'),
    leftBorder: _tealThinBorder,
    rightBorder: _tealThinBorder,
    topBorder: _tealThinBorder,
    bottomBorder: _tealThinBorder,
  );
  static final _dashboardHeaderStyle = CellStyle(
    backgroundColorHex: _teal,
    fontColorHex: ExcelColor.white,
    fontSize: 8,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _whiteThinBorder,
    rightBorder: _whiteThinBorder,
    topBorder: _whiteThinBorder,
    bottomBorder: _whiteThinBorder,
  );
  static final _dashboardBodyStyle = CellStyle(
    backgroundColorHex: _dashboardTableBackground,
    fontColorHex: _darkText,
    fontSize: 8,
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _whiteThinBorder,
    rightBorder: _whiteThinBorder,
    topBorder: _whiteThinBorder,
    bottomBorder: _whiteThinBorder,
  );
  static final _dashboardCurrencyStyle = _dashboardBodyStyle.copyWith(
    horizontalAlignVal: HorizontalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: '"Rp" #,##0;[Red]-"Rp" #,##0'),
  );
  static final _dashboardPercentageStyle = _dashboardBodyStyle.copyWith(
    horizontalAlignVal: HorizontalAlign.Center,
    numberFormat: NumFormat.custom(formatCode: '0%'),
  );
  static final _dashboardProgressStyle = _dashboardBodyStyle.copyWith(
    fontColorHexVal: _teal,
    fontFamilyVal: 'Arial',
    fontSizeVal: 8,
    horizontalAlignVal: HorizontalAlign.Center,
  );
  static final _dashboardHighlightLabelStyle = _dashboardHeaderStyle.copyWith(
    horizontalAlignVal: HorizontalAlign.Left,
  );
  static final _dashboardHighlightCategoryStyle = _dashboardBodyStyle.copyWith(
    boldVal: true,
    horizontalAlignVal: HorizontalAlign.Left,
  );
}

class _SheetNames {
  final String dashboard;
  final String periodSummary;
  final String transactions;
  final String categories;
  final String adjustments;
  final String chartData;

  _SheetNames(ReportDataset dataset)
    : dashboard = dataset.localizations.tr('dashboard'),
      periodSummary = dataset.localizations.tr('period_summary'),
      transactions = dataset.localizations.tr('transactions'),
      categories = dataset.localizations.tr('budget_categories'),
      adjustments = dataset.localizations.tr('budget_changes'),
      chartData = dataset.localizations.tr('chart_data');
}
