import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/export_report_template.dart';
import '../providers/app_settings_provider.dart';

class ExportReportTemplatesScreen extends ConsumerWidget {
  const ExportReportTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('export_template'))),
      body: settingsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (settings) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              itemCount: ExportReportTemplate.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final template = ExportReportTemplate.values[index];
                return _ExportTemplateCard(
                  template: template,
                  selected: settings.exportReportTemplate == template,
                  onTap: () async {
                    await ref
                        .read(appSettingsProvider.notifier)
                        .save(
                          settings.copyWith(
                            exportReportTemplateCode: template.code,
                          ),
                        );
                    if (!context.mounted) return;
                    AppToast.show(
                      context,
                      context.trf('export_template_selected', {
                        'template': context.tr(template.nameKey),
                      }),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportTemplateCard extends StatelessWidget {
  final ExportReportTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _ExportTemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.mintSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.overlay.withValues(
                  alpha: selected ? 0.055 : 0.035,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.72,
                child: _ExportTemplatePreview(template: template),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(template.nameKey),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr(template.descriptionKey),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportTemplatePreview extends StatelessWidget {
  final ExportReportTemplate template;

  const _ExportTemplatePreview({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      child: template == ExportReportTemplate.dashboard
          ? const _DashboardExportPreview()
          : const _BasicExportPreview(),
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
                    for (var index = 0; index < 4; index++) ...[
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
