import '../../finance/domain/entities/budget_snapshot.dart';
import '../../settings/domain/entities/app_currency.dart';
import '../../settings/domain/entities/app_language.dart';
import '../../settings/domain/entities/export_report_template.dart';
import 'report_format.dart';

class ExportReportRequest {
  final List<BudgetSnapshot> snapshots;
  final ReportFormat format;
  final ExportReportTemplate template;
  final AppLanguage language;
  final AppCurrency currency;
  final String displayName;
  final DateTime generatedAt;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;

  const ExportReportRequest({
    required this.snapshots,
    required this.format,
    required this.template,
    required this.language,
    required this.currency,
    required this.displayName,
    required this.generatedAt,
    this.dateRangeStart,
    this.dateRangeEnd,
  });
}
