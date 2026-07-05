enum ReportFormat {
  pdf(extension: 'pdf', mimeType: 'application/pdf', labelKey: 'pdf'),
  excel(
    extension: 'xlsx',
    mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    labelKey: 'excel',
  );

  final String extension;
  final String mimeType;
  final String labelKey;

  const ReportFormat({
    required this.extension,
    required this.mimeType,
    required this.labelKey,
  });
}
