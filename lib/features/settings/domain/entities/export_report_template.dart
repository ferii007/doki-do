enum ExportReportTemplate {
  dashboard(
    code: 'dashboard',
    nameKey: 'dashboard_export_template',
    descriptionKey: 'dashboard_export_template_description',
  ),
  basic(
    code: 'basic',
    nameKey: 'basic_export_template',
    descriptionKey: 'basic_export_template_description',
  );

  final String code;
  final String nameKey;
  final String descriptionKey;

  const ExportReportTemplate({
    required this.code,
    required this.nameKey,
    required this.descriptionKey,
  });

  static ExportReportTemplate byCode(String code) {
    return ExportReportTemplate.values.firstWhere(
      (template) => template.code == code,
      orElse: () => ExportReportTemplate.dashboard,
    );
  }
}
