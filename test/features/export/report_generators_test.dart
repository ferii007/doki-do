import 'dart:convert';
import 'dart:io';

import 'package:doki_do/features/export/data/excel_report_generator.dart';
import 'package:doki_do/features/export/data/pdf_report_generator.dart';
import 'package:doki_do/features/export/data/report_data_mapper.dart';
import 'package:doki_do/features/export/data/report_save_gateway.dart';
import 'package:doki_do/features/export/data/report_share_gateway.dart';
import 'package:doki_do/features/export/domain/export_report_request.dart';
import 'package:doki_do/features/export/domain/report_export_service.dart';
import 'package:doki_do/features/export/domain/report_format.dart';
import 'package:doki_do/features/finance/domain/entities/budget_period.dart';
import 'package:doki_do/features/finance/domain/entities/budget_snapshot.dart';
import 'package:doki_do/features/finance/domain/entities/category_adjustment.dart';
import 'package:doki_do/features/finance/domain/entities/category_budget.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_item.dart';
import 'package:doki_do/features/finance/domain/entities/transaction_type.dart';
import 'package:doki_do/features/settings/domain/entities/app_currency.dart';
import 'package:doki_do/features/settings/domain/entities/app_language.dart';
import 'package:doki_do/features/settings/domain/entities/export_report_template.dart';
import 'package:excel_community/excel_community.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('report generators', () {
    test('creates readable Dashboard PDF bytes', () async {
      final report = await const PdfReportGenerator().generate(
        _request(
          format: ReportFormat.pdf,
          template: ExportReportTemplate.dashboard,
        ),
      );

      expect(report.fileName, contains('_Dashboard.pdf'));
      expect(report.mimeType, 'application/pdf');
      expect(utf8.decode(report.bytes.take(5).toList()), '%PDF-');
      expect(report.bytes.length, greaterThan(3000));
      await _writeQaArtifact(report.fileName, report.bytes);
    });

    test('creates Basic PDF without changing the source data', () async {
      final request = _request(
        format: ReportFormat.pdf,
        template: ExportReportTemplate.basic,
      );
      final originalTransactionCount =
          request.snapshots.single.transactions.length;

      final report = await const PdfReportGenerator().generate(request);

      expect(report.fileName, contains('_Basic.pdf'));
      expect(
        request.snapshots.single.transactions.length,
        originalTransactionCount,
      );
      expect(report.bytes, isNotEmpty);
    });

    test('creates Dashboard workbook with formulas and typed data', () async {
      final report = await const ExcelReportGenerator().generate(
        _request(
          format: ReportFormat.excel,
          template: ExportReportTemplate.dashboard,
        ),
      );
      final workbook = Excel.decodeBytes(report.bytes);
      await _writeQaArtifact(report.fileName, report.bytes);

      expect(report.fileName, contains('_Dashboard.xlsx'));
      expect(
        workbook.tables.keys,
        containsAll([
          'Dashboard',
          'Ringkasan Periode Ini',
          'Transaksi',
          'Kategori Anggaran',
          'Perubahan Anggaran',
          'Data Grafik',
        ]),
      );
      expect(
        workbook['Transaksi'].cell(CellIndex.indexByString('F6')).value,
        const IntCellValue(2260885),
      );
      expect(
        workbook['Dashboard'].cell(CellIndex.indexByString('F6')).value,
        isA<FormulaCellValue>(),
      );
      expect(
        (workbook['Dashboard'].cell(CellIndex.indexByString('F6')).value
                as FormulaCellValue)
            .formula,
        contains('SUM'),
      );
      expect(
        workbook['Dashboard'].cell(CellIndex.indexByString('B2')).value,
        TextCellValue('DokiDo - Laporan Keuangan'),
      );
      expect(
        workbook['Dashboard'].cell(CellIndex.indexByString('B13')).value,
        TextCellValue('Arus Keuangan'),
      );
      expect(
        workbook['Dashboard'].cell(CellIndex.indexByString('I13')).value,
        TextCellValue('Komposisi Pengeluaran'),
      );
    });

    test('creates Basic workbook without Dashboard sheet', () async {
      final report = await const ExcelReportGenerator().generate(
        _request(
          format: ReportFormat.excel,
          template: ExportReportTemplate.basic,
        ),
      );
      final workbook = Excel.decodeBytes(report.bytes);

      expect(report.fileName, contains('_Basic.xlsx'));
      expect(workbook.tables.keys, isNot(contains('Dashboard')));
      expect(
        workbook.tables.keys,
        containsAll(['Transaksi', 'Kategori Anggaran', 'Perubahan Anggaran']),
      );
    });

    test('service shares the generated report through its gateway', () async {
      final gateway = MemoryReportShareGateway();
      final service = ReportExportService(
        pdfGenerator: const PdfReportGenerator(),
        excelGenerator: const ExcelReportGenerator(),
        shareGateway: gateway,
        saveGateway: MemoryReportSaveGateway(),
      );

      final report = await service.generateAndShare(
        _request(
          format: ReportFormat.pdf,
          template: ExportReportTemplate.dashboard,
        ),
      );

      expect(gateway.lastShared, same(report));
    });

    test('service saves the generated report through its gateway', () async {
      final gateway = MemoryReportSaveGateway();
      final service = ReportExportService(
        pdfGenerator: const PdfReportGenerator(),
        excelGenerator: const ExcelReportGenerator(),
        shareGateway: MemoryReportShareGateway(),
        saveGateway: gateway,
      );

      final result = await service.generateAndSave(
        _request(
          format: ReportFormat.excel,
          template: ExportReportTemplate.dashboard,
        ),
      );

      expect(result.saved, isTrue);
      expect(gateway.lastSaved, same(result.report));
    });

    test('exports a period that has no transactions yet', () async {
      final emptySnapshot = BudgetSnapshot(
        period: BudgetPeriod(
          id: 'empty-period',
          startDate: DateTime(2026, 8, 2),
          endDate: DateTime(2026, 9, 1),
          totalIncome: 0,
          totalAllocatable: 0,
          allocationsFollowIncome: false,
        ),
        categories: const [],
        transactions: const [],
        categoryAdjustments: const [],
      );
      final request = ExportReportRequest(
        snapshots: [emptySnapshot],
        format: ReportFormat.excel,
        template: ExportReportTemplate.dashboard,
        language: AppLanguage.id,
        currency: AppCurrency.idr,
        displayName: 'Feri',
        generatedAt: DateTime(2026, 8, 2),
      );

      final excelReport = await const ExcelReportGenerator().generate(request);
      final pdfReport = await const PdfReportGenerator().generate(
        ExportReportRequest(
          snapshots: request.snapshots,
          format: ReportFormat.pdf,
          template: request.template,
          language: request.language,
          currency: request.currency,
          displayName: request.displayName,
          generatedAt: request.generatedAt,
        ),
      );

      expect(Excel.decodeBytes(excelReport.bytes).tables, isNotEmpty);
      expect(utf8.decode(pdfReport.bytes.take(5).toList()), '%PDF-');
    });

    test(
      'filters report transactions and totals by an inclusive date range',
      () {
        final base = _request(
          format: ReportFormat.pdf,
          template: ExportReportTemplate.dashboard,
        );
        final dataset = ReportDataset.fromRequest(
          ExportReportRequest(
            snapshots: base.snapshots,
            format: base.format,
            template: base.template,
            language: base.language,
            currency: base.currency,
            displayName: base.displayName,
            generatedAt: base.generatedAt,
            dateRangeStart: DateTime(2026, 7, 3),
            dateRangeEnd: DateTime(2026, 7, 3),
          ),
        );

        expect(dataset.transactions, hasLength(1));
        expect(dataset.transactions.single.description, 'Belanja Bulanan');
        expect(dataset.totalIncome, 0);
        expect(dataset.totalExpense, 250000);
        expect(dataset.remainingMoney, -250000);
        expect(dataset.fileNameStem, contains('20260703_20260703'));
      },
    );
  });
}

Future<void> _writeQaArtifact(String fileName, List<int> bytes) async {
  final outputDirectory = Platform.environment['DOKIDO_EXPORT_QA_DIR'];
  if (outputDirectory == null) return;
  final directory = Directory(outputDirectory);
  await directory.create(recursive: true);
  await File('${directory.path}/$fileName').writeAsBytes(bytes, flush: true);
}

ExportReportRequest _request({
  required ReportFormat format,
  required ExportReportTemplate template,
}) {
  return ExportReportRequest(
    snapshots: [_snapshot()],
    format: format,
    template: template,
    language: AppLanguage.id,
    currency: AppCurrency.idr,
    displayName: 'Feri',
    generatedAt: DateTime(2026, 7, 4),
  );
}

BudgetSnapshot _snapshot() {
  return BudgetSnapshot(
    period: BudgetPeriod(
      id: 'period-july',
      startDate: DateTime(2026, 7, 2),
      endDate: DateTime(2026, 8, 1),
      totalIncome: 2260885,
      totalAllocatable: 2260885,
      allocationsFollowIncome: true,
    ),
    categories: const [
      CategoryBudget(
        id: 'daily',
        name: 'Kebutuhan Harian',
        allocatedAmount: 2000000,
        remainingAmount: 1750000,
        allocationPercent: 88.46,
      ),
      CategoryBudget(
        id: 'saving',
        name: 'Tabungan & Investasi',
        allocatedAmount: 260885,
        remainingAmount: 210885,
        allocationPercent: 11.54,
      ),
    ],
    transactions: [
      TransactionItem(
        id: 'income-1',
        title: 'Saldo Awal',
        amount: 2260885,
        date: DateTime(2026, 7, 2),
        type: TransactionType.income,
      ),
      TransactionItem(
        id: 'expense-1',
        categoryId: 'daily',
        title: 'Belanja Bulanan',
        amount: 250000,
        date: DateTime(2026, 7, 3),
        type: TransactionType.expense,
      ),
      TransactionItem(
        id: 'expense-2',
        categoryId: 'saving',
        title: 'Investasi',
        amount: 50000,
        date: DateTime(2026, 7, 4),
        type: TransactionType.expense,
      ),
    ],
    categoryAdjustments: [
      CategoryAdjustment(
        id: 'adjustment-1',
        categoryId: 'daily',
        relatedCategoryId: 'saving',
        type: CategoryAdjustmentType.increase,
        amount: 100000,
        deltaAmount: 100000,
        previousAmount: 1900000,
        newAmount: 2000000,
        reason: 'Penyesuaian kebutuhan',
        date: DateTime(2026, 7, 3),
      ),
    ],
  );
}
