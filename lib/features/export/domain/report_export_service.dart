import '../data/excel_report_generator.dart';
import '../data/pdf_report_generator.dart';
import '../data/report_save_gateway.dart';
import '../data/report_share_gateway.dart';
import 'export_report_request.dart';
import 'generated_report.dart';
import 'report_format.dart';

class ReportExportService {
  final PdfReportGenerator _pdfGenerator;
  final ExcelReportGenerator _excelGenerator;
  final ReportShareGateway _shareGateway;
  final ReportSaveGateway _saveGateway;

  const ReportExportService({
    required PdfReportGenerator pdfGenerator,
    required ExcelReportGenerator excelGenerator,
    required ReportShareGateway shareGateway,
    required ReportSaveGateway saveGateway,
  }) : _pdfGenerator = pdfGenerator,
       _excelGenerator = excelGenerator,
       _shareGateway = shareGateway,
       _saveGateway = saveGateway;

  Future<GeneratedReport> generate(ExportReportRequest request) {
    return switch (request.format) {
      ReportFormat.pdf => _pdfGenerator.generate(request),
      ReportFormat.excel => _excelGenerator.generate(request),
    };
  }

  Future<GeneratedReport> generateAndShare(ExportReportRequest request) async {
    final report = await generate(request);
    await _shareGateway.share(report);
    return report;
  }

  Future<({GeneratedReport report, bool saved})> generateAndSave(
    ExportReportRequest request,
  ) async {
    final report = await generate(request);
    final saved = await _saveGateway.save(report);
    return (report: report, saved: saved);
  }
}
