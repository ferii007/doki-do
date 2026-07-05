import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_calendar.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../finance/domain/entities/budget_snapshot.dart';
import '../../../finance/presentation/providers/current_budget_provider.dart';
import '../../../finance/presentation/providers/selected_period_provider.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../../../settings/presentation/widgets/export_template_preview.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/entities/export_report_template.dart';
import '../../domain/export_report_request.dart';
import '../../domain/report_format.dart';
import '../../domain/report_scope.dart';
import '../providers/report_export_provider.dart';

class ExportReportScreen extends ConsumerStatefulWidget {
  const ExportReportScreen({super.key});

  @override
  ConsumerState<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends ConsumerState<ExportReportScreen> {
  ReportScope _scope = ReportScope.selectedPeriods;
  ReportFormat _format = ReportFormat.pdf;
  final Set<String> _selectedPeriodIds = {};
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  _ExportAction? _activeAction;

  bool get _busy => _activeAction != null;

  @override
  Widget build(BuildContext context) {
    final snapshotsAsync = ref.watch(allBudgetSnapshotsProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('export_report'))),
      body: snapshotsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(error: error),
        data: (snapshots) {
          if (snapshots.isEmpty) {
            return _EmptyExportState();
          }
          final settings = settingsAsync.asData?.value;
          if (settings == null) return const LoadingView();

          _ensureSelections(snapshots);
          final exportSnapshots = _snapshotsForScope(snapshots);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              _TemplateSummaryCard(template: settings.exportReportTemplate),
              const SizedBox(height: 14),
              _ChoiceCard<ReportScope>(
                title: context.tr('data_scope'),
                selected: _scope,
                options: ReportScope.values,
                label: (value) => context.tr(value.labelKey),
                icon: (value) => switch (value) {
                  ReportScope.selectedPeriods =>
                    Icons.library_add_check_rounded,
                  ReportScope.dateRange => Icons.date_range_rounded,
                  ReportScope.allPeriods => Icons.calendar_month_rounded,
                },
                onSelected: (value) => setState(() => _scope = value),
              ),
              if (_scope == ReportScope.selectedPeriods) ...[
                const SizedBox(height: 12),
                _SelectionField(
                  icon: Icons.library_add_check_rounded,
                  label: context.tr('financial_periods'),
                  value: context.trf('selected_period_count', {
                    'count': _selectedPeriodIds.length,
                  }),
                  onTap: () => _selectPeriods(snapshots),
                ),
              ],
              if (_scope == ReportScope.dateRange) ...[
                const SizedBox(height: 12),
                _SelectionField(
                  icon: Icons.date_range_rounded,
                  label: context.tr('date_range'),
                  value: _rangeStart == null || _rangeEnd == null
                      ? context.tr('choose_date_range')
                      : '${_dateLabel(context, _rangeStart!)} - '
                            '${_dateLabel(context, _rangeEnd!)}',
                  onTap: () => _selectDateRange(snapshots),
                ),
              ],
              const SizedBox(height: 14),
              _ChoiceCard<ReportFormat>(
                title: context.tr('file_format'),
                selected: _format,
                options: ReportFormat.values,
                label: (value) => context.tr(value.labelKey),
                icon: (value) => value == ReportFormat.pdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.table_chart_outlined,
                onSelected: (value) => setState(() => _format = value),
              ),
              const SizedBox(height: 14),
              _ExportContentSummary(
                snapshots: exportSnapshots,
                format: _format,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed:
                    _busy ||
                        exportSnapshots.isEmpty ||
                        (_scope == ReportScope.dateRange &&
                            (_rangeStart == null || _rangeEnd == null))
                    ? null
                    : () =>
                          _save(snapshots: exportSnapshots, settings: settings),
                icon: Icon(
                  _activeAction == _ExportAction.save
                      ? Icons.hourglass_top_rounded
                      : Icons.download_rounded,
                ),
                label: Text(
                  context.tr(
                    _activeAction == _ExportAction.save
                        ? 'saving_report'
                        : 'save_to_device',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed:
                    _busy ||
                        exportSnapshots.isEmpty ||
                        (_scope == ReportScope.dateRange &&
                            (_rangeStart == null || _rangeEnd == null))
                    ? null
                    : () => _share(
                        snapshots: exportSnapshots,
                        settings: settings,
                      ),
                icon: Icon(
                  _activeAction == _ExportAction.share
                      ? Icons.hourglass_top_rounded
                      : Icons.ios_share_rounded,
                ),
                label: Text(
                  context.tr(
                    _activeAction == _ExportAction.share
                        ? 'preparing_report'
                        : 'share_report',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _ensureSelections(List<BudgetSnapshot> snapshots) {
    _selectedPeriodIds.removeWhere(
      (id) => !snapshots.any((snapshot) => snapshot.period.id == id),
    );
    if (_selectedPeriodIds.isNotEmpty) return;
    final activeId = ref.read(selectedPeriodIdProvider);
    _selectedPeriodIds.add(
      activeId ??
          ([...snapshots]..sort(
                (a, b) => a.period.startDate.compareTo(b.period.startDate),
              ))
              .last
              .period
              .id,
    );
  }

  List<BudgetSnapshot> _snapshotsForScope(List<BudgetSnapshot> snapshots) {
    return switch (_scope) {
      ReportScope.selectedPeriods =>
        snapshots
            .where(
              (snapshot) => _selectedPeriodIds.contains(snapshot.period.id),
            )
            .toList(growable: false),
      ReportScope.dateRange =>
        _rangeStart == null || _rangeEnd == null
            ? const []
            : snapshots
                  .where(
                    (snapshot) =>
                        !snapshot.period.endDate.isBefore(_rangeStart!) &&
                        !snapshot.period.startDate.isAfter(_rangeEnd!),
                  )
                  .toList(growable: false),
      ReportScope.allPeriods => snapshots,
    };
  }

  Future<void> _selectPeriods(List<BudgetSnapshot> snapshots) async {
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final pending = {..._selectedPeriodIds};
        return StatefulBuilder(
          builder: (context, setSheetState) => AppSheetSurface(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSheetHeader(
                    title: context.tr('choose_financial_periods'),
                    icon: Icons.library_add_check_rounded,
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: snapshots.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final snapshot = snapshots[index];
                        final isSelected = pending.contains(snapshot.period.id);
                        return _PeriodSelectionTile(
                          snapshot: snapshot,
                          selected: isSelected,
                          onTap: () => setSheetState(() {
                            if (isSelected) {
                              pending.remove(snapshot.period.id);
                            } else {
                              pending.add(snapshot.period.id);
                            }
                          }),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: pending.isEmpty
                          ? null
                          : () => Navigator.pop(sheetContext, pending),
                      child: Text(
                        context.trf('use_selected_periods', {
                          'count': pending.length,
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedPeriodIds
        ..clear()
        ..addAll(selected);
    });
  }

  Future<void> _selectDateRange(List<BudgetSnapshot> snapshots) async {
    final ordered = [...snapshots]
      ..sort((a, b) => a.period.startDate.compareTo(b.period.startDate));
    final firstDate = _dateOnly(ordered.first.period.startDate);
    final lastDate = _dateOnly(
      ordered
          .map((snapshot) => snapshot.period.endDate)
          .reduce((a, b) => a.isAfter(b) ? a : b),
    );
    final result = await showModalBottomSheet<({DateTime start, DateTime end})>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        DateTime? pendingStart = _rangeStart;
        DateTime? pendingEnd = _rangeEnd;
        return StatefulBuilder(
          builder: (context, setSheetState) => AppSheetSurface(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSheetHeader(
                    title: context.tr('choose_date_range'),
                    icon: Icons.date_range_rounded,
                  ),
                  const SizedBox(height: 14),
                  AppCalendar(
                    initialVisibleMonth: pendingStart ?? lastDate,
                    selectedStart: pendingStart,
                    selectedEnd: pendingEnd,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    isDateDisabled: (date) => !snapshots.any(
                      (snapshot) =>
                          !date.isBefore(
                            _dateOnly(snapshot.period.startDate),
                          ) &&
                          !date.isAfter(_dateOnly(snapshot.period.endDate)),
                    ),
                    onDateTap: (date) => setSheetState(() {
                      final selectedDate = _dateOnly(date);
                      if (pendingStart == null || pendingEnd != null) {
                        pendingStart = selectedDate;
                        pendingEnd = null;
                      } else if (selectedDate.isBefore(pendingStart!)) {
                        pendingEnd = pendingStart;
                        pendingStart = selectedDate;
                      } else {
                        pendingEnd = selectedDate;
                      }
                    }),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: pendingStart == null || pendingEnd == null
                          ? null
                          : () => Navigator.pop(sheetContext, (
                              start: pendingStart!,
                              end: pendingEnd!,
                            )),
                      child: Text(context.tr('use_date_range')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result == null || !mounted) return;
    setState(() {
      _rangeStart = result.start;
      _rangeEnd = result.end;
    });
  }

  ExportReportRequest _request({
    required List<BudgetSnapshot> snapshots,
    required AppSettings settings,
  }) {
    return ExportReportRequest(
      snapshots: snapshots,
      format: _format,
      template: settings.exportReportTemplate,
      language: settings.language,
      currency: settings.currency,
      displayName: settings.displayName,
      generatedAt: DateTime.now(),
      dateRangeStart: _scope == ReportScope.dateRange ? _rangeStart : null,
      dateRangeEnd: _scope == ReportScope.dateRange ? _rangeEnd : null,
    );
  }

  Future<void> _save({
    required List<BudgetSnapshot> snapshots,
    required AppSettings settings,
  }) async {
    setState(() => _activeAction = _ExportAction.save);
    try {
      final result = await ref
          .read(reportExportServiceProvider)
          .generateAndSave(_request(snapshots: snapshots, settings: settings));
      if (!mounted) return;
      AppToast.show(
        context,
        result.saved
            ? context.trf('report_saved_to_device', {
                'file': result.report.fileName,
              })
            : context.tr('saving_report_cancelled'),
      );
    } on Object {
      if (!mounted) return;
      AppToast.show(context, context.tr('report_save_failed'));
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }

  Future<void> _share({
    required List<BudgetSnapshot> snapshots,
    required AppSettings settings,
  }) async {
    setState(() => _activeAction = _ExportAction.share);
    try {
      final report = await ref
          .read(reportExportServiceProvider)
          .generateAndShare(_request(snapshots: snapshots, settings: settings));
      if (!mounted) return;
      AppToast.show(
        context,
        context.trf('report_ready_to_share', {'file': report.fileName}),
      );
    } on Object {
      if (!mounted) return;
      AppToast.show(context, context.tr('report_export_failed'));
    } finally {
      if (mounted) setState(() => _activeAction = null);
    }
  }
}

enum _ExportAction { save, share }

class _TemplateSummaryCard extends StatelessWidget {
  final ExportReportTemplate template;

  const _TemplateSummaryCard({required this.template});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 72,
            child: ExportTemplatePreview(template: template),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('active_export_template'),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(template.nameKey),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard<T> extends StatelessWidget {
  final String title;
  final T selected;
  final List<T> options;
  final String Function(T value) label;
  final IconData Function(T value) icon;
  final ValueChanged<T> onSelected;

  const _ChoiceCard({
    required this.title,
    required this.selected,
    required this.options,
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              for (var index = 0; index < options.length; index++) ...[
                Expanded(
                  child: _ChoiceOption(
                    icon: icon(options[index]),
                    label: label(options[index]),
                    selected: selected == options[index],
                    onTap: () => onSelected(options[index]),
                  ),
                ),
                if (index != options.length - 1) const SizedBox(width: 9),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintSurface : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SelectionField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.mintSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelectionTile extends StatelessWidget {
  final BudgetSnapshot snapshot;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodSelectionTile({
    required this.snapshot,
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
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? AppColors.mintSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.calendar_today_outlined,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  _periodLabel(context, snapshot),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportContentSummary extends StatelessWidget {
  final List<BudgetSnapshot> snapshots;
  final ReportFormat format;

  const _ExportContentSummary({required this.snapshots, required this.format});

  @override
  Widget build(BuildContext context) {
    final transactionCount = snapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.transactions.length,
    );
    final categoryCount = snapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.categories.length,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: AppColors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              context.trf('export_content_summary', {
                'periods': snapshots.length,
                'transactions': transactionCount,
                'categories': categoryCount,
                'format': context.tr(format.labelKey),
              }),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExportState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.tr('no_data_to_export'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _periodLabel(BuildContext context, BudgetSnapshot snapshot) {
  return '${_dateLabel(context, snapshot.period.startDate)} - '
      '${_dateLabel(context, snapshot.period.endDate)}';
}

String _dateLabel(BuildContext context, DateTime value) =>
    '${value.day} ${context.tr('month_long_${value.month}')} ${value.year}';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
