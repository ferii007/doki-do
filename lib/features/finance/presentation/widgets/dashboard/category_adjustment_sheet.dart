import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/formatters/currency_input_formatter.dart';
import '../../../../../core/formatters/rupiah_formatter.dart';
import '../../../../../core/layout/app_spacing.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../domain/entities/category_budget.dart';
import '../transaction_type_icon.dart';
import '../transaction_form/themed_dropdown_field.dart';

enum CategoryAdjustmentAction { increase, decrease, setAmount }

class CategoryAdjustmentResult {
  final String action;
  final int amount;
  final String reason;
  final String? relatedCategoryId;

  const CategoryAdjustmentResult({
    required this.action,
    required this.amount,
    required this.reason,
    this.relatedCategoryId,
  });
}

class CategoryAdjustmentSheet extends StatefulWidget {
  final CategoryBudget category;
  final List<CategoryBudget> categories;
  final CategoryAdjustmentAction action;

  const CategoryAdjustmentSheet({
    super.key,
    required this.category,
    required this.categories,
    required this.action,
  });

  @override
  State<CategoryAdjustmentSheet> createState() =>
      _CategoryAdjustmentSheetState();
}

class _CategoryAdjustmentSheetState extends State<CategoryAdjustmentSheet> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _reasonFocusNode = FocusNode();
  String? _relatedCategoryId;

  @override
  void initState() {
    super.initState();
    _reasonFocusNode.addListener(_refresh);
  }

  @override
  void dispose() {
    _reasonFocusNode
      ..removeListener(_refresh)
      ..dispose();
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherCategories = widget.categories
        .where((category) => category.id != widget.category.id)
        .toList();

    return AppSheetSurface(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(
              title: _title(context),
              icon: widget.action == CategoryAdjustmentAction.setAmount
                  ? Icons.tune_rounded
                  : null,
              leading: widget.action == CategoryAdjustmentAction.setAmount
                  ? null
                  : TransactionTypeIcon(
                      isIncome:
                          widget.action == CategoryAdjustmentAction.increase,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.category.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const AppFormControlGap(),
            _SheetAmountTextField(
              controller: _amountController,
              label: context.tr('amount_2'),
              onChanged: _refresh,
            ),
            const AppFormFieldGap(),
            _FocusOnlyLabelTextField(
              controller: _reasonController,
              focusNode: _reasonFocusNode,
              label: context.tr('reason'),
            ),
            if (otherCategories.isNotEmpty) ...[
              const AppFormFieldGap(),
              _RelatedCategoryPicker(
                categories: otherCategories,
                selectedCategoryId: _relatedCategoryId,
                label: _relatedLabel(context),
                onChanged: (value) =>
                    setState(() => _relatedCategoryId = value),
              ),
            ],
            const AppFormControlGap(),
            _ImpactPreview(
              category: widget.category,
              action: widget.action,
              amount: CurrencyInputFormatter.parse(_amountController.text),
              relatedCategory: _findCategory(
                otherCategories,
                _relatedCategoryId,
              ),
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
    );
  }

  String _title(BuildContext context) {
    return switch (widget.action) {
      CategoryAdjustmentAction.increase => context.tr('add_budget_amount'),
      CategoryAdjustmentAction.decrease => context.tr('reduce_budget_amount'),
      CategoryAdjustmentAction.setAmount => context.tr('set_budget_amount'),
    };
  }

  String _relatedLabel(BuildContext context) {
    return switch (widget.action) {
      CategoryAdjustmentAction.increase => context.tr(
        'take_from_another_category',
      ),
      CategoryAdjustmentAction.decrease => context.tr(
        'move_to_another_category',
      ),
      CategoryAdjustmentAction.setAmount => context.tr(
        'balance_with_another_category',
      ),
    };
  }

  void _submit() {
    final amount = CurrencyInputFormatter.parse(_amountController.text);
    final reason = _reasonController.text.trim();

    if (amount <= 0) {
      AppToast.show(context, context.tr('enter_the_amount_first'));
      return;
    }
    if (reason.isEmpty) {
      AppToast.show(context, context.tr('write_the_reason_first'));
      return;
    }

    Navigator.pop(
      context,
      CategoryAdjustmentResult(
        action: switch (widget.action) {
          CategoryAdjustmentAction.increase => 'increase',
          CategoryAdjustmentAction.decrease => 'decrease',
          CategoryAdjustmentAction.setAmount => 'set',
        },
        amount: amount,
        reason: reason,
        relatedCategoryId: _relatedCategoryId,
      ),
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  CategoryBudget? _findCategory(
    List<CategoryBudget> categories,
    String? categoryId,
  ) {
    if (categoryId == null) return null;
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }
}

class _RelatedCategoryPicker extends StatelessWidget {
  final List<CategoryBudget> categories;
  final String? selectedCategoryId;
  final String label;
  final ValueChanged<String?> onChanged;

  const _RelatedCategoryPicker({
    required this.categories,
    required this.selectedCategoryId,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedDropdownField<String>(
      label: label,
      value: selectedCategoryId,
      options: [
        ThemedDropdownOption<String>(
          value: null,
          title: context.tr('do_not_use_another_category'),
          subtitle: context.tr('only_this_category_amount_will_change'),
        ),
        for (final category in categories)
          ThemedDropdownOption<String>(
            value: category.id,
            title: category.name,
            subtitle: RupiahFormatter.format(category.remainingAmount),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ImpactPreview extends StatelessWidget {
  final CategoryBudget category;
  final CategoryBudget? relatedCategory;
  final CategoryAdjustmentAction action;
  final int amount;

  const _ImpactPreview({
    required this.category,
    required this.action,
    required this.amount,
    this.relatedCategory,
  });

  @override
  Widget build(BuildContext context) {
    final delta = switch (action) {
      CategoryAdjustmentAction.increase => amount,
      CategoryAdjustmentAction.decrease => -amount,
      CategoryAdjustmentAction.setAmount => amount - category.allocatedAmount,
    };
    final nextAmount = category.allocatedAmount + delta;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mintSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('change_impact'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _ImpactRow(name: category.name, amount: nextAmount),
          if (relatedCategory != null)
            _ImpactRow(
              name: relatedCategory!.name,
              amount: relatedCategory!.allocatedAmount - delta,
            ),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final String name;
  final int amount;

  const _ImpactRow({required this.name, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            RupiahFormatter.format(amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: amount < 0 ? AppColors.danger : AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAmountTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  const _SheetAmountTextField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [CurrencyInputFormatter()],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const _CurrencyPrefix(),
        prefixIconConstraints: const BoxConstraints(minWidth: 52),
        floatingLabelBehavior: FloatingLabelBehavior.always,
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

class _FocusOnlyLabelTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;

  const _FocusOnlyLabelTextField({
    required this.controller,
    required this.focusNode,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
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

class _CurrencyPrefix extends StatelessWidget {
  const _CurrencyPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 8),
      child: Text(
        CurrencyFormatterPreference.current.symbol,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
