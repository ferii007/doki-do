import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/currency_input_formatter.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/layout/app_spacing.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_calendar.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../domain/entities/transaction_template.dart';
import '../../../domain/entities/transaction_type.dart';
import 'amount_input.dart';
import 'transaction_note_field.dart';

class RecurringTemplateEditResult {
  final String title;
  final int amount;
  final String? preferredCategoryName;
  final int dayOfMonth;
  final DateTime activeFromDate;
  final DateTime? endDate;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  const RecurringTemplateEditResult({
    required this.title,
    required this.amount,
    required this.preferredCategoryName,
    required this.dayOfMonth,
    required this.activeFromDate,
    required this.endDate,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
  });
}

class RecurringTemplateEditSheet extends StatefulWidget {
  final TransactionTemplate template;

  const RecurringTemplateEditSheet({super.key, required this.template});

  @override
  State<RecurringTemplateEditSheet> createState() =>
      _RecurringTemplateEditSheetState();
}

class _RecurringTemplateEditSheetState
    extends State<RecurringTemplateEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _categoryController;
  late final TextEditingController _dayController;
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late DateTime _activeFromDate;
  DateTime? _endDate;
  late bool _reminderEnabled;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    _titleController = TextEditingController(text: template.title);
    _amountController = TextEditingController(
      text: CurrencyInputFormatter.format(template.amount),
    );
    _categoryController = TextEditingController(
      text: template.preferredCategoryName,
    );
    _dayController = TextEditingController(text: '${template.dayOfMonth ?? 1}');
    _hourController = TextEditingController(text: '${template.reminderHour}');
    _minuteController = TextEditingController(
      text: template.reminderMinute.toString().padLeft(2, '0'),
    );
    _activeFromDate = template.activeFromDate;
    _endDate = template.endDate;
    _reminderEnabled = template.reminderEnabled;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _dayController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return AppSheetSurface(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSheetHeader(
                title: context.tr('edit_recurring_transaction'),
                icon: Icons.event_repeat_rounded,
              ),
              const AppFormControlGap(),
              TransactionNoteField(
                controller: _titleController,
                label: context.tr('transaction_name'),
              ),
              const AppFormFieldGap(),
              AmountInput(controller: _amountController),
              if (widget.template.type == TransactionType.expense) ...[
                const AppFormFieldGap(),
                TransactionNoteField(
                  controller: _categoryController,
                  label: context.tr('target_budget_category'),
                ),
              ],
              const AppFormFieldGap(),
              TextField(
                controller: _dayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('monthly_recording_date'),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const OutlineInputBorder(),
                  suffixText: context.tr('day_1_to_31'),
                ),
              ),
              const AppFormFieldGap(),
              _DateField(
                label: context.tr('active_from'),
                value: DateFormatter.full(_activeFromDate),
                onTap: _pickStartDate,
              ),
              const AppFormControlGap(),
              _DateField(
                label: context.tr('ends_on'),
                value: _endDate == null
                    ? context.tr('no_end_date')
                    : DateFormatter.full(_endDate!),
                onTap: _pickEndDate,
                onClear: _endDate == null
                    ? null
                    : () => setState(() => _endDate = null),
              ),
              const AppFormControlGap(),
              _ReminderToggle(
                selected: _reminderEnabled,
                onTap: () =>
                    setState(() => _reminderEnabled = !_reminderEnabled),
              ),
              if (_reminderEnabled) ...[
                const AppFormFieldGap(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _hourController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.tr('reminder_hour'),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _minuteController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: context.tr('reminder_minute'),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(context.tr('save_changes')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final selected = await showAppDatePicker(
      context: context,
      initialDate: _activeFromDate,
      lastDate: _endDate,
      title: context.tr('choose_active_start_date'),
    );
    if (selected != null && mounted) {
      setState(() => _activeFromDate = selected);
    }
  }

  Future<void> _pickEndDate() async {
    final selected = await showAppDatePicker(
      context: context,
      initialDate: _endDate ?? _activeFromDate,
      firstDate: _activeFromDate,
      title: context.tr('choose_end_date'),
    );
    if (selected != null && mounted) setState(() => _endDate = selected);
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = CurrencyInputFormatter.parse(_amountController.text);
    final day = int.tryParse(_dayController.text.trim());
    final hour = int.tryParse(_hourController.text.trim());
    final minute = int.tryParse(_minuteController.text.trim());

    if (title.isEmpty) {
      AppToast.show(context, context.tr('enter_transaction_name'));
      return;
    }
    if (amount <= 0) {
      AppToast.show(context, context.tr('enter_the_amount_first'));
      return;
    }
    if (day == null || day < 1 || day > 31) {
      AppToast.show(context, context.tr('monthly_date_must_be_1_to_31'));
      return;
    }
    if (_reminderEnabled &&
        (hour == null ||
            hour < 0 ||
            hour > 23 ||
            minute == null ||
            minute < 0 ||
            minute > 59)) {
      AppToast.show(context, context.tr('invalid_reminder_time'));
      return;
    }

    Navigator.pop(
      context,
      RecurringTemplateEditResult(
        title: title,
        amount: amount,
        preferredCategoryName: widget.template.type == TransactionType.expense
            ? _categoryController.text.trim()
            : null,
        dayOfMonth: day,
        activeFromDate: _activeFromDate,
        endDate: _endDate,
        reminderEnabled: _reminderEnabled,
        reminderHour: hour ?? 9,
        reminderMinute: minute ?? 0,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          suffixIcon: onClear == null
              ? const Icon(Icons.calendar_month_outlined)
              : IconButton(
                  tooltip: context.tr('clear_end_date'),
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
        child: Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ReminderToggle extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _ReminderToggle({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.mintSurface : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('local_reminder'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('local_reminder_description'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(3),
              alignment: selected
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
