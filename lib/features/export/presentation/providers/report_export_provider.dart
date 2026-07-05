import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/excel_report_generator.dart';
import '../../data/pdf_report_generator.dart';
import '../../data/report_save_gateway.dart';
import '../../data/report_share_gateway.dart';
import '../../domain/report_export_service.dart';

final reportShareGatewayProvider = Provider<ReportShareGateway>((ref) {
  return const PlatformReportShareGateway();
});

final reportSaveGatewayProvider = Provider<ReportSaveGateway>((ref) {
  return const PlatformReportSaveGateway();
});

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  return ReportExportService(
    pdfGenerator: const PdfReportGenerator(),
    excelGenerator: const ExcelReportGenerator(),
    shareGateway: ref.watch(reportShareGatewayProvider),
    saveGateway: ref.watch(reportSaveGatewayProvider),
  );
});
