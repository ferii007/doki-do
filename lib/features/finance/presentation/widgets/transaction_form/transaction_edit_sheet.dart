import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/currency_input_formatter.dart';
import '../../../../../core/formatters/date_formatter.dart';
import '../../../../../core/formatters/rupiah_formatter.dart';
import '../../../../../core/layout/app_spacing.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_calendar.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../domain/entities/category_budget.dart';
import '../../../domain/entities/transaction_item.dart';
import '../../../domain/entities/transaction_type.dart';
import 'themed_dropdown_field.dart';

class TransactionEditResult {
  final String? categoryId;
  final int amount;
  final String title;
  final DateTime date;

  const TransactionEditResult({
    required this.amount,
    required this.title,
    required this.date,
    this.categoryId,
  });
}

class TransactionEditSheet extends StatefulWidget {
  final TransactionItem transaction;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<CategoryBudget> categories;

  const TransactionEditSheet({
    super.key,
    required this.transaction,
    required this.firstDate,
    required this.lastDate,
    this.categories = const [],
  });

  @override
  State<TransactionEditSheet> createState() => _TransactionEditSheetState();
}

class _TransactionEditSheetState extends State<TransactionEditSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  final _amountFocusNode = FocusNode();
  final _titleFocusNode = FocusNode();
  final _categoryFocusNode = FocusNode();
  late DateTime _date;
  String? _categoryId;

  bool get _isExpense => widget.transaction.type == TransactionType.expense;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: CurrencyInputFormatter.format(widget.transaction.amount),
    );
    _titleController = TextEditingController(text: widget.transaction.title);
    _date = widget.transaction.date;
    _categoryId = widget.transaction.categoryId;
    _amountFocusNode.addListener(_refreshFocusState);
    _titleFocusNode.addListener(_refreshFocusState);
    _categoryFocusNode.addListener(_refreshFocusState);
  }

  @override
  void dispose() {
    _amountFocusNode
      ..removeListener(_refreshFocusState)
      ..dispose();
    _titleFocusNode
      ..removeListener(_refreshFocusState)
      ..dispose();
    _categoryFocusNode
      ..removeListener(_refreshFocusState)
      ..dispose();
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return AppSheetSurface(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSheetHeader(
                title: context.tr(_isExpense ? 'edit_expense' : 'edit_income'),
                icon: Icons.edit_note_rounded,
              ),
              const AppFormControlGap(),
              if (_isExpense) ...[
                _FocusOnlyLabelCategoryField(
                  categories: widget.categories,
                  selectedCategoryId: _categoryId,
                  focusNode: _categoryFocusNode,
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                const AppFormFieldGap(),
              ],
              _FocusOnlyLabelTextField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                label: context.tr('amount'),
                prefixText: CurrencyFormatterPreference.current.symbol,
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
              ),
              const AppFormFieldGap(),
              _FocusOnlyLabelTextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                label: context.tr(
                  _isExpense
                      ? 'what_was_it_used_for'
                      : 'where_did_this_money_come_from',
                ),
              ),
              const AppFormFieldGap(),
              _EditDateField(
                date: _date,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                onChanged: (value) => setState(() => _date = value),
              ),
              const SizedBox(height: 16),
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

  void _submit() {
    final amount = CurrencyInputFormatter.parse(_amountController.text);
    final title = _titleController.text.trim();

    if (_isExpense && _categoryId == null) {
      AppToast.show(context, context.tr('choose_the_budget_category_first'));
      return;
    }
    if (amount <= 0) {
      AppToast.show(context, context.tr('enter_the_amount_first'));
      return;
    }
    if (title.isEmpty) {
      AppToast.show(context, context.tr('fill_in_the_note_first'));
      return;
    }

    Navigator.pop(
      context,
      TransactionEditResult(
        categoryId: _categoryId,
        amount: amount,
        title: title,
        date: _date,
      ),
    );
  }

  void _refreshFocusState() {
    if (mounted) setState(() {});
  }
}

class _FocusOnlyLabelTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? prefixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _FocusOnlyLabelTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.prefixText,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: prefixText == null
            ? null
            : _CurrencyPrefix(symbol: prefixText!),
        prefixIconConstraints: prefixText == null
            ? null
            : const BoxConstraints(minWidth: 52),
        filled: true,
        fillColor: AppColors.background,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _FocusOnlyLabelCategoryField extends StatelessWidget {
  final List<CategoryBudget> categories;
  final String? selectedCategoryId;
  final FocusNode focusNode;
  final ValueChanged<String?> onChanged;

  const _FocusOnlyLabelCategoryField({
    required this.categories,
    required this.selectedCategoryId,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedDropdownField<String>(
      label: context.tr('budget_category'),
      value: selectedCategoryId,
      focusNode: focusNode,
      options: categories
          .map(
            (category) => ThemedDropdownOption<String>(
              value: category.id,
              title: category.name,
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _CurrencyPrefix extends StatelessWidget {
  final String symbol;

  const _CurrencyPrefix({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 8),
      child: Text(
        symbol,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EditDateField extends StatelessWidget {
  final DateTime date;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  const _EditDateField({
    required this.date,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final selected = await showAppDatePicker(
          context: context,
          initialDate: _clampDate(date, firstDate, lastDate),
          firstDate: firstDate,
          lastDate: lastDate,
        );

        if (selected != null) onChanged(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: context.tr('date'),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: AppColors.background,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
          labelStyle: TextStyle(color: AppColors.textSecondary),
          floatingLabelStyle: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Text(DateFormatter.full(date)),
      ),
    );
  }

  DateTime _clampDate(DateTime value, DateTime min, DateTime max) {
    if (value.isBefore(min)) return min;
    if (value.isAfter(max)) return max;
    return value;
  }
}
