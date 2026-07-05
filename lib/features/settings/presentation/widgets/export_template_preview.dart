import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/export_report_template.dart';

class ExportTemplatePreview extends StatelessWidget {
  final ExportReportTemplate template;

  const ExportTemplatePreview({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 300,
          height: 150,
          child: template == ExportReportTemplate.dashboard
              ? const _DashboardExportPreview()
              : const _BasicExportPreview(),
        ),
      ),
    );
  }
}

class _DashboardExportPreview extends StatelessWidget {
  const _DashboardExportPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (final color in [
              AppColors.secondary,
              AppColors.primary,
              AppColors.danger,
            ]) ...[
              Expanded(
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              if (color != AppColors.danger) const SizedBox(width: 5),
            ],
          ],
        ),
        const SizedBox(height: 7),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final height in [26.0, 44.0, 34.0, 54.0, 40.0]) ...[
                      Expanded(
                        child: Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.72),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      if (height != 40.0) const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    for (var index = 0; index < 4; index++)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: index.isEven
                                ? AppColors.mintSurface
                                : Colors.white,
                            border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BasicExportPreview extends StatelessWidget {
  const _BasicExportPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              for (var row = 0; row < 5; row++)
                Expanded(
                  child: Row(
                    children: [
                      for (var column = 0; column < 4; column++)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: row.isEven
                                  ? AppColors.mintSurface.withValues(alpha: 0.5)
                                  : Colors.white,
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.6),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
